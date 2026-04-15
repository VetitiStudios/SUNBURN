local ffi = require("ffi")
local loader = {}

local arch = ffi.abi("64bit") and "x64" or "x86"

function loader.init()
    local libs = {}
    
    if ffi.os == "Windows" then
        require("bin.win_" .. arch .. ".init")
        libs.gl = ffi.load("opengl32")
        libs.user32 = ffi.load("user32")
        libs.gdi32 = ffi.load("gdi32")
    elseif ffi.os == "Linux" then
        libs.x11 = ffi.load("X11")
        libs.gl = ffi.load("GL")
        -- Explicitly load OpenAL if the file exists
        local al_status, al_handle = pcall(ffi.load, "./bin/linux_x64/libopenal.so")
        libs.al = al_status and al_handle or nil
        
        require("bin.linux_" .. arch .. ".x11_init")
    end

    _G.libs = libs
    return libs
end

return loader
