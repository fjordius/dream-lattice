local Synth = require("synth")

local Recorder = {}
Recorder.__index = Recorder

local function sanitize_filename(str)
    str = str:gsub("[^%w%-_]+", "_")
    if #str == 0 then
        str = "dream" .. os.time()
    end
    return str
end

function Recorder.new(story, synth)
    local self = setmetatable({}, Recorder)
    self:set_story(story)
    self.synth = synth
    self.status = "Press E to export snapshot"
    self.last_blink = 0
    self.blink_state = false
    return self
end

function Recorder:set_story(story)
    self.story = story
end

local function summarize_timeline(timeline)
    local lines = {}
    for i, entry in ipairs(timeline) do
        table.insert(lines, string.format("%02d. [%s] %s :: %s", i, entry.mood, entry.synapse or "", entry.line))
    end
    return table.concat(lines, "\n")
end

local function build_snapshot_text(fingerprint, summary)
    return string.format("Dream Lattice Snapshot\nFingerprint: %s\n\n%s", fingerprint, summary)
end

local function write_var_length(value)
    local buffer = {}
    repeat
        table.insert(buffer, 1, value % 128)
        value = math.floor(value / 128)
    until value == 0
    for i = 1, #buffer - 1 do
        buffer[i] = buffer[i] + 0x80
    end
    return buffer
end

local function write_be(value, bytes)
    local out = {}
    for i = bytes, 1, -1 do
        out[i] = value % 256
        value = math.floor(value / 256)
    end
    return out
end

local function midi_append_bytes(target, bytes)
    for i = 1, #bytes do
        table.insert(target, bytes[i])
    end
end

local function build_midi_data(timeline, story, synth)
    if #timeline == 0 then
        return nil
    end

    local tpq = 480
    local track = {}
    local last_tempo
    local lex = Story and Story.lexicon and Story.lexicon() or nil

    for index, entry in ipairs(timeline) do
        local profile = story:get_mood_profile(entry.mood)
        local tempo = profile and profile.tempo or 90
        if tempo ~= last_tempo then
            midi_append_bytes(track, write_var_length(0))
            local microseconds = math.floor(60000000 / tempo + 0.5)
            midi_append_bytes(track, {0xFF, 0x51, 0x03})
            midi_append_bytes(track, write_be(microseconds, 3))
            last_tempo = tempo
        end

        local freq = synth:entry_frequency(entry)
        local note = Synth.frequency_to_midi(freq)
        note = math.max(0, math.min(127, note))

        midi_append_bytes(track, write_var_length(0))
        midi_append_bytes(track, {0x90, note, 100})

        local next_entry = timeline[index + 1]
        local duration = entry.duration
        if (not duration or duration <= 0) and next_entry and entry.timestamp then
            duration = math.max(0.25, next_entry.timestamp - entry.timestamp)
        end
        duration = duration or 3.0
        local ticks = math.max(60, math.floor(duration * tempo / 60 * tpq + 0.5))

        midi_append_bytes(track, write_var_length(ticks))
        midi_append_bytes(track, {0x80, note, 0})
    end

    midi_append_bytes(track, write_var_length(0))
    midi_append_bytes(track, {0xFF, 0x2F, 0x00})

    local track_data = string.char(table.unpack(track))
    local header = {
        string.char(0x4D, 0x54, 0x68, 0x64), -- MThd
        string.char(0x00, 0x00, 0x00, 0x06), -- header length
        string.char(0x00, 0x00),             -- format 0
        string.char(0x00, 0x01),             -- one track
        string.char(math.floor(tpq / 256), tpq % 256),
    }

    local track_prefix = string.char(0x4D, 0x54, 0x72, 0x6B) -- MTrk
    local track_length = write_be(#track_data, 4)
    local track_length_str = string.char(table.unpack(track_length))

    return table.concat({
        table.concat(header),
        track_prefix,
        track_length_str,
        track_data,
    })
end

function Recorder:export(on_complete)
    local entry = self.story:get_current_entry()
    if not entry then
        self.status = "No dream yet."
        return
    end

    local base_name = sanitize_filename(entry.line:sub(1, 32))
    local stamp = os.date("%Y%m%d_%H%M%S")
    local text_name = base_name .. "_" .. stamp .. ".txt"
    local midi_name = base_name .. "_" .. stamp .. ".mid"

    local ok, err = love.filesystem.write(text_name, build_snapshot_text(self.synth:get_fingerprint(), summarize_timeline(self.story.timeline)))
    if not ok then
        self.status = "Export failed: " .. tostring(err)
        return
    end

    local midi_data = build_midi_data(self.story.timeline, self.story, self.synth)
    if midi_data then
        local midi_ok, midi_err = love.filesystem.write(midi_name, midi_data)
        if not midi_ok then
            self.status = "Snapshot saved, MIDI failed: " .. tostring(midi_err)
            return
        end
    end

    self.status = string.format("Snapshot saved (%s, %s)", text_name, midi_name)
    if on_complete then
        on_complete()
    end
end

function Recorder:update(dt)
    self.last_blink = self.last_blink + dt
    if self.last_blink > 0.6 then
        self.last_blink = self.last_blink - 0.6
        self.blink_state = not self.blink_state
    end
end

function Recorder:draw_status(exporting)
    local w = love.graphics.getWidth()
    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, exporting and 0.4 or 0.7)
    love.graphics.printf(self.status, 0, 20, w, "center")
    if exporting and self.blink_state then
        love.graphics.printf("...", 0, 48, w, "center")
    end
    love.graphics.pop()
end

return Recorder
}
