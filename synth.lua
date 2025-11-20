local Story = require("story")

local Synth = {}
Synth.__index = Synth

local TAU = math.pi * 2

local function log2(x)
    return math.log(x) / math.log(2)
end

function Synth.new(story)
    local self = setmetatable({}, Synth)
    self:set_story(story)

    self.sample_rate = 44100
    self.buffer_size = 2048
    self.source = love.audio.newQueueableSource(self.sample_rate, 16, 1, 8)
    self.phase = 0
    self.noise_phase = 0
    self.rng = love.math.newRandomGenerator()
    self.primary = {freq = 220, amp = 0.5}
    self.target = {freq = 220, amp = 0.5}
    self.hue = 0
    self.blur = 0

    return self
end

function Synth.frequency_to_midi(freq)
    if freq <= 0 then
        return 0
    end
    return math.floor(69 + 12 * log2(freq / 440) + 0.5)
end

function Synth:entry_frequency(entry)
    if not entry then
        return 0
    end
    local profile = self.story:get_mood_profile(entry.mood)
    return profile.base_freq
end

function Synth:set_story(story)
    self.story = story
    self.time = 0
    self.mood_shift = 0
    self.last_entry_id = nil
end

function Synth:get_fingerprint()
    local entry = self.story:get_current_entry()
    if not entry then
        return "empty lattice"
    end
    local profile = self.story:get_mood_profile(entry.mood)
    return string.format("%s @ %.2f Hz", profile.name, profile.base_freq)
end

function Synth:sync_scene()
    self.last_entry_id = nil
end

local function mix_harmonics(profile, t)
    local freq = profile.base_freq * (1.0 + math.sin(t * 0.35) * 0.07)
    local amp = 0
    for _, harmonic in ipairs(profile.harmonics) do
        amp = amp + harmonic.amp
    end
    return freq, amp
end

function Synth:update(dt, rewind)
    if not self.story then
        return
    end

    local entry = self.story:get_current_entry()
    if not entry then
        return
    end

    local profile = self.story:get_mood_profile(entry.mood)
    local freq, amp = mix_harmonics(profile, self.time or 0)
    self.target.freq = freq
    self.target.amp = amp
    self.primary.freq = self.primary.freq + (self.target.freq - self.primary.freq) * (1 - math.exp(-dt * 2.4))
    self.primary.amp = self.primary.amp + (self.target.amp - self.primary.amp) * (1 - math.exp(-dt * 2.4))

    self.blur = self.blur + ((rewind > 0.05 and 0.75 or 0.15) - self.blur) * (1 - math.exp(-dt * 5))

    if not self.source:isPlaying() then
        self.source:play()
    end

    while self.source:getFreeBufferCount() > 0 do
        local data = love.sound.newSoundData(self.buffer_size, self.sample_rate, 16, 1)
        local base = self.primary.freq
        local total_samples = self.buffer_size
        local noise_amt = profile.noise + rewind * 0.2

        for i = 0, total_samples - 1 do
            self.phase = self.phase + base / self.sample_rate
            if self.phase > 1 then
                self.phase = self.phase - 1
            end

            local sample = 0
            for _, harmonic in ipairs(profile.harmonics) do
                local h_phase = self.phase * harmonic.ratio
                sample = sample + math.sin(h_phase * TAU) * harmonic.amp
            end

            self.noise_phase = self.noise_phase + 0.0017
            local noise = (self.rng:random() - 0.5) * noise_amt
            local rewind_mod = math.sin((self.time or 0) * 0.5 + i / total_samples * TAU) * self.blur * 0.35
            local value = (sample * 0.4 + noise + rewind_mod)
            data:setSample(i, value)
        end

        self.source:queue(data)
    end

    self.time = (self.time or 0) + dt
end

return Synth
