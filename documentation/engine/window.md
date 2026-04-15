# Window Functions (`util/window.lua`)

Cross-platform window management.

---

## `window.create(width, height, title)`

Creates a new window with an OpenGL context.

```lua
local win = window.create(width, height, title)
```

**Parameters:**

| Name   | Type   | Description                    |
|--------|--------|--------------------------------|
| width  | number | Window width in pixels         |
| height | number | Window height in pixels        |
| title  | string | Window title bar text          |

**Returns:** `table` - Window handle object

**Example:**

```lua
local win = window.create(1280, 720, "My Game")
```

---

## `window.should_close(win)`

Checks if the user requested to close the window.

```lua
local should_close = window.should_close(win)
```

**Parameters:**

| Name | Type   | Description                              |
|------|--------|------------------------------------------|
| win  | table  | Window handle from `window.create()`     |

**Returns:** `boolean` - `true` if close requested, `false` otherwise

**Example:**

```lua
while not window.should_close(win) do
    -- game loop
end
```

---

## `window.swap(win)`

Swaps the front and back buffers (double buffering).

```lua
window.swap(win)
```

**Parameters:**

| Name | Type   | Description                              |
|------|--------|------------------------------------------|
| win  | table  | Window handle from `window.create()`     |

**Behavior:** Copies the rendered image to the screen. Call once per
frame after rendering.

**Example:**

```lua
engine.step()     -- Render frame
window.swap(win)  -- Show on screen
```

---

## `window.destroy(win)`

Closes the window and releases all resources.

```lua
window.destroy(win)
```

**Parameters:**

| Name | Type   | Description                              |
|------|--------|------------------------------------------|
| win  | table  | Window handle from `window.create()`     |

**Behavior:**

- Destroys OpenGL context
- Closes window
- Releases system resources

**Example:**

```lua
window.destroy(win)
```

---

## Complete Example

```lua
local win = window.create(800, 600, "My Game")

while not window.should_close(win) do
    engine.update()
    engine.step()
    window.swap(win)
end

window.destroy(win)
```
