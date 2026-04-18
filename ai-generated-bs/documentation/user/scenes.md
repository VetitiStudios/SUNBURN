# Scene Functions (`scenes/init.lua`)

Scenes contain your game's logic, state, and rendering.

---

## Scene Table

A scene is a Lua table with optional lifecycle functions:

```lua
local scene = {}
-- functions defined here
return scene
```

---

## `scene.load()`

Called once when the engine initializes with this scene.

```lua
function scene.load()
    -- initialization code
end
```

**When called:** When `engine.init(scene)` is called in `main.lua`

**Use for:**
- Setting OpenGL state (clear color, viewport)
- Loading audio files
- Initializing game state
- Creating OpenAL sources

**Example:**
```lua
function scene.load()
    libs.gl.glClearColor(0.1, 0.1, 0.3, 1.0)
    scene.score = 0
    scene.player_x = 0
end
```

---

## `scene.update(dt, fps)`

Called every frame for game logic.

```lua
function scene.update(dt, fps)
    -- game logic
end
```

**Use for:**
- Input handling
- Physics updates
- Game logic
- State changes
- Animation

**Example:**
```lua
function scene.update(dt, fps)
    scene.player_x = scene.player_x + dt * 100
    scene.fps = fps
end
```

---

## `scene.draw()`

Called every frame for rendering.

```lua
function scene.draw()
    -- rendering code
end
```

**When called:** After `scene.update()` each frame

**Use for:**
- OpenGL draw calls
- UI rendering
- Debug text

**Example:**
```lua
function scene.draw()
    local gl = libs.gl
    gl.glClear(0x4000)
    gl.glLoadIdentity()
    gl.glBegin(4)  -- GL_TRIANGLES
        gl.glColor3f(1, 0, 0)
        gl.glVertex3f(-0.5, -0.5, 0)
        gl.glColor3f(0, 1, 0)
        gl.glVertex3f(0.5, -0.5, 0)
        gl.glColor3f(0, 0, 1)
        gl.glVertex3f(0, 0.5, 0)
    gl.glEnd()
end
```

---

## Complete Scene Example

```lua
local ffi = require("ffi")
local scene = {}
local audio_parser = require("util.audio_parser")

function scene.load()
    libs.gl.glClearColor(0.1, 0.1, 0.2, 1.0)
    scene.fps = 0
    scene.rotation = 0
    
    local burn = audio_parser.load_burn("temps/meow.burn")
    if burn then
        local src = ffi.new("uint32_t[1]")
        _G.libs.al.alGenSources(1, src)
        scene.source = src[0]
        
        local buf = ffi.new("uint32_t[1]")
        _G.libs.al.alGenBuffers(1, buf)
        scene.buffer = buf[0]
        
        local pcm = ffi.new("uint8_t[?]", burn.size)
        ffi.copy(pcm, burn.data, burn.size)
        
        _G.libs.al.alBufferData(buf[0], 0x1101, pcm, burn.size, burn.rate)
        _G.libs.al.alSourcei(src[0], 0x1009, buf[0])
        _G.libs.al.alSourcePlay(src[0])
    end
end

function scene.update(dt, fps)
    scene.fps = fps
    scene.rotation = scene.rotation + dt * 90
end

function scene.draw()
    local gl = libs.gl
    gl.glClear(0x4000)
    gl.glLoadIdentity()
    
    gl.glBegin(4)
        gl.glColor3f(1, 0, 0)
        gl.glVertex3f(-0.5, -0.5, 0)
        gl.glColor3f(0, 1, 0)
        gl.glVertex3f(0.5, -0.5, 0)
        gl.glColor3f(0, 0, 1)
        gl.glVertex3f(0, 0.5, 0)
    gl.glEnd()
    
    local txt = scene.fps .. " FPS"
    gl.glColor3f(1, 1, 1)
    gl.glRasterPos2f(-0.9, 0.9)
    gl.glListBase(1000 - 32)
    gl.glCallLists(#txt, 0x1401, txt)
end

return scene
```
