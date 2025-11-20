local Story = {}
Story.__index = Story

local GOLDEN_ANGLE = math.pi * (3 - math.sqrt(5))

local LEXICON = {
    serene = {
        name = "Serene Signal",
        palette = {
            primary = {0.58, 0.78, 0.95},
            accent = {0.25, 0.36, 0.62},
            glow = {0.76, 0.92, 1.0},
        },
        adjectives = {"luminous", "silken", "holographic", "tranquil", "vaporous", "cerulean"},
        nouns = {"lagoon", "horizon", "cascade", "halo", "mist", "breath"},
        verbs = {"whispers", "breathes", "glows", "anchors", "softens", "echoes"},
        artifacts = {"tidal memory", "sleeping aurora", "lapis hum", "seagrass filament"},
        base_freq = 196,
        tempo = 64,
        harmonics = {
            {ratio = 1.0, amp = 0.6},
            {ratio = 2.0, amp = 0.25},
            {ratio = 2.5, amp = 0.15},
        },
        noise = 0.02,
    },
    frenzy = {
        name = "Voltage Bloom",
        palette = {
            primary = {0.95, 0.54, 0.36},
            accent = {0.75, 0.22, 0.18},
            glow = {1.0, 0.82, 0.48},
        },
        adjectives = {"electric", "fractal", "kinetic", "volatile", "fragmented", "blazing"},
        nouns = {"storm", "lattice", "pulse", "flare", "reef", "spark"},
        verbs = {"fractures", "erupts", "shards", "ignites", "splinters", "rattles"},
        artifacts = {"ion bloom", "error blossom", "razor flood", "chromatic glitch"},
        base_freq = 330,
        tempo = 128,
        harmonics = {
            {ratio = 1.0, amp = 0.55},
            {ratio = 1.5, amp = 0.25},
            {ratio = 2.75, amp = 0.2},
        },
        noise = 0.08,
    },
    melancholy = {
        name = "Inkstill",
        palette = {
            primary = {0.52, 0.48, 0.72},
            accent = {0.28, 0.22, 0.48},
            glow = {0.78, 0.72, 0.94},
        },
        adjectives = {"dusky", "longing", "echoing", "paper-thin", "drizzling", "somnolent"},
        nouns = {"archive", "corridor", "river", "ink", "lantern", "pulse"},
        verbs = {"remembers", "drifts", "folds", "braids", "suspends", "stretches"},
        artifacts = {"amber reel", "tired lighthouse", "cinder echo", "vellum ripple"},
        base_freq = 174,
        tempo = 72,
        harmonics = {
            {ratio = 1.0, amp = 0.5},
            {ratio = 2.01, amp = 0.3},
            {ratio = 3.0, amp = 0.12},
        },
        noise = 0.04,
    },
    mischief = {
        name = "Prism Prank",
        palette = {
            primary = {0.42, 0.86, 0.58},
            accent = {0.16, 0.48, 0.36},
            glow = {0.74, 0.96, 0.82},
        },
        adjectives = {"wayward", "glittering", "curious", "tilted", "shivering", "fizzing"},
        nouns = {"loop", "mirror", "maze", "spark", "goblin", "rift"},
        verbs = {"skips", "tickles", "rewrites", "loops", "tilts", "distorts"},
        artifacts = {"prankster bloom", "glitch kite", "candy prism", "wobble glyph"},
        base_freq = 247,
        tempo = 112,
        harmonics = {
            {ratio = 1.0, amp = 0.55},
            {ratio = 2.05, amp = 0.25},
            {ratio = 2.98, amp = 0.18},
        },
        noise = 0.05,
    },
    astral = {
        name = "Deep Archiver",
        palette = {
            primary = {0.86, 0.76, 0.98},
            accent = {0.48, 0.32, 0.74},
            glow = {0.94, 0.88, 1.0},
        },
        adjectives = {"ancient", "orbiting", "hushed", "stellar", "cryptic", "ceramic"},
        nouns = {"vault", "atlas", "signal", "glyph", "nebula", "spire"},
        verbs = {"etches", "catalogs", "aligns", "recites", "anchors", "orbits"},
        artifacts = {"cosmic archive", "lattice hymn", "zero horizon", "silica star"},
        base_freq = 262,
        tempo = 96,
        harmonics = {
            {ratio = 1.0, amp = 0.58},
            {ratio = 1.99, amp = 0.22},
            {ratio = 3.02, amp = 0.2},
        },
        noise = 0.03,
    },
}

local MOOD_KEYS = {}
for key in pairs(LEXICON) do
    table.insert(MOOD_KEYS, key)
end

local TEMPLATES = {
    "A %s %s %s the %s.",
    "You follow the %s %s as it %s the %s.",
    "Within a %s %s, something %s the %s.",
    "The %s %s quietly %s another %s.",
    "Under a %s %s you %s the %s.",
}

local CONNECTORS = {
    "drift impulse",
    "lighthouse ping",
    "unwritten corridor",
    "mirage request",
    "sleep tide",
    "quantum nudge",
    "glyph rumor",
}

local GLYPHS = {"*", "+", "~", "%", "?", "=", "#", ":", "@"}

local function clamp(x, a, b)
    if x < a then
        return a
    elseif x > b then
        return b
    end
    return x
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function Story.lexicon()
    return LEXICON
end

local function default_seed()
    local tick = love.timer.getTime() * 100000
    return math.floor(tick % 0xFFFFFFFF)
end

local function normalize_seed(seed)
    if not seed then
        return default_seed()
    end
    if type(seed) == "string" then
        local parsed = Story.parse_seed(seed)
        if parsed then
            return parsed
        end
    end
    seed = math.floor(seed)
    if seed < 0 then
        seed = math.abs(seed)
    end
    return seed % 0xFFFFFFFF
end

function Story.seed_to_share(seed)
    seed = normalize_seed(seed)
    return string.format("%08X", seed)
end

function Story.parse_seed(token)
    if not token then
        return nil
    end
    token = token:gsub("[^0-9a-fA-F]", "")
    if token == "" then
        return nil
    end
    local value = tonumber(token)
    if value then
        return normalize_seed(value)
    end
    value = tonumber(token, 16)
    if value then
        return normalize_seed(value)
    end
    return nil
end

function Story.create(seed, node_count)
    local self = setmetatable({}, Story)
    seed = normalize_seed(seed)
    self.seed = seed
    self.share_code = Story.seed_to_share(seed)
    self.rng = love.math.newRandomGenerator(seed)
    self.node_count = node_count or 36
    self.nodes = {}
    self.edges = {}
    self.timeline = {}
    self.pointer = 0
    self.progress = 1
    self.elapsed = 0
    self.target_wait = 3 + self.rng:random() * 2

    self:_generate_nodes()
    self:_link_nodes()

    local start_id = self:_find_calm_origin()
    self:add_entry(start_id, "origin pulse")
    return self
end

function Story:_random_choice(list)
    return list[self.rng:random(1, #list)]
end

function Story:_generate_nodes()
    for i = 1, self.node_count do
        local mood = self:_random_choice(MOOD_KEYS)
        local lex = LEXICON[mood]
        local radius = math.sqrt(i / self.node_count) * 0.45
        local angle = i * GOLDEN_ANGLE
        local x = 0.5 + math.cos(angle) * radius
        local y = 0.5 + math.sin(angle) * radius
        x = clamp(x, 0.08, 0.92)
        y = clamp(y, 0.08, 0.92)

        local node = {
            id = i,
            mood = mood,
            palette = lex.palette,
            position = {x = x, y = y},
            glyph = self:_random_choice(GLYPHS),
            pulse = 0,
            slide = self.rng:random() * math.pi * 2,
            links = {},
            fragment = string.format("%s %s", self:_random_choice(lex.adjectives), self:_random_choice(lex.nouns)),
            artifact = self:_random_choice(lex.artifacts),
            age = self.rng:random(),
        }
        self.nodes[i] = node
    end
end

function Story:_link_nodes()
    for _, node in ipairs(self.nodes) do
        local count = self.rng:random(2, 4)
        local added = {}
        while #node.links < count do
            local candidate = self.rng:random(1, self.node_count)
            if candidate ~= node.id and not added[candidate] then
                added[candidate] = true
                table.insert(node.links, {
                    id = candidate,
                    weight = self.rng:random() * 0.6 + 0.4,
                    synapse = self:_random_choice(CONNECTORS),
                })
                table.insert(self.edges, {
                    from = node.id,
                    to = candidate,
                    sway = self.rng:random() * math.pi * 2,
                    jitter = self.rng:random() * 0.8 + 0.2,
                })
            end
        end
    end
end

function Story:_find_calm_origin()
    local best_id = 1
    local best_radius = math.huge
    for _, node in ipairs(self.nodes) do
        local dx = node.position.x - 0.5
        local dy = node.position.y - 0.5
        local dist = dx * dx + dy * dy
        if dist < best_radius then
            best_radius = dist
            best_id = node.id
        end
    end
    return best_id
end

function Story:add_entry(node_id, link_label)
    local node = self.nodes[node_id]
    if not node then
        return
    end

    local lex = LEXICON[node.mood]
    local template = self:_random_choice(TEMPLATES)
    local line = string.format(
        template,
        self:_random_choice(lex.adjectives),
        self:_random_choice(lex.nouns),
        self:_random_choice(lex.verbs),
        node.artifact
    )

    local now = love.timer.getTime()
    local prev = self.timeline[#self.timeline]
    if prev then
        prev.duration = now - prev.timestamp
    end

    local entry = {
        node_id = node_id,
        line = line,
        synapse = link_label or "",
        timestamp = now,
        duration = 3.0,
        mood = node.mood,
    }

    table.insert(self.timeline, entry)
    self.pointer = #self.timeline
    self.progress = 1
    node.pulse = 1
end

function Story:get_seed()
    return self.seed
end

function Story:get_share_code()
    return self.share_code
end

function Story:get_nodes()
    return self.nodes
end

function Story:get_edges()
    return self.edges
end

function Story:get_current_entry()
    return self.timeline[self.pointer]
end

function Story:get_entry_at(index)
    return self.timeline[index]
end

function Story:get_current_node()
    local entry = self:get_current_entry()
    if not entry then
        return self.nodes[1]
    end
    return self.nodes[entry.node_id]
end

function Story:get_mood_profile(id)
    return LEXICON[id or self:get_current_node().mood]
end

function Story:set_progress(t)
    if #self.timeline == 0 then
        return
    end
    self.progress = clamp(t, 0, 1)
    local target_index = clamp(math.floor(self.progress * (#self.timeline - 1) + 1.5), 1, #self.timeline)
    if target_index ~= self.pointer then
        self.pointer = target_index
    end
end

function Story:update(dt, rewind)
    for _, node in ipairs(self.nodes) do
        node.pulse = lerp(node.pulse, 0, dt * 1.4)
        node.age = node.age + dt * 0.05
    end

    if rewind > 0.01 then
        return
    end

    self.elapsed = self.elapsed + dt
    if self.elapsed < self.target_wait then
        return
    end

    self.elapsed = 0
    self.target_wait = 2.5 + self.rng:random() * 2.5

    local current = self:get_current_node()
    local links = current.links
    if #links == 0 then
        return
    end

    local total = 0
    for _, link in ipairs(links) do
        total = total + link.weight
    end
    local pick = self.rng:random() * total
    local chosen_link = links[1]
    local accum = 0
    for _, link in ipairs(links) do
        accum = accum + link.weight
        if pick <= accum then
            chosen_link = link
            break
        end
    end

    self:add_entry(chosen_link.id, chosen_link.synapse)
end

function Story:rewind_amount()
    return 1 - self.progress
end

return Story
