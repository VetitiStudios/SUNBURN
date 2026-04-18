local ffi = require("ffi")

ffi.cdef[[
    /* X11 and GLX */
    typedef void* Display;
    typedef unsigned long Window;
    typedef void* Visual;
    typedef void* GLXContext;

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

    /* stb_truetype */
    typedef struct {
        float x0, y0, x1, y1;
        float u0, v0, u1, v1;
    } stbtt_bakedchar;

    typedef struct {
        float x0, y0, x1, y1;
        float s0, t0, s1, t1;
    } stbtt_aligned_quad;

    int stbtt_BakeFontBitmap(const unsigned char *data, int offset, float em_to_pixels, unsigned char *pixels, int pw, int ph, int first_char, int num_chars, stbtt_bakedchar *chardata);
    void stbtt_GetBakedQuad(const stbtt_bakedchar *chardata, int pw, int ph, int char_index, float *xpos, float *ypos, stbtt_aligned_quad *q, int align_to_integer);

    /* OpenGL (minimal needed) */
    void glGenTextures(int, unsigned int*);
    void glBindTexture(unsigned int, unsigned int);
    void glTexImage2D(unsigned int, int, int, int, int, int, unsigned int, unsigned int, const void*);
    void glTexParameteri(unsigned int, unsigned int, int);
    void* glXGetProcAddress(const char*);

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

    void glClearColor(float, float, float, float);
    void glClear(int);
    void glLoadIdentity();
    void glEnable(int cap);
    void glDisable(int cap);
    void glBlendFunc(int sfactor, int dfactor);
    void glColor3f(float, float, float);
    void glListBase(uint32_t base);
    void glCallLists(int n, int type, const char* s);
    void glRasterPos2f(float, float);
    void glBegin(int);
    void glEnd();
    void glVertex3f(float, float, float);
    void glTexCoord2f(float, float);

    typedef void (*PFNGLXSWAPINTERVALEXTPROC)(Display*, Window, int);

    /* OpenAL */
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
    void alSourcef(uint32_t, int, float);
    void alSourcePlay(uint32_t);
    int alGetError();
    void alDeleteBuffers(int, uint32_t*);
]]

-- OpenAL constants
local AL_FORMAT_MONO8    = 0x1100
local AL_FORMAT_MONO16   = 0x1101
local AL_FORMAT_STEREO8  = 0x1102
local AL_FORMAT_STEREO16 = 0x1103
local AL_GAIN            = 0x100A
local AL_BUFFER          = 0x1009

-- OpenGL constants
local GL_TEXTURE_2D = 0x0DE1
local GL_RGB = 0x1907
local GL_RGBA = 0x1908
local GL_UNSIGNED_BYTE = 0x1401
local GL_LINEAR = 0x2601
local GL_TEXTURE_MIN_FILTER = 0x2801
local GL_TEXTURE_MAG_FILTER = 0x2800

local function load_file(path)
    local f = io.open(path, "rb")
    local d = f:read("*all")
    f:close()
    return ffi.new("unsigned char[?]", #d, d), #d
end

local function create_font(path)
    local ttf, size = load_file(path)

    if not ttf or size == 0 then
        return nil
    end

    local W, H = 512, 512
    local bitmap = ffi.new("unsigned char[?]", W * H)
    local cdata = ffi.new("stbtt_bakedchar[96]")

    if not libs.stb then
        return nil
    end

    local px = 24.0
    local result = libs.stb.stbtt_BakeFontBitmap(
        ttf, 0,
        px,
        bitmap,
        W, H,
        32, 96,
        cdata
    )

    local rgba = ffi.new("unsigned char[?]", W * H * 4)
    for i = 0, W * H - 1 do
        local v = bitmap[i]
        rgba[i * 4] = 255
        rgba[i * 4 + 1] = 255
        rgba[i * 4 + 2] = 255
        rgba[i * 4 + 3] = v
    end

    local tex = ffi.new("unsigned int[1]")
    libs.gl.glGenTextures(1, tex)
    libs.gl.glBindTexture(GL_TEXTURE_2D, tex[0])

    libs.gl.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
        W, H, 0,
        GL_RGBA, GL_UNSIGNED_BYTE,
        rgba
    )

    libs.gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    libs.gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

    return {
        tex = tex[0],
        cdata = cdata,
        w = W,
        h = H,
        px = px
    }
end

local function draw_text(font, px, py, text)
    local gl = libs.gl
    gl.glEnable(GL_TEXTURE_2D)
    gl.glColor3f(1, 1, 1)
    gl.glBindTexture(GL_TEXTURE_2D, font.tex)

    gl.glBegin(7)
    gl.glTexCoord2f(0, 0)
    gl.glVertex3f(-0.5, -0.8, 0)
    gl.glTexCoord2f(1, 0)
    gl.glVertex3f(0.5, -0.8, 0)
    gl.glTexCoord2f(1, 1)
    gl.glVertex3f(0.5, -0.5, 0)
    gl.glTexCoord2f(0, 1)
    gl.glVertex3f(-0.5, -0.5, 0)
    gl.glEnd()

    gl.glDisable(GL_TEXTURE_2D)
end

_G.window_impl = {
    draw_text = draw_text,
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

        local swp_ptr = libs.glx.glXGetProcAddress("glXSwapIntervalEXT")
        if swp_ptr ~= nil then
            ffi.cast("PFNGLXSWAPINTERVALEXTPROC", swp_ptr)(dpy, win, 0)
        end

        local font = create_font("/home/frontline/SUNBURN/assets/fonts/font.ttf")

        _G._window = {
            dpy = dpy,
            win = win,
            ctx = ctx,
            font = font
        }
        return _G._window
    end,

    should_close = function(obj)
        local ev = ffi.new("XEvent")
        libs.x11.XFlush(obj.dpy)

        while libs.x11.XPending(obj.dpy) > 0 do
            libs.x11.XNextEvent(obj.dpy, ev)
            if ev.type == 33 or ev.type == 17 then
                return true
            end
        end
        return false
    end,

    swap = function(obj)
        libs.gl.glXMakeCurrent(obj.dpy, obj.win, obj.ctx)
        libs.gl.glXSwapBuffers(obj.dpy, obj.win)
    end,

    destroy = function(obj)
        libs.gl.glXMakeCurrent(obj.dpy, 0, nil)
        libs.gl.glXDestroyContext(obj.dpy, obj.ctx)
        libs.x11.XDestroyWindow(obj.dpy, obj.win)
        libs.x11.XCloseDisplay(obj.dpy)
    end
}

---------------------------------------------------
-- AUDIO
---------------------------------------------------

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
    audio_impl = _G.audio_impl,
    draw_text = draw_text
}
