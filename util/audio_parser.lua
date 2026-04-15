local ffi = require("ffi")

local parser = {}

-- read helpers (little endian)
local function read_u16(ptr)
    return ptr[0] + ptr[1] * 256
end

local function read_u32(ptr)
    return ptr[0]
        + ptr[1] * 256
        + ptr[2] * 65536
        + ptr[3] * 16777216
end

function parser.load_wav(filename)
    local file = io.open(filename, "rb")
    if not file then return nil, "File not found" end

    local content = file:read("*a")
    file:close()

    local len = #content
    if len < 44 then return nil, "File too small" end

    -- stable copy of entire wav file
    local buf = ffi.new("uint8_t[?]", len)
    ffi.copy(buf, content, len)

    local ptr = ffi.cast("uint8_t*", buf)

    -- header validation
    if ffi.string(ptr, 4) ~= "RIFF" or ffi.string(ptr + 8, 4) ~= "WAVE" then
        return nil, "Invalid WAV header"
    end

    local format = 1
    local channels = 1
    local sample_rate = 44100
    local bits = 16

    local data_offset = 0
    local data_size = 0

    local offset = 12

    -- chunk parsing
    while offset + 8 <= len do
        local chunk_id = ffi.string(ptr + offset, 4)
        local chunk_size = read_u32(ptr + offset + 4)

        if chunk_id == "fmt " then
            format = read_u16(ptr + offset + 8)
            channels = read_u16(ptr + offset + 10)
            sample_rate = read_u32(ptr + offset + 12)
            bits = read_u16(ptr + offset + 22)

        elseif chunk_id == "data" then
            data_offset = offset + 8
            data_size = chunk_size
            break
        end

        offset = offset + 8 + chunk_size
        if chunk_size % 2 == 1 then
            offset = offset + 1
        end
    end

    if data_offset == 0 then
        return nil, "No data chunk"
    end

    if format ~= 1 then
        return nil, "Unsupported WAV format (only PCM): " .. tostring(format)
    end

    if bits ~= 16 then
        return nil, "Only 16-bit WAV supported (got " .. tostring(bits) .. ")"
    end

    if channels < 1 or channels > 2 then
        return nil, "Unsupported channel count: " .. tostring(channels)
    end

    -- PCM data copy (NO malloc)
    local audio_data = ffi.new("uint8_t[?]", data_size)
    ffi.copy(audio_data, ptr + data_offset, data_size)

    local wav = {
        data = audio_data,
        size = data_size,
        rate = sample_rate,
        channels = channels,
        bits = bits,
        format = format,
        _buffer = buf -- keep file alive
    }

    print("=== WAV LOADED ===")
    print("format:", wav.format)
    print("channels:", wav.channels)
    print("bits:", wav.bits)
    print("rate:", wav.rate)
    print("size:", wav.size)
    print("==================")

    return wav
end

function parser.save_burn(wav, path)
    local samples = math.floor(wav.size / 2 / wav.channels)
    local mono_size = samples * 2

    local out = ffi.new("uint8_t[?]", mono_size)
    local dst = ffi.cast("int16_t*", out)
    local src = ffi.cast("int16_t*", wav.data)

    if wav.channels == 1 then
        for i = 0, samples - 1 do
            dst[i] = src[i]
        end
    else
        for i = 0, samples - 1 do
            local l = src[i * 2]
            local r = src[i * 2 + 1]
            dst[i] = (l + r) / 2
        end
    end

    local f = io.open(path, "wb")
    f:write("BURN")

    f:write(string.char(wav.rate % 256))
    f:write(string.char(math.floor(wav.rate / 256) % 256))

    f:write(string.char(samples % 256))
    f:write(string.char(math.floor(samples / 256) % 256))

    f:write(string.char(1))   -- mono
    f:write(string.char(16))  -- bits

    f:write(ffi.string(out, mono_size))
    f:close()

    return true
end

function parser.load_burn(path)
    local f = io.open(path, "rb")
    if not f then return nil, "missing burn file" end

    local header = f:read(8)
    if not header or header:sub(1, 4) ~= "BURN" then
        return nil, "invalid burn"
    end

    local rate = header:byte(5) + header:byte(6) * 256
    local samples = header:byte(7) + header:byte(8) * 256

    local data = f:read("*a")
    f:close()

    return {
        data = data,
        size = #data,
        rate = rate,
        samples = samples,
        channels = 1,
        bits = 16
    }
end

return parser