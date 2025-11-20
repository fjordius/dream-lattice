# Dream Lattice

> A generative narrative instrument built with LÖVE + Lua. Wander a shifting graph of micro-scenes, bend time with a rewind halo, and archive alternate histories as audio-tinged dream snapshots.

## Concept

Dream Lattice assembles a living hypergraph of vignettes—each node carries mood-specific language, color, and harmonic fingerprints. As the lattice expands, colored synapse lines drift between stories while a procedural synth follows the emotional tone. Drag the timeline to fork the narrative, hold space to rewind, or regenerate the whole cosmos with a keypress.

## Features

- **Narrative hypergraph**: 40+ procedurally placed nodes linked by weighted “synapses,” rendered as animated bezier ribbons.
- **Mood-aware lexicon**: Each node draws from themed adjective/noun/verb pools and invoked artifacts, yielding surreal micro-fiction lines.
- **Live synth score**: Parameterized additive synthesizer adapts base frequency, harmonics, and noise to the active mood.
- **Temporal controls**: Hold space to rewind, drag the timeline scrubber to revisit or branch the dream sequence.
- **Snapshot exporter**: Press `E` to dump your journey into a timestamped `.txt` file with story beats and harmonic fingerprint.
- **Regeneration**: Press `R` to spin up an entirely new lattice seeded from golden-angle sampling + RNG.

## Getting Started

### Requirements
- [LÖVE 11.5+](https://love2d.org/) installed.
- Windows, macOS, or Linux.

### Run

```bash
love dream-lattice
```

The project directory contains:

- `main.lua` — app bootstrap and input handling.
- `story.lua` — narrative generation, node graph logic.
- `visual.lua` — rendering of nodes, edges, overlays, and UI.
- `synth.lua` — additive synth engine backed by queueable audio buffers.
- `recorder.lua` — snapshot exporter & HUD status text.

## Controls

| Action | Input |
| --- | --- |
| Rewind dream halo | Hold `Space` |
| Scrub timeline | Left-click + drag |
| Export snapshot | `E` |
| Regenerate lattice | `R` |
| Quit | `Esc` |

## Exported Snapshot

Snapshots drop into the LÖVE save directory (platform-specific) as human-readable text files. Each file records:

- The current mood fingerprint (`Serene Signal @ 196 Hz`, etc.).
- Ordered list of traversed nodes with mood, synapse label, and generated line.



