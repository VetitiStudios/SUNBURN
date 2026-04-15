# Platform: Linux (`bin/linux_x64/x11_init.lua`)

Linux implementation using X11, GLX, and OpenAL.

## Dependencies

- `libx11-dev` - X11 windowing
- `libgl-dev` - OpenGL
- `libopenal-dev` - Audio
- `libx11-6`

## Window Implementation

### `window_impl.create(width, height, title)`

Creates an X11 window with OpenGL context.

1. Opens X11 display connection
2. Chooses RGBA visual with double buffering
3. Creates simple window
4. Sets `WM_DELETE_WINDOW` protocol for proper close handling
5. Creates GLX context and makes it current
6. Disables vsync via `glXSwapIntervalEXT`
7. Loads font "9x15" for bitmap text

**Returns:** Handle object:
```lua
{
    dpy = <Display*>,
    win = <Window>,
    wm_delete = <Atom>,
    ctx = <GLXContext>
}
```

### `window_impl.should_close(obj)`

Checks for window close events.

**Close conditions:**
- `ClientMessage` (type 33) with `WM_DELETE_WINDOW` atom
- `DestroyNotify` (type 17)

### `window_impl.swap(obj)`

Calls `glXSwapBuffers()` for double buffering.

### `window_impl.destroy(obj)`

Properly cleans up:
1. Clears OpenGL context
2. Destroys GLX context
3. Destroys X11 window
4. Closes display connection

## Audio Implementation

### `audio_impl.init()`

Opens default OpenAL device and creates context.

**Returns:** Context object:
```lua
{
    device = <ALCdevice*>,
    context = <ALCcontext*>
}
```

### `audio_impl.create_source()`

Generates an OpenAL source with default gain of 1.0.

### `audio_impl.play_pcm(source_id, data, size, freq, channels, bits)`

Uploads PCM data to a buffer and plays it.

1. Generates buffer
2. Copies data to stable memory
3. Uploads to OpenAL with appropriate format
4. Queues buffer on source
5. Starts playback

### `audio_impl.destroy(obj)`

Shuts down OpenAL:
1. Clears current context
2. Destroys context
3. Closes device

## OpenGL Functions

The following OpenGL functions are declared and available via `libs.gl`:

```c
glClearColor(float, float, float, float)
glClear(int)
glRasterPos2f(float, float)
glListBase(uint32_t)
glCallLists(int, int, const char*)
glColor3f(float, float, float)
glLoadIdentity()
glBegin(int)
glEnd()
glVertex3f(float, float, float)
```

## Bitmap Text Rendering

Uses X11 font "9x15" loaded at 32-127 ASCII range:

```lua
gl.glListBase(1000 - 32)        -- Set base list
gl.glCallLists(#txt, 0x1401, txt)  -- Render string
```
