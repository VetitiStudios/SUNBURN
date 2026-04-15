local ffi = require("ffi")

ffi.cdef[[
    /* X11 and GLX */
    typedef void* Display;
    typedef unsigned long Window;
    typedef void* Visual;
    typedef void* GLXContext;
    typedef unsigned long Font;

    typedef struct {
        int type;
        unsigned long serial;
        int send_event;
        Display* display;
        Window window;
        unsigned long message_type;
        int format;
        long data;
    } XClientMessageEvent;

    typedef union {
        int type;
        XClientMessageEvent xclient;
        long pad[24];
    } XEvent;

    typedef struct {
        void* visual;
        unsigned long visualid;
        int screen;
        int depth;
        int class;
        unsigned long red_mask, green_mask, blue_mask;
        int colormap_size;
        int bits_per_rgb;
    } XVisualInfo;

    typedef struct {
        long tv_sec;
        long tv_usec;
    } timeval;

    Display* XOpenDisplay(const char*);
    Window XDefaultRootWindow(Display*);
    XVisualInfo* glXChooseVisual(Display*, int, int*);
    Window XCreateSimpleWindow(Display*, Window, int, int, unsigned int, unsigned int, unsigned int, unsigned long, unsigned long);
    void XMapWindow(Display*, Window);
    void XStoreName(Display*, Window, const char*);
    int XInternAtom(Display*, const char*, int);
    int XSetWMProtocols(Display*, Window, int*, int);
    int XPending(Display*);
    int XNextEvent(Display*, XEvent*);
    int XFlush(Display*);
    GLXContext glXCreateContext(Display*, XVisualInfo*, GLXContext, int);
    void glXDestroyContext(Display*, GLXContext);
    int glXMakeCurrent(Display*, Window, GLXContext);
    void glXSwapBuffers(Display*, Window);
    void XDestroyWindow(Display*, Window);
    void XCloseDisplay(Display*);
    Font XLoadFont(Display*, const char*);
    void glXUseXFont(Font, int, int, int);
    void* glXGetProcAddress(const char* name);

    typedef void (*PFNGLXSWAPINTERVALEXTPROC)(Display*, Window, int);

    int gettimeofday(timeval* t, void* tzp);

    typedef struct ALCdevice_struct ALCdevice;
    typedef struct ALCcontext_struct ALCcontext;

    ALCdevice* alcOpenDevice(const char*);
    ALCcontext* alcCreateContext(ALCdevice*, const int*);
    bool alcMakeContextCurrent(ALCcontext*);
    void alcDestroyContext(ALCcontext*);
    bool alcCloseDevice(ALCdevice*);

    void alGenSources(int, uint32_t*);
    void alGenBuffers(int, uint32_t*);
    void alBufferData(uint32_t, int, const void*, int, int);
    void alSourcei(uint32_t, int, int);
    void alSourcePlay(uint32_t);
    int alGetError();
    void alDeleteBuffers(int, uint32_t*);

    void glClearColor(float, float, float, float);
    void glClear(int);
    void glRasterPos2f(float, float);
    void glListBase(uint32_t);
    void glCallLists(int, int, const char*);
    void glColor3f(float, float, float);
    void glLoadIdentity();
    void glBegin(int);
    void glEnd();
    void glVertex3f(float, float, float);
]]

local AL_FORMAT_MONO8    = 0x1100
local AL_FORMAT_MONO16   = 0x1101
local AL_FORMAT_STEREO8  = 0x1102
local AL_FORMAT_STEREO16 = 0x1103
local AL_GAIN            = 0x100A
local AL_BUFFER          = 0x1009

_G.window_impl = {
    create = function(w, h, title)
        local dpy = libs.x11.XOpenDisplay(nil)
        local root = libs.x11.XDefaultRootWindow(dpy)

        local attr = ffi.new("int[5]", {4, 5, 12, 24, 0})
        local vis = libs.gl.glXChooseVisual(dpy, 0, attr)

        local win = libs.x11.XCreateSimpleWindow(dpy, root, 0, 0, w, h, 1, 0, 0)
        libs.x11.XStoreName(dpy, win, title)

        local wm_delete = libs.x11.XInternAtom(dpy, "WM_DELETE_WINDOW", 0)
        local protocols = ffi.new("int[1]", {ffi.cast("int", wm_delete)})
        libs.x11.XSetWMProtocols(dpy, win, protocols, 1)

        libs.x11.XMapWindow(dpy, win)

        local ctx = libs.gl.glXCreateContext(dpy, vis, nil, 1)
        libs.gl.glXMakeCurrent(dpy, win, ctx)

        local swp_ptr = libs.gl.glXGetProcAddress("glXSwapIntervalEXT")
        if swp_ptr ~= nil then
            ffi.cast("PFNGLXSWAPINTERVALEXTPROC", swp_ptr)(dpy, win, 0)
        end

        libs.gl.glXUseXFont(libs.x11.XLoadFont(dpy, "9x15"), 32, 96, 1000)

        return { dpy = dpy, win = win, wm_delete = wm_delete, ctx = ctx }
    end,

    should_close = function(obj)
        local ev = ffi.new("XEvent")
        libs.x11.XFlush(obj.dpy)

        while libs.x11.XPending(obj.dpy) > 0 do
            libs.x11.XNextEvent(obj.dpy, ev)
            local ev_type = ev.type

            if ev_type == 33 then
                return true
            elseif ev_type == 17 then
                return true
            end
        end

        return false
    end,

    swap = function(obj)
        libs.gl.glXSwapBuffers(obj.dpy, obj.win)
    end,

    destroy = function(obj)
        libs.gl.glXMakeCurrent(obj.dpy, 0, nil)
        libs.gl.glXDestroyContext(obj.dpy, obj.ctx)
        libs.x11.XDestroyWindow(obj.dpy, obj.win)
        libs.x11.XCloseDisplay(obj.dpy)
    end
}

_G.audio_impl = {
    init = function()
        local dev = libs.al.alcOpenDevice(nil)
        if dev == nil then return nil end

        local ctx = libs.al.alcCreateContext(dev, nil)
        libs.al.alcMakeContextCurrent(ctx)

        return { device = dev, context = ctx }
    end,

    create_source = function()
        local src = ffi.new("uint32_t[1]")
        libs.al.alGenSources(1, src)

        -- ensure gain is safe
        libs.al.alSourcef(src[0], AL_GAIN, 1.0)

        return src[0]
    end,

    play_pcm = function(source_id, data, size, freq, channels, bits)
        local buf = ffi.new("uint32_t[1]")
        libs.al.alGenBuffers(1, buf)

        local format
        if bits == 16 then
            format = (channels == 1) and AL_FORMAT_MONO16 or AL_FORMAT_STEREO16
        else
            format = (channels == 1) and AL_FORMAT_MONO8 or AL_FORMAT_STEREO8
        end

        local stable = ffi.new("uint8_t[?]", size)
        ffi.copy(stable, data, size)

        libs.al.alBufferData(buf[0], format, stable, size, freq)
        libs.al.alSourcei(source_id, AL_BUFFER, buf[0])
        libs.al.alSourcePlay(source_id)

        local err = libs.al.alGetError()
        if err ~= 0 then
            print("OpenAL ERROR:", err)
        end
    end,

    destroy = function(obj)
        libs.al.alcMakeContextCurrent(nil)
        libs.al.alcDestroyContext(obj.context)
        libs.al.alcCloseDevice(obj.device)
    end
}

return {
    window_impl = _G.window_impl,
    audio_impl = _G.audio_impl
}