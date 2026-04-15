local ffi = require("ffi")
local scene = {}
local audio_parser = require("util.audio_parser")
local sfx_source

function scene.load()
    libs.gl.glClearColor(0.1, 0.1, 0.1, 1.0)
    scene.current_fps = 0
    
    local src = ffi.new("uint32_t[1]")
    _G.libs.al.alGenSources(1, src)
    sfx_source = src[0]
    
    local burn = audio_parser.load_burn("temps/meow.burn")
    if burn then
        local buf = ffi.new("uint32_t[1]")
        _G.libs.al.alGenBuffers(1, buf)
        
        local pcm = ffi.new("uint8_t[?]", burn.size)
        ffi.copy(pcm, burn.data, burn.size)
        
        _G.libs.al.alBufferData(buf[0], 0x1101, pcm, burn.size, burn.rate)
        _G.libs.al.alSourcei(sfx_source, 0x1009, buf[0])
        _G.libs.al.alSourcePlay(sfx_source)
        print("Playing meow...")
    else
        print("Sound Error: could not load burn file")
    end
end

function scene.update(dt, fps)
    scene.current_fps = fps
end

function scene.draw()
    local gl = libs.gl
    gl.glClear(0x4000)
    gl.glLoadIdentity()

    gl.glBegin(4) 
        gl.glColor3f(1, 0, 0) gl.glVertex3f(-0.5, -0.5, 0)
        gl.glColor3f(0, 1, 0) gl.glVertex3f(0.5, -0.5, 0)
        gl.glColor3f(0, 0, 1) gl.glVertex3f(0, 0.5, 0)
    gl.glEnd()

    local txt = (scene.current_fps or 0) .. " FPS"
    gl.glColor3f(1, 1, 1)
    gl.glRasterPos2f(-0.9, 0.9)
    gl.glListBase(1000 - 32)
    gl.glCallLists(#txt, 0x1401, txt)
end

return scene
