local ffi = require("ffi")

ffi.cdef[[
    typedef void* wl_display;
    typedef void* wl_surface;
    typedef void* wl_egl_window;
    typedef void* EGLDisplay;
    typedef void* EGLConfig;
    typedef void* EGLContext;
    typedef void* EGLSurface;

    wl_display wl_display_connect(const char* name);
    void wl_display_disconnect(wl_display display);
    
    EGLDisplay eglGetDisplay(wl_display display);
    bool eglInitialize(EGLDisplay dpy, int* major, int* minor);
    void* eglGetProcAddress(const char* name);

    typedef struct { long tv_sec; long tv_usec; } timeval;
    int gettimeofday(timeval* t, void* tzp);

    void glClearColor(float r, float g, float b, float a);
    void glClear(int mask);
    void glRasterPos2f(float x, float y);
    void glListBase(uint32_t base);
    void glCallLists(int n, int type, const char* s);
    void glColor3f(float r, float g, float b);
    void glLoadIdentity();
]]

_G.window_impl = {
    create = function(w, h, title)
        print("[SUNBURN] Driver: Pure Wayland")
        
        -- Use the handle loaded in loader.lua
        local dpy = libs.wayland.wl_display_connect(nil)
        if dpy == nil then error("Wayland connection failed") end
        
        -- Minimal EGL setup to prevent "Wait..." hang
        local egl_dpy = libs.egl.eglGetDisplay(dpy)
        libs.egl.eglInitialize(egl_dpy, nil, nil)
        
        return { 
            type = "wayland", 
            display = dpy, 
            egl_display = egl_dpy,
            font_base = 1000 
        }
    end,

    should_close = function(obj) return false end,
    swap = function(obj) end -- Placeholder for eglSwapBuffers
}
