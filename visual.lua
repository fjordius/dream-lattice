local Story = require("story")

local Visual = {}
Visual.__index = Visual

local PARTICLE_COUNT = 220

local SHADER_CODE = [[
extern float time;
extern float intensity;
extern float glitch;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
{
    vec2 pixel = 1.0 / resolution;
    vec3 base = Texel(tex, uv).rgb;
    vec3 bloom = base;
    bloom += Texel(tex, uv + pixel * vec2(1.5, 0.0)).rgb;
    bloom += Texel(tex, uv + pixel * vec2(-1.5, 0.0)).rgb;
    bloom += Texel(tex, uv + pixel * vec2(0.0, 1.5)).rgb;
    bloom += Texel(tex, uv + pixel * vec2(0.0, -1.5)).rgb;
    bloom = bloom * 0.2;

    float glitchWave = sin(uv.y * 120.0 + time * 5.0) * glitch;
    vec3 glitchColor = Texel(tex, uv + vec2(glitchWave * 0.02, 0.0)).rgb;
    float scan = sin(uv.y * 800.0 + time * 10.0) * 0.02;

    vec3 finalColor = mix(base, glitchColor, glitch * 0.5);
    finalColor += bloom * intensity;
    finalColor += scan;
    return vec4(clamp(finalColor, 0.0, 1.0), 1.0) * color;
}
]]

local function node_position(node)
    local w, h = love.graphics.getDimensions()
    return node.position.x * w, node.position.y * h
end

local function draw_background(profile, t)
    local w, h = love.graphics.getDimensions()
    local palette = profile.palette
    local gradient = love.graphics.newMesh({
        {0, 0, 0, 0, palette.primary[1], palette.primary[2], palette.primary[3], 1},
        {w, 0, 1, 0, palette.accent[1], palette.accent[2], palette.accent[3], 1},
        {w, h, 1, 1, palette.primary[1], palette.primary[2], palette.primary[3], 1},
        {0, h, 0, 1, palette.accent[1], palette.accent[2], palette.accent[3], 1},
    }, "fan")
    love.graphics.draw(gradient, 0, 0)

    local rings = 11
    for i = rings, 1, -1 do
        local alpha = 0.02 + i / rings * 0.09
        love.graphics.setColor(palette.glow[1], palette.glow[2], palette.glow[3], alpha)
        local radius = (math.sin(t * 0.3 + i * 0.4) * 0.035 + 0.05 * i) * math.min(w, h)
        love.graphics.circle("fill", w * 0.5, h * 0.5, radius)
    end
end

local function glyph_color(node, accent)
    local c = node.palette
    if accent then
        return c.accent[1], c.accent[2], c.accent[3]
    end
    return c.primary[1], c.primary[2], c.primary[3]
end

local function draw_edges(story, t)
    local nodes = story:get_nodes()
    love.graphics.setLineWidth(2)
    for _, edge in ipairs(story:get_edges()) do
        local from = nodes[edge.from]
        local to = nodes[edge.to]
        if from and to then
            local x1, y1 = node_position(from)
            local x2, y2 = node_position(to)
            local sway = math.sin(t + edge.sway) * 18 * edge.jitter
            local midx = (x1 + x2) / 2 + sway
            local midy = (y1 + y2) / 2 - sway
            love.graphics.setColor(1, 1, 1, 0.1)
            love.graphics.line(x1, y1, midx, midy)
            love.graphics.setColor(1, 1, 1, 0.06)
            love.graphics.line(midx, midy, x2, y2)
        end
    end
end

local function draw_nodes(story, current_id, rewind, time)
    for _, node in ipairs(story:get_nodes()) do
        local x, y = node_position(node)
        local scale = 14 + node.pulse * 36
        local alpha = 0.35 + node.pulse * 0.65
        love.graphics.setColor(node.palette.glow[1], node.palette.glow[2], node.palette.glow[3], alpha * 0.8)
        love.graphics.circle("fill", x, y, scale * 1.2)
        love.graphics.setColor(node.palette.accent[1], node.palette.accent[2], node.palette.accent[3], alpha)
        love.graphics.circle("fill", x, y, scale)
        local glyph_scale = 1 + math.sin(time * 2 + node.slide) * 0.12 + node.pulse * 0.4
        local font_size = 24 * glyph_scale
        love.graphics.setColor(glyph_color(node))
        love.graphics.printf(node.glyph, x - font_size / 2, y - font_size / 2, font_size, "center")

        if node.id == current_id then
            local halo = 0.7 + math.sin(time * 4) * 0.2 + rewind * 0.5
            love.graphics.setColor(node.palette.glow[1], node.palette.glow[2], node.palette.glow[3], 0.4 + rewind * 0.3)
            love.graphics.circle("line", x, y, scale * (1.6 + halo))
        end
    end
end

local function draw_text_panel(story, profile, rewind)
    local margin = 28
    local w, h = love.graphics.getDimensions()
    local width = math.min(480, w * 0.45)
    local height = h - margin * 2
    local x = w - width - margin
    local y = margin
    love.graphics.setColor(0, 0, 0, 0.35 + rewind * 0.25)
    love.graphics.rectangle("fill", x, y, width, height, 18, 18)
    love.graphics.setColor(profile.palette.primary[1], profile.palette.primary[2], profile.palette.primary[3], 0.9)
    love.graphics.rectangle("line", x, y, width, height, 18, 18)

    local entry = story:get_current_entry()
    if not entry then
        return
    end

    love.graphics.setColor(profile.palette.glow[1], profile.palette.glow[2], profile.palette.glow[3], 1)
    love.graphics.printf(profile.name, x + 20, y + 16, width - 40, "left")
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.printf(entry.line, x + 20, y + 70, width - 40)
    love.graphics.setColor(profile.palette.accent[1], profile.palette.accent[2], profile.palette.accent[3], 0.7)
    love.graphics.printf(string.format("link: %s", entry.synapse or ""), x + 20, y + height - 110, width - 40)
    love.graphics.printf(string.format("mood: %s", entry.mood), x + 20, y + height - 80, width - 40)
    love.graphics.printf(string.format("seed: %s", story:get_share_code()), x + 20, y + height - 50, width - 40)
end

function Visual.new(story)
    local self = setmetatable({}, Visual)
    self.shader = love.graphics.newShader(SHADER_CODE)
    self.scene_canvas = nil
    self.time = 0
    self.wave = 0
    self.halo_phase = 0
    self.rng = love.math.newRandomGenerator()
    self.particles = {}
    self.node_cache = {}
    self:set_story(story)
    return self
end

function Visual:ensure_canvas()
    local w, h = love.graphics.getDimensions()
    if not self.scene_canvas or self.scene_canvas:getWidth() ~= w or self.scene_canvas:getHeight() ~= h then
        self.scene_canvas = love.graphics.newCanvas(w, h)
        self.scene_canvas:setFilter("linear", "linear")
        if self.shader then
            self.shader:send("resolution", {w, h})
        end
    end
end

function Visual:set_story(story)
    self.story = story
    self.node_cache = {}
    self:ensure_canvas()
    self:_spawn_particles()
end

function Visual:_spawn_particles()
    self.particles = {}
    if not self.story then
        return
    end
    local nodes = self.story:get_nodes()
    if #nodes == 0 then
        return
    end
    local lex = Story.lexicon()
    self.rng:setSeed((self.story:get_seed() or 0) + 0xBEE5)
    for i = 1, PARTICLE_COUNT do
        local node = nodes[((i - 1) % #nodes) + 1]
        local palette = lex[node.mood].palette
        table.insert(self.particles, {
            x = self.rng:random(),
            y = self.rng:random(),
            vx = (self.rng:random() - 0.5) * 0.12,
            vy = (self.rng:random() - 0.5) * 0.12,
            base_size = self.rng:random() * 18 + 12,
            color = {palette.glow[1], palette.glow[2], palette.glow[3]},
            accent = {palette.accent[1], palette.accent[2], palette.accent[3]},
            drift = self.rng:random() * math.pi * 2,
            mood = node.mood,
        })
    end
end

function Visual:_update_particles(dt, rewind)
    if not self.particles then
        return
    end
    local lex = Story.lexicon()
    for _, particle in ipairs(self.particles) do
        particle.drift = particle.drift + dt * (0.6 + rewind * 3.6)
        particle.vx = particle.vx + math.sin(self.time * 0.4 + particle.drift) * dt * 0.02
        particle.vy = particle.vy + math.cos(self.time * 0.5 + particle.drift) * dt * 0.02
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        if particle.x < 0 then
            particle.x = particle.x + 1
        elseif particle.x > 1 then
            particle.x = particle.x - 1
        end
        if particle.y < 0 then
            particle.y = particle.y + 1
        elseif particle.y > 1 then
            particle.y = particle.y - 1
        end
        particle.size = particle.base_size * (0.9 + math.sin(self.time * 2 + particle.drift) * 0.25 + rewind * 0.4)
        local palette = lex[particle.mood].palette
        particle.color[1], particle.color[2], particle.color[3] = palette.glow[1], palette.glow[2], palette.glow[3]
        particle.accent[1], particle.accent[2], particle.accent[3] = palette.accent[1], palette.accent[2], palette.accent[3]
    end
end

function Visual:_draw_particles(rewind)
    if not self.particles then
        return
    end
    local w, h = love.graphics.getDimensions()
    for _, particle in ipairs(self.particles) do
        local alpha = 0.1 + rewind * 0.2 + math.abs(math.sin(self.time * 1.5 + particle.drift)) * 0.15
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x * w, particle.y * h, particle.size)
        love.graphics.setColor(particle.accent[1], particle.accent[2], particle.accent[3], alpha * 0.6)
        love.graphics.circle("line", particle.x * w, particle.y * h, particle.size * 1.4)
    end
end

function Visual:update(dt, rewind)
    self:ensure_canvas()
    self.time = self.time + dt
    self.wave = self.wave + dt * (4 + rewind * 5)
    self.halo_phase = self.halo_phase + dt * (2.2 + rewind * 3)
    self:_update_particles(dt, rewind)
    if self.shader then
        local intensity = 0.25 + rewind * 0.6
        local glitch = 0.08 + rewind * 0.5
        self.shader:send("time", self.time)
        self.shader:send("intensity", intensity)
        self.shader:send("glitch", glitch)
    end
end

function Visual:draw(rewind)
    self:ensure_canvas()
    local entry = self.story:get_current_entry()
    local profile = self.story:get_mood_profile(entry and entry.mood or nil)

    love.graphics.push("all")
    love.graphics.setCanvas(self.scene_canvas)
    love.graphics.clear(0, 0, 0, 0)
    draw_background(profile, self.time)
    self:_draw_particles(rewind)
    draw_edges(self.story, self.wave)
    draw_nodes(self.story, entry and entry.node_id or 1, rewind, self.time)
    draw_text_panel(self.story, profile, rewind)
    love.graphics.setCanvas()
    love.graphics.pop()

    love.graphics.push("all")
    if self.shader then
        love.graphics.setShader(self.shader)
    end
    love.graphics.draw(self.scene_canvas, 0, 0)
    love.graphics.setShader()
    love.graphics.pop()
end

function Visual:draw_overlay(story, rewind, seed_input, hovered)
    love.graphics.push("all")
    local w, h = love.graphics.getDimensions()
    local bar_height = 8
    local y = h - 60
    local progress = story.progress or 1
    love.graphics.setColor(0, 0, 0, 0.4 + rewind * 0.3)
    love.graphics.rectangle("fill", w * 0.1, y, w * 0.8, bar_height, 4, 4)
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.rectangle("fill", w * 0.1, y, w * 0.8 * progress, bar_height, 4, 4)

    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.printf(seed_input.status or "", 0, 24, w, "center")
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf(string.format("Seed: %s | Press C to copy, L to load", story:get_share_code()), 0, 52, w, "center")

    if hovered then
        love.graphics.setColor(1, 1, 1, 0.85)
        love.graphics.circle("fill", hovered.x, y + bar_height / 2, 6)
        local box_w = 360
        local box_h = 90
        local box_x = math.min(math.max(hovered.x - box_w / 2, w * 0.1), w * 0.9 - box_w)
        local box_y = y - box_h - 20
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, 10, 10)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.printf(string.format("%02d • %s", hovered.index, hovered.entry.mood), box_x + 16, box_y + 12, box_w - 32, "left")
        love.graphics.setColor(0.85, 0.85, 1.0, 0.9)
        love.graphics.printf(hovered.entry.line, box_x + 16, box_y + 36, box_w - 32, "left")
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.printf(string.format("link: %s", hovered.entry.synapse or ""), box_x + 16, box_y + 62, box_w - 32, "left")
    end

    if seed_input.active then
        local box_w = math.min(420, w * 0.8)
        local box_x = (w - box_w) / 2
        local box_y = h - 150
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", box_x, box_y, box_w, 54, 12, 12)
        love.graphics.setColor(1, 1, 1, 0.9)
        local caret = (seed_input.blink % 1.2) > 0.6 and "▌" or " "
        love.graphics.printf("Seed: " .. seed_input.text .. caret, box_x + 18, box_y + 16, box_w - 36, "left")
    else
        love.graphics.setColor(1, 1, 1, 0.55)
        love.graphics.printf("Hold SPACE to rewind dream | Drag mouse to scrub | R to regenerate | E to export", 0, h - 40, w, "center")
    end
    love.graphics.pop()
end

return Visual
