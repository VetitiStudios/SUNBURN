# Loader (`bin/loader.lua`)

The loader handles platform detection and loads the appropriate native libraries.

## Platform Detection

```lua
local arch = ffi.abi("64bit") and "x64" or "x86"
```

The loader detects:
- Operating system (`ffi.os` - "Linux" or "Windows")
- Architecture (64-bit or 32-bit)

## Library Loading

### Linux
Loads system libraries via `ffi.load`:
- `X11` - Window management
- `GL` - OpenGL rendering
- `./bin/linux_x64/libopenal.so` - OpenAL audio (with graceful fallback)

Loads platform implementation:
- `bin.linux_x64.x11_init`

### Windows
Loads system libraries:
- `opengl32` - OpenGL
- `user32` - Window management
- `gdi32` - Graphics

Loads platform implementation:
- `bin.win_x64.init`

## Global Export

All loaded libraries are stored in `_G.libs`:

```lua
_G.libs = {
    x11 = <X11 library>,
    gl = <OpenGL library>,
    al = <OpenAL library>,
    user32 = <Windows user32>,
    gdi32 = <Windows gdi32>
}
```

## Usage

The loader is called once at startup in `main.lua`:

```lua
local loader = require("bin.loader")
local libs = loader.init()
_G.libs = libs
```
