local ffi = require("ffi")
local engine = {}
local tv = ffi.new("timeval")

local function get_time()
    if pcall(function() return ffi.C.gettimeofday end) then
        ffi.C.gettimeofday(tv, nil)
        return tonumber(tv.tv_sec) + tonumber(tv.tv_usec) / 1000000
    end
    return os.clock()
end

function engine.init(scene)
    engine.scene = scene
    engine.last_time = get_time()
    engine.fps = 0
    engine.frames = 0
    if engine.scene.load then engine.scene.load() end
end

function engine.update()
    local current_time = get_time()
    local dt = current_time - engine.last_time
    engine.frames = engine.frames + 1
    if dt >= 1.0 then
        engine.fps = math.floor(engine.frames / dt)
        engine.frames = 0
        engine.last_time = current_time
    end
    if engine.scene.update then engine.scene.update(dt, engine.fps) end
end

function engine.step()
    if engine.scene.draw then engine.scene.draw() end
end

return engine
