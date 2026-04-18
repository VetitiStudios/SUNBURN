# Platform: Windows (`bin/win_x64/init.lua`)

Windows implementation using Win32 GDI/OpenGL (WGL).

## Dependencies

- `opengl32.dll` - OpenGL (system DLL)

## Window Implementation

### `window_impl.create(width, height, title)`

Creates a Win32 window with OpenGL context.

1. Registers window class
2. Creates overlapped window
3. Gets device context (DC)
4. Sets up pixel format descriptor
5. Creates OpenGL rendering context (RC)
6. Makes RC current

**Returns:** Handle object:
```lua
{
    hwnd = <HWND>,
    hdc = <HDC>,
    hrc = <HGLRC>
}
```

### `window_impl.should_close(obj)`

Checks for close messages.

**Close messages:**
- `WM_CLOSE` (0x0010)
- `WM_QUIT` (0x0012)

### `window_impl.swap(obj)`

Calls `SwapBuffers()` for double buffering.

### `window_impl.destroy(obj)`

Properly cleans up:
1. Removes window class
2. Destroys window
3. Releases device context

## Notes

- Currently uses GDI for rendering (no hardware acceleration)
- Message loop runs in `should_close()`
- Font rendering not yet implemented
