# Engine Functions (`util/engine.lua`)

Manages the game loop, timing, and scene lifecycle.

---

## `engine.init(scene)`

Initializes the engine with a scene and starts the game timing.

```lua
engine.init(scene)
```

**Parameters:**

| Name  | Type   | Description                                       |
|-------|--------|---------------------------------------------------|
| scene | table  | Scene table with optional load/update/draw        |

**Behavior:**

- Stores scene reference globally
- Initializes timing system
- Calls `scene.load()` immediately
- Resets FPS counter

---

## `engine.update()`

Updates game logic and timing. Call once per frame in your main loop.

```lua
engine.update()
```

**Behavior:**

- Calculates delta time (`dt`) since last frame
- Increments frame counter
- Updates FPS every 1 second
- Calls `scene.update(dt, fps)` with timing data

---

## `engine.step()`

Renders the current frame. Call once per frame after `engine.update()`.

```lua
engine.step()
```

**Behavior:**

- Calls `scene.draw()` for rendering

---

## Timing Details

| Variable | Description                                              |
|----------|----------------------------------------------------------|
| dt       | Delta time in seconds (time since last frame)            |
| fps      | Current frames per second (updated every 1 second)       |
| frames   | Frame counter (resets each FPS update)                   |

---

## Typical Main Loop

```lua
engine.init(scene)

while not window_should_close do
    engine.update()  -- Logic + timing
    engine.step()    -- Rendering
    window.swap()
end
```
