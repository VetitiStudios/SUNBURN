io.stdout:setvbuf('no')
package.path = './?.lua;' .. package.path

local loader = require("bin.loader")
local libs = loader.init()
_G.libs = libs

local audio_parser = require("util.audio_parser")

print("Parsing audio files...")
os.execute("mkdir -p temps && rm -f temps/*.burn")
local wav = audio_parser.load_wav("assets/sounds/meow.wav")
if wav then
    local ok, err = audio_parser.save_burn(wav, "temps/meow.burn")
    if ok then
        local f = io.open("temps/meow.burn", "rb")
        local sz = f:seek("end")
        f:close()
        print("  Parsed: meow.wav -> meow.burn (" .. sz .. " bytes)")
    else
        print("  Error: " .. tostring(err))
    end
else
    print("  Error loading WAV")
end

local win_sys = require("util.window")
local engine = require("util.engine")
local scene = require("scenes.init")

local my_win = win_sys.create(800, 600, "SUNBURN ENGINE")
local my_audio = _G.audio_impl.init()

engine.init(scene)

while not win_sys.should_close(my_win) do
    engine.update()
    engine.step()
    win_sys.swap(my_win)
end

print("Cleaning up temps...")
os.execute("rm -rf temps/*")

if my_audio then
    _G.audio_impl.destroy(my_audio)
end
win_sys.destroy(my_win)
