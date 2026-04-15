local ffi = require("ffi")
local audio = {}

function audio.init()
    if not libs.al then return nil end
    return _G.audio_impl.init()
end

function audio.new_source()
    return _G.audio_impl.create_source()
end

function audio.play_test_tone(source_id)
    local sample_rate = 44100
    local duration = 0.5
    local count = sample_rate * duration
    local samples = ffi.new("int16_t[?]", count)
    for i = 0, count - 1 do
        samples[i] = math.sin(i * (440 * 2 * math.pi) / sample_rate) > 0 and 2000 or -2000
    end
    _G.audio_impl.play_pcm(source_id, samples, count * 2, sample_rate, 1, 16)
end

function audio.quit(obj)
    if obj then _G.audio_impl.destroy(obj) end
end

return audio
