local utf8 = require("utf8")
local Story = require("story")
local Synth = require("synth")
local Visual = require("visual")
local Recorder = require("recorder")

local app = {
    story = nil,
    synth = nil,
    visual = nil,
    recorder = nil,
    rewind = 0,
    hovered = nil,
    exporting = false,
    seed_input = {
        active = false,
        text = "",
        status = "Press L to load a seed, C to copy current seed",
        blink = 0,
        message_timer = 0,
    },
}

local function set_status(text)
    app.seed_input.status = text
    app.seed_input.message_timer = 3
end

local function clamp(x, a, b)
    if x < a then
        return a
    elseif x > b then
        return b
    end
    return x
end

local function spawn_story(seed)
    app.story = Story.create(seed, 42)
    app.visual = app.visual or Visual.new(app.story)
    app.synth = app.synth or Synth.new(app.story)
    app.recorder = app.recorder or Recorder.new(app.story, app.synth)

    app.visual:set_story(app.story)
    app.synth:set_story(app.story)
    app.recorder:set_story(app.story)
    app.exporting = false
    set_status(string.format("Active seed: %s", app.story:get_share_code()))
end

function love.load()
    love.window.setTitle("Dream Lattice")
    love.window.setMode(1280, 720, {resizable = true, vsync = 1})
    love.graphics.setBackgroundColor(0.04, 0.05, 0.08)
    spawn_story(nil)
end

function love.update(dt)
    if app.seed_input.message_timer > 0 then
        app.seed_input.message_timer = math.max(0, app.seed_input.message_timer - dt)
        if app.seed_input.message_timer == 0 then
            app.seed_input.status = string.format("Active seed: %s", app.story:get_share_code())
        end
    end

    app.seed_input.blink = app.seed_input.blink + dt

    local w, h = love.graphics.getDimensions()
    local bar_x = w * 0.1
    local bar_w = w * 0.8
    local bar_y = h - 60
    local mx, my = love.mouse.getPosition()
    app.hovered = nil
    local timeline = app.story and app.story.timeline or {}
    if #timeline > 0 and my >= bar_y - 24 and my <= bar_y + 24 then
        local rel = (mx - bar_x) / bar_w
        if rel >= 0 and rel <= 1 then
            local idx = clamp(math.floor(rel * (#timeline - 1) + 1.5), 1, #timeline)
            local entry = app.story:get_entry_at(idx)
            if entry then
                app.hovered = {
                    index = idx,
                    entry = entry,
                    ratio = rel,
                    x = clamp(mx, bar_x, bar_x + bar_w),
                    y = bar_y,
                }
            end
        end
    end

    if not app.seed_input.active then
        if love.keyboard.isDown("space") then
            app.rewind = math.min(1, app.rewind + dt / 6)
        else
            app.rewind = math.max(0, app.rewind - dt / 3)
        end

        if love.mouse.isDown(1) and #timeline > 1 then
            local normalized = clamp((mx - bar_x) / bar_w, 0, 1)
            app.story:set_progress(normalized)
            app.synth:sync_scene()
        end
    end

    app.story:update(dt, app.rewind)
    app.visual:update(dt, app.rewind)
    app.synth:update(dt, app.rewind)
    app.recorder:update(dt)
end

function love.draw()
    app.visual:draw(app.rewind)
    app.recorder:draw_status(app.exporting)
    app.visual:draw_overlay(app.story, app.rewind, app.seed_input, app.hovered)
end

function love.keypressed(key)
    if app.seed_input.active then
        if key == "escape" then
            app.seed_input.active = false
            app.seed_input.text = ""
        elseif key == "return" or key == "kpenter" then
            local parsed = Story.parse_seed(app.seed_input.text)
            if parsed then
                spawn_story(parsed)
                app.seed_input.active = false
                app.seed_input.text = ""
            else
                set_status("Invalid seed. Use hex or numeric.")
            end
        elseif key == "backspace" then
            local byteoffset = utf8.offset(app.seed_input.text, -1)
            if byteoffset then
                app.seed_input.text = app.seed_input.text:sub(1, byteoffset - 1)
            end
        end
        return
    end

    if key == "escape" then
        love.event.quit()
    elseif key == "e" then
        if not app.exporting then
            app.exporting = true
            app.recorder:export(function()
                app.exporting = false
            end)
        end
    elseif key == "r" then
        spawn_story(nil)
    elseif key == "l" then
        app.seed_input.active = true
        app.seed_input.text = ""
        set_status("Type seed then press Enter")
    elseif key == "c" then
        local code = app.story:get_share_code()
        if love.system and love.system.setClipboardText then
            love.system.setClipboardText(code)
            set_status("Copied seed to clipboard")
        else
            set_status("Clipboard unavailable")
        end
    end
end

function love.textinput(t)
    if app.seed_input.active then
        app.seed_input.text = app.seed_input.text .. t
    end
end
