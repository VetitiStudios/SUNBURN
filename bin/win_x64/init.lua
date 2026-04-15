local ffi = require("ffi")
ffi.cdef[[
    typedef void* HWND; typedef void* HDC; typedef void* HGLRC;
    typedef struct { int nSize; int nVersion; uint32_t dwFlags; uint8_t iPixelType; uint8_t cColorBits; uint8_t cRedBits; uint8_t cRedShift; uint8_t cGreenBits; uint8_t cGreenShift; uint8_t cBlueBits; uint8_t cBlueShift; uint8_t cAlphaBits; uint8_t cAlphaShift; uint8_t cAccumBits; uint8_t cAccumRedBits; uint8_t cAccumGreenBits; uint8_t cAccumBlueBits; uint8_t cAccumAlphaBits; uint8_t cDepthBits; uint8_t cStencilBits; uint8_t cAuxBuffers; uint8_t iLayerType; uint8_t bReserved; uint32_t dwLayerMask; uint32_t dwVisibleMask; uint32_t dwDamageMask; } PIXELFORMATDESCRIPTOR;
    typedef struct { HWND hwnd; uint32_t message; uint64_t wParam; int64_t lParam; uint32_t time; int pt_x; int pt_y; } MSG;
    HWND CreateWindowExA(uint32_t, const char*, const char*, uint32_t, int, int, int, int, HWND, void*, void*, void*);
    HDC GetDC(HWND);
    int ChoosePixelFormat(HDC, const PIXELFORMATDESCRIPTOR*);
    bool SetPixelFormat(HDC, int, const PIXELFORMATDESCRIPTOR*);
    HGLRC wglCreateContext(HDC);
    bool wglMakeCurrent(HDC, HGLRC);
    bool wglUseFontBitmapsA(HDC, uint32_t, uint32_t, uint32_t);
    bool PeekMessageA(MSG*, HWND, uint32_t, uint32_t, uint32_t);
    bool TranslateMessage(const MSG*);
    int64_t DispatchMessageA(const MSG*);
    bool SwapBuffers(HDC);
    void* wglGetProcAddress(const char*);
    typedef bool (__stdcall *PFNWGLSWAPINTERVALEXTPROC)(int interval);
    void glClearColor(float r, float g, float b, float a);
    void glClear(int mask);
    void glRasterPos2f(float x, float y);
    void glListBase(uint32_t base);
    void glCallLists(int n, int type, const char* s);
    void glColor3f(float r, float g, float b);
    void glLoadIdentity();
]]

_G.window_impl = {
    create = function(libs, w, h, title)
        local hwnd = libs.user32.CreateWindowExA(0, "EDIT", title, 0x10CF0000, 100, 100, w, h, nil, nil, nil, nil)
        local hdc = libs.user32.GetDC(hwnd)
        local pfd = ffi.new("PIXELFORMATDESCRIPTOR", { nSize = ffi.sizeof("PIXELFORMATDESCRIPTOR"), nVersion = 1, dwFlags = 37, iPixelType = 0, cColorBits = 32, cDepthBits = 24 })
        libs.gdi32.SetPixelFormat(hdc, libs.gdi32.ChoosePixelFormat(hdc, pfd), pfd)
        local hglrc = libs.gl.wglCreateContext(hdc)
        libs.gl.wglMakeCurrent(hdc, hglrc)
        local swp = ffi.cast("PFNWGLSWAPINTERVALEXTPROC", libs.gl.wglGetProcAddress("wglSwapIntervalEXT"))
        if swp ~= nil then swp(0) end
        libs.gl.wglUseFontBitmapsA(hdc, 32, 96, 1000)
        return { type = "win", handle = hwnd, hdc = hdc, font_base = 1000 }
    end,
    should_close = function(libs, obj)
        local msg = ffi.new("MSG")
        while libs.user32.PeekMessageA(msg, obj.handle, 0, 0, 1) do
            if msg.message == 0x0012 or msg.message == 0x0010 then return true end
            libs.user32.TranslateMessage(msg)
            libs.user32.DispatchMessageA(msg)
        end
        return false
    end,
    swap = function(libs, obj) libs.gdi32.SwapBuffers(obj.hdc) end
}
