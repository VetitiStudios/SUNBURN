# Audio Parser Functions (`util/audio_parser.lua`)

WAV file parsing and BURN format conversion.

---

## `parser.load_wav(filename)`

Loads and validates a WAV audio file.

```lua
local wav = parser.load_wav(filename)
```

**Parameters:**

| Name      | Type   | Description                  |
|-----------|--------|------------------------------|
| filename  | string | Path to WAV file             |

**Returns:** `table` or `nil, error`

**Supported Formats:**

- Format: PCM (format code 1)
- Bits: 16-bit only
- Channels: 1 (mono) or 2 (stereo)

**Return Table Fields:**

| Field     | Type     | Description                          |
|-----------|----------|--------------------------------------|
| data      | pointer  | Pointer to audio data (16-bit PCM)   |
| size      | number   | Size of data in bytes                |
| rate      | number   | Sample rate (e.g., 44100, 48000)     |
| channels  | number   | Channel count (1 or 2)               |
| bits      | number   | Bits per sample (16)                 |
| format    | number   | WAV format code (1 for PCM)          |

**Example:**

```lua
local wav, err = parser.load_wav("assets/sounds/meow.wav")
if not wav then
    print("Error loading WAV:", err)
    return
end
print("Loaded:", wav.rate .. "Hz", wav.channels .. "ch", wav.bits .. "bit")
```

---

## `parser.save_burn(wav, path)`

Converts WAV data to BURN format and saves to file.

```lua
local ok, err = parser.save_burn(wav, path)
```

**Parameters:**

| Name  | Type   | Description                          |
|-------|--------|--------------------------------------|
| wav   | table  | WAV data from `parser.load_wav()`    |
| path  | string | Output file path                     |

**Returns:** `true` on success, or `nil, error`

**Conversion:**

- Stereo audio is mixed to mono
- Output is always 16-bit mono PCM

**Example:**

```lua
local wav = parser.load_wav("assets/sounds/meow.wav")
local ok, err = parser.save_burn(wav, "temps/meow.burn")
if not ok then
    print("Error:", err)
end
```

---

## `parser.load_burn(path)`

Loads a BURN format audio file.

```lua
local burn = parser.load_burn(path)
```

**Parameters:**

| Name  | Type   | Description                  |
|-------|--------|------------------------------|
| path  | string | Path to BURN file            |

**Returns:** `table` or `nil, error`

**Return Table Fields:**

| Field     | Type   | Description                         |
|-----------|--------|-------------------------------------|
| data      | string | Raw PCM audio data                  |
| size      | number | Size of data in bytes               |
| rate      | number | Sample rate                         |
| samples   | number | Total sample count                  |
| channels  | number | Always 1 (mono)                     |
| bits      | number | Always 16                           |

**Example:**

```lua
local burn = parser.load_burn("temps/meow.burn")
if burn then
    print("Sample rate:", burn.rate)
    print("Duration:", burn.samples / burn.rate .. "s")
end
```

---

## BURN Format Structure

| Offset | Size | Description                          |
|--------|------|--------------------------------------|
| 0      | 4    | Magic bytes: "BURN"                  |
| 4      | 2    | Sample rate (little-endian)          |
| 6      | 2    | Sample count (little-endian)         |
| 8      | 1    | Channel count (always 1)             |
| 9      | 1    | Bits per sample (always 16)          |
| 10     | N    | Raw PCM data (mono 16-bit)           |

---

## Complete Audio Loading Example

```lua
local audio_parser = require("util.audio_parser")

-- Load WAV and convert to BURN
local wav = audio_parser.load_wav("assets/sounds/meow.wav")
if wav then
    audio_parser.save_burn(wav, "temps/meow.burn")
end

-- Later, in scene.load()
local burn = audio_parser.load_burn("temps/meow.burn")
if burn then
    local src = ffi.new("uint32_t[1]")
    _G.libs.al.alGenSources(1, src)
    
    local buf = ffi.new("uint32_t[1]")
    _G.libs.al.alGenBuffers(1, buf)
    
    local pcm = ffi.new("uint8_t[?]", burn.size)
    ffi.copy(pcm, burn.data, burn.size)
    
    _G.libs.al.alBufferData(buf[0], 0x1101, pcm, burn.size, burn.rate)
    _G.libs.al.alSourcei(src[0], 0x1009, buf[0])
    _G.libs.al.alSourcePlay(src[0])
end
```
