# Audio Functions (`util/audio.lua`)

OpenAL-based audio playback system.

---

## `audio.init()`

Initializes the OpenAL audio system.

```lua
local audio_ctx = audio.init()
```

**Returns:** `table` - Audio context object, or `nil` if init failed

**Example:**

```lua
local my_audio = audio.init()
if not my_audio then
    print("Audio initialization failed")
end
```

---

## `audio.new_source()`

Creates a new audio source.

```lua
local source_id = audio.new_source()
```

**Returns:** `number` - OpenAL source ID (uint32)

**Example:**

```lua
local src = audio.new_source()
```

---

## `audio.play_test_tone(source_id)`

Plays a 440Hz (A4) sine wave test tone.

```lua
audio.play_test_tone(source_id)
```

**Parameters:**

| Name       | Type   | Description                    |
|------------|--------|--------------------------------|
| source_id  | number | Source ID from `new_source()`  |

**Example:**

```lua
local src = audio.new_source()
audio.play_test_tone(src)
```

---

## `audio.quit(audio_ctx)`

Shuts down the audio system and releases resources.

```lua
audio.quit(audio_ctx)
```

**Parameters:**

| Name       | Type   | Description                    |
|------------|--------|--------------------------------|
| audio_ctx  | table  | Audio context from `init()`    |

**Example:**

```lua
if my_audio then
    audio.quit(my_audio)
end
```

---

## Low-Level PCM Playback

For custom audio data, use `audio_impl.play_pcm()`:

```lua
audio_impl.play_pcm(source_id, data, size, freq, channels, bits)
```

**Parameters:**

| Name       | Type     | Description                            |
|------------|----------|----------------------------------------|
| source_id  | number   | OpenAL source ID                       |
| data       | pointer  | Pointer to PCM audio data              |
| size       | number   | Size of data in bytes                  |
| freq       | number   | Sample rate (e.g., 44100, 48000)       |
| channels   | number   | 1 for mono, 2 for stereo               |
| bits       | number   | 8 or 16 bits per sample                |

**Format Constants:**

| Value  | Constant              | Description                 |
|--------|----------------------|------------------------------|
| 0x1100 | AL_FORMAT_MONO8      | 1 channel, 8-bit             |
| 0x1101 | AL_FORMAT_MONO16     | 1 channel, 16-bit            |
| 0x1102 | AL_FORMAT_STEREO8    | 2 channels, 8-bit            |
| 0x1103 | AL_FORMAT_STEREO16   | 2 channels, 16-bit           |

**Example:**

```lua
-- Generate 440Hz tone
local sample_rate = 44100
local duration = 0.5
local count = sample_rate * duration
local samples = ffi.new("int16_t[?]", count)
for i = 0, count - 1 do
    samples[i] = math.sin(i * (440 * 2 * math.pi) / sample_rate) > 0
        and 2000 or -2000
end

local src = audio.new_source()
audio_impl.play_pcm(src, samples, count * 2, sample_rate, 1, 16)
```
