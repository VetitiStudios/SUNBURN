# Main Entry Point (`main.lua`)

Entry point configuration and game setup.

---

## Default Configuration

```lua
-- Setup
package.path = './?.lua;' .. package.path
local loader = require("bin.loader")
local libs = loader.init()
_G.libs = libs

-- Modules
local audio_parser = require("util.audio_parser")
local win_sys = require("util.window")
local engine = require("util.engine")
local scene = require("scenes.init")

-- Audio conversion
os.execute("mkdir -p temps")
local wav = audio_parser.load_wav("assets/sounds/meow.wav")
audio_parser.save_burn(wav, "temps/meow.burn")

-- Create window (800x600 default)
local my_win = win_sys.create(800, 600, "SUNBURN")

-- Initialize audio
local my_audio = _G.audio_impl.init()

-- Start engine
engine.init(scene)

-- Main loop
while not win_sys.should_close(my_win) do
    engine.update()
    engine.step()
    win_sys.swap(my_win)
end

-- Cleanup
_G.audio_impl.destroy(my_audio)
win_sys.destroy(my_win)
```

---

## Customizing Window

Change window size and title:

```lua
-- Resolution
local my_win = win_sys.create(1280, 720, "My Game")

-- Title
local my_win = win_sys.create(800, 600, "Epic Adventure")
```

---

## Customizing Scene

Replace the default scene:

```lua
-- Create your scene in scenes/my_game.lua
local scene = require("scenes.my_game")
```

---

## Customizing Audio

Change the audio file to load:

```lua
local wav = audio_parser.load_wav("assets/sounds/explosion.wav")
audio_parser.save_burn(wav, "temps/explosion.burn")
```

---

## Running

```bash
luajit main.lua
```

---

## Cleanup

The `temps/` directory is automatically created and used for BURN audio files. It's cleaned up when the game exits.
