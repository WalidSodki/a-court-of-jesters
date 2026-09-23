# CLAUDE.md

This file gives Claude Code (and other contributors) the context needed to work effectively in this repository.

> **Status: early preproduction.** Mechanics are not set in stone. Expect this document — and the game's scope — to change. When something here conflicts with what's actually in the codebase, trust the code and flag the mismatch.

## Project Overview

**A Court of Jesters** is a **single-player, top-down pixel-art adventure game** with a 3/4 perspective (think _A Link to the Past_ or _The Witch's House_). It's **story-driven with spooky/horror elements**, and **player choices can and will affect other parts of the game**.

You play as a **jester in a medieval setting**. Core gameplay is simple: move in all directions, hold a button to move faster, talk to NPCs, and manage an **inventory of items that can be combined and/or used on things in the world** to solve puzzles and advance the story.

There is **no direct combat**. Tension comes from atmosphere, story, and occasional set-piece sequences (see below).

## Tech Stack

- **Engine:** Godot 4.7.x
- **Language:** GDScript only (no C#, no GDExtension unless explicitly discussed first)
- **Target platforms:** PC (Windows/Mac/Linux) + Steam Deck
- **Input:** Controller-first, fully playable on keyboard

## Core Design Pillars

1. **Story-driven, choices matter** — the game reacts to what the player does. Meaningful choices should persist and influence later content. This needs to be tracked in a clean, queryable game-state system rather than ad-hoc booleans scattered across scenes.
2. **Simple core, layered mechanics** — the always-on loop is deliberately small: **movement + interaction + inventory (use/combine items to solve puzzles)**. Everything else is an optional layer.
3. **Modular set-piece mechanics** — richer mechanics are added _on top_ for specific sequences, not baked into the core. The architecture must make these easy to drop in and remove. Currently envisioned (none are core; none need to be fully fleshed out early):
   - **Timing / rhythm minigame** (DDR-style) — entertaining the royal family.
   - **Placement / rotation puzzles** — move and rotate items to match a target arrangement.
   - **Chase sequences** — flee from a threat; no combat.
   - **Stealth sequences** — avoid being caught by guards.
4. **Atmosphere first** — spooky/horror mood is a feature. Lighting, audio, pacing, and readability of threats matter as much as mechanics.

## Vertical Slice — The Golden Path

The demo's job is to make **one path** feel great, not to show every feature. Depth beats breadth: a short, polished, replayable sequence sells the game far better than many half-built systems. Art and story are placeholder for now — the slice must be fun on **feel and structure** before final assets arrive.

The golden path (built to later chain all three set-pieces — **perform → sneak → flee**):

> Explore the hall → talk to the steward (dialogue with a **choice that sets a flag**) → find and **combine** props in the inventory → **use** the result on the stage → **court performance (rhythm minigame)** → outcome **branches** on the earlier choice + score → short reaction **cutscene**.

- Build the slice **first set-piece first** (court performance), then layer stealth and chase onto the *same* path.
- Every system in the slice should demonstrate a reusable pattern (interaction, choice/flag, combine, use-on-object, control-mode handoff), so the rest of the game is "more of this," not "new plumbing each time."
- If a feature doesn't serve the one path, it waits.

## Architecture Philosophy

- **Build for layering, not for everything.** The whole point of this project is a small core with optional mechanics bolted on for specific sequences. Design the core (player, interaction, inventory, game state) to be clean and stable; build each set-piece mechanic as a **self-contained module/scene** that a level can opt into. Don't wire minigame logic into the player controller.
- **Composition over inheritance, but not dogmatically.** Prefer composing behavior via components/nodes (e.g. `Interactable.gd`, `Movement.gd`, `Inventory.gd` attached as child nodes) over deep inheritance chains. Use inheritance when there's a clear "is-a" relationship that meaningfully reduces duplication (e.g. a base `NPC.gd` that specific NPCs extend).
- **No over-engineering.** Don't build abstractions, interfaces, or systems for hypothetical future needs. Solve the problem in front of you in the simplest reasonable way. Duplicate a little code before introducing a complex abstraction. "It's built for layering" is not a license to pre-build layers nobody has asked for yet.
- **Readability first.** Code should be easy to read top-to-bottom and understand without jumping through many files. Favor clear naming and straightforward logic over cleverness.
- **Reusable, not generic.** Reusability should come from clean, well-scoped components (e.g. a generic `Interactable` that anything in the world can be) — not from building a configurable "framework" inside the game.

### Suggested patterns

- **Autoloads/Singletons**: only for truly global concerns (e.g. `GameManager`, `GameState`, `DialogueManager`, `InputManager`, `AudioManager`). Keep them lean.
- **Game state / choice tracking**: keep story flags and choice consequences in one clearly named place (e.g. a `GameState` autoload backed by a dictionary, or Resources) so branching logic is easy to find, query, and save/load. Don't scatter story booleans across level scripts.
- **Signals** for decoupled communication between nodes (e.g. an `Interactable` emits `interacted`, a puzzle emits `solved`, rather than callers reaching into each other). Set-piece mechanics should report results via signals so the surrounding scene stays decoupled.
- **Resource-based data** (`.tres` custom Resources) for content and tuning: item definitions, item-combination recipes, dialogue, puzzle layouts, minigame charts. Keeps designer-facing content separate from logic and easy to add to.
- **Scene composition**: build entities as a root node + child component nodes/scripts rather than one big monolithic script per entity.

## Core Systems (early guidance)

These are the systems most likely to be touched often. Keep them clean; they're the foundation everything layers onto.

- **Inventory & items** — items are data (Resources), not hardcoded. Support **combining items** and **using an item on a world object**. Model interactions as data-driven where reasonable (item + target → result) so new puzzles don't require new bespoke code each time.
- **Interaction** — a single, reusable `Interactable` concept for NPCs, doors, pickups, puzzle objects, etc. The player interacts the same way with everything; what happens is defined per-object.
- **Dialogue & NPCs** — dialogue is data-driven: conversations are `ConversationData` graphs (`dialogue/conversations/*.tres`) of `DialogueNode`s with per-node/per-choice `DialogueCondition`s and `DialogueEffect`s and `goto` branching, so branching/reactive writing is authored in the inspector, not GDScript. NPCs are interactable and drive one via `Dialogue.start_conversation()`; a choice can set a flag (or grant an item/clue) that matters later. The older inline `Dialogue.start([...])` array path still works for quick one-off lines/prompts.
- **Game state & saves** — because choices persist, plan for the state system to be serializable from early on, even if the save UI comes later.

## Set-Piece Mechanics (keep them modular)

When implementing any of the optional mechanics (rhythm minigame, placement/rotation puzzle, chase, stealth):

- Build it as its **own scene/module** with a clear entry (start) and exit (success/failure via signal).
- It should **hand control back** to the normal exploration loop cleanly when done.
- Drive its content from **data/Resources** where practical (e.g. a rhythm chart, a puzzle's target layout) so variants don't mean new code.
- Don't leak its logic into core scripts. If the player controller starts growing `if in_minigame:` branches, that's a smell — isolate it.

## Game Feel & Juice

A demo lives or dies on **feel before features**. Cheap, systemic juice makes placeholder art feel like a real game. Bake these in early rather than bolting them on later:

- **Responsive movement** — acceleration/deceleration (not instant on/off), hold-to-run, and a subtle walk bob/squash so motion reads even without walk-cycle art.
- **Camera** — smoothed follow with room limits; a reusable `shake(amount, time)` on the camera for scares and impacts.
- **Feedback on every interaction** — a floating, gently bobbing interaction prompt; a squash-and-stretch "pop" on pickups; a flourish on puzzle success; a flash/shake on invalid actions. Nothing the player does should feel silent.
- **Transitions** — fade in/out on room enter/exit and as cutscene bookends; never hard-cut.
- **Hit-stop / micro-freezes** on big beats (a scare trigger, a perfect rhythm hit) — a few frames of pause reads as impact.
- **Audio on every action** — even placeholder blips; silence feels broken (see Audio & Atmosphere).

Keep juice **systemic and reusable** (tween helpers, one camera-shake, one transition system) rather than hand-animated per object.

## Placeholder Art & Assets

Final art/story arrive later; build so they **swap in without code changes**.

- Placeholder set: **Kenney 16×16** (`art/royalty free placeholder/`). Use `tilemap_packed.png` (no inter-tile spacing) for tiles; the per-cell crops live in `Tiles/`. Stand-ins: colorful sprite = jester (player), knight = steward/guards, skeleton = future threat, torches = mood.
- Keep art **data-referenced**: items carry an icon (explicit `Texture2D` when it exists, else a sheet index via `Art.gd`); rooms reference tiles by index constants gathered at the top of the script. Swapping art = changing data/one constant, never gameplay logic.
- Project is configured for crisp pixels: **Nearest** texture filter, **integer** stretch scale, 320×200 base viewport (×4 = 1280×800 on Steam Deck).

## Audio & Atmosphere

- Route **all** SFX/music through the lean `AudioManager` autoload (one place for volume/ducking later). Gameplay calls `play_sfx(&"pickup")` etc. today; those are safe no-ops until real streams are registered, so wiring the calls now costs nothing and pays off instantly when audio lands.
- Mood can be carried by **lighting + sound** long before final art — lean on torches/`CanvasModulate`/`PointLight2D` and audio cues to establish the spooky tone in placeholder scenes.

## Debug & Dev Affordances

Fast iteration is a first-class requirement for a demo, not a nicety.

- Ship a **dev-only overlay** (guarded by `OS.is_debug_build()`) that shows live control mode, story flags, player position, and FPS, with hotkeys to **grant items, set flags, trigger cutscenes, toggle noclip, and reload the room**.
- Anything that takes more than a few seconds to reach by playing normally should have a debug shortcut. If you add a new gated sequence, add a way to jump straight to it.

## Cutscenes (in-engine, scripted)

Cutscenes are **real-time, in-engine scripted sequences** — the game temporarily takes control, moves actors around, plays animations/dialogue, and hands control back. We are **not** planning pre-rendered video/cinematics, so a cutscene "actor" is just a normal in-game entity (the player, an NPC, a prop) being driven by a script instead of by input.

- **Control ownership through one global mode, not ad-hoc flags.** Player input should be gated by a single source of truth (e.g. a `GameState`/`GameManager` control-mode enum like `EXPLORING` / `CUTSCENE` / `DIALOGUE` / `MENU`), and the player controller reads that mode. A cutscene enters `CUTSCENE` mode on start and restores the previous mode on end — it should **never** reach into the player script to disable input directly.
- **Guarantee control is restored.** Re-enabling input must be robust to early exit, skipping, and errors (structure it so cleanup always runs). A cutscene that can leave the player soft-locked with no control is the failure mode to design against.
- **Always skippable, and skipping is safe.** Every cutscene should be skippable. Skipping must **apply the sequence's end-state immediately** (final actor positions, flags set, doors opened) rather than just stopping playback — the world must be left in exactly the state it would be in had the scene played out.
- **Use Godot's built-in sequencing tools; don't reinvent a timeline.** Prefer `AnimationPlayer` (animate any property + call-method/signal tracks) and `Tween` for code-driven motion, sequenced with `await` coroutines. Reach for these before building a custom scheduler.
- **Command existing actors; don't duplicate them.** A cutscene should drive the real NPC/player/prop nodes already in the scene (move-to, play-animation, face-direction, say-line) rather than spawning bespoke cutscene-only clones.
- **Decoupled and data-friendly.** A cutscene runs as its own module and reports completion via **signal** (`finished`), like other set-piece mechanics. Keep the *what happens* separate from *what happens next* — the cutscene shouldn't hardcode game flow. Author sequences as data/Resources where it keeps them readable and lets non-programmers tweak beats.
- **Integrate with state and dialogue.** Cutscenes can read game state to play conditionally and write flags on completion (route through the game-state system, not local booleans), and should reuse the existing dialogue system for spoken lines rather than a parallel one.
- **Mind pausing.** Actors must keep moving during a cutscene, so don't lean on `get_tree().paused` for cutscene control — gate via the control-mode instead, and reserve the paused tree for the actual pause menu.

## Steam Deck & Input Considerations

- **Controller-first**: design and test with controller as the primary input; keyboard is a fully supported secondary scheme, not an afterthought. Controls are simple (8-directional movement, hold-to-run, interact, inventory) — keep them reachable on a gamepad.
- Use **controller button glyphs** by default in prompts/UI hints; don't assume keyboard-only prompts.
- **Disabling input** (during cutscenes, dialogue, minigames, menus) goes through the single global control-mode, not by poking flags on the player script — see [Cutscenes](#cutscenes-in-engine-scripted).
- Test **UI scaling/readability at Steam Deck's resolution (1280x800)** — avoid tiny text; horror/atmosphere shouldn't mean unreadable UI.
- Be mindful of performance (Deck's APU is weaker than a typical desktop GPU) — profile early, avoid unnecessary per-frame allocations, keep 2D draw calls reasonable. Atmospheric effects (lighting, shaders, particles) are the most likely perf risk here — watch them.
- Avoid relying on mouse-only interactions (hover states, click-drag) for core gameplay, since Deck shouldn't require the trackpad. If a placement/rotation puzzle uses drag, ensure it's fully controller-operable too.

## Project Layout (Milestone 1 — what exists now)

The foundation is built. Match these established conventions before inventing new ones.

- **Run it:** open the project in Godot 4.7 and press Play, or headless-check with
  `"<godot>" --headless --path . --quit-after 90`. Main scene: `world/Boot.tscn`
  (→ `world/GreatHall.tscn`).
- **Control-mode spine:** `GameState.mode` (enum `EXPLORING/DIALOGUE/MENU/CUTSCENE/MINIGAME`, a push/pop stack) is the single source of truth for input gating. The player only moves in `EXPLORING`; dialogue, menus, and cutscenes disable control by changing the mode — **never** by poking the player script.
- **Autoloads (`managers/`, kept lean):** `Controls` (registers the input map in code), `GameState` (mode + story flags, serializable), `Inventory` (items + combine + held item), `Clues` (discovered clues, serializable), `AudioManager` (pooled SFX, loads `audio/*.wav`), `Transitions` (fades), `World` (room switching), `Dialogue` (data-driven conversation graphs — conditions, branching, effects — plus a legacy inline-array path), `InventoryScreen` (inventory UI), `Debug` (dev overlay).
- **Maps are editor-authored scenes (author them visually):** each room (`world/GreatHall.tscn`, `world/Antechamber.tscn`) is a `Node2D` with the `Room.gd` controller, painted `Floor`/`Walls` `TileMapLayer`s using the shared `world/tileset/court_tileset.tres`, an `Entities` node of placed prefab instances, and a `Spawns` node of `Marker2D`s. Edit layouts with the TileMap painter; place entities by dragging prefabs from `entities/`. **Do not generate maps in scripts.** `tools/BuildRooms.tscn` only re-scaffolds a room from scratch; day-to-day design is in the editor.
- **TileSet & collision (layer-based):** `world/tileset/court_tileset.tres` (rebuild via `tools/BuildTileSet.tscn`) is the shared tile atlas. **Every** tile carries a full-cell collision shape on physics layer 0 (collision layer 1), so solidity is decided by the layer, not the tile: the **`Walls`** `TileMapLayer` has `collision_enabled = true` (paint anything here → solid) and the **`Floor`** layer has `collision_enabled = false` (walkable). Works with any art; no separate collider nodes. For a 3/4 look, paint solid rows on `Walls` and the walkable front-face row on `Floor`, and keep doors on a walkable cell at the wall base.
- **Entity prefabs (`entities/`):** `Chest`, `Pedestal`, `Door`, `Steward`, `Torch`, `Ghost`, `ExamineSpot` — reusable scenes configured via `@export` in the inspector (chest's item, door's target scene + spawn id, torch's `react_flag`, examine spot's lines, etc.). Add a new interactable = new prefab, not room-script code.
- **Rooms & transitions:** main scene is `world/Boot.tscn` → `World.go_to(scene, spawn_id)`. A `Door` prefab moves between rooms and spawns the player at the destination's named `Marker2D`; autoloads persist across the swap. `Room.gd` only spawns the player, sizes the camera to the map, and optionally plays the intro.
- **Atmosphere:** rooms use a dark `CanvasModulate` + `FlickerLight` torches + a player glow + a vignette, so lighting carries mood. `ShakeCamera.shake()` is on the player camera for impacts/scares.
- **Audio:** placeholder SFX are generated by `tools/GenSfx.tscn` into `audio/`; `AudioManager.play_sfx(&"name")` plays them (silent no-op if absent). Swap the `.wav`s for real audio, no code change.
- **Dev tools (`tools/`, not shipped):** `BuildTileSet` (regenerate the TileSet asset), `BuildRooms` (re-scaffold room scenes), `AtlasViewer` (numbered tile contact sheet), `Screenshotter` (drives the game and saves PNGs for headless visual checks), `GenSfx` (regenerate SFX).
- **Interaction:** everything the player can act on extends `interaction/Interactable.gd` (an `Area2D` on physics layer 2); `InteractionSensor` on the player finds the nearest and calls `interact()`. Reuse this for new NPCs/props — don't write bespoke input handling.
- **Choices matter:** a `DialogueEffect` (or the inline choice's `flag`) writes state via `GameState.set_flag()`; consequences read it back (the steward choice lights/dims the stage and changes later lines). A `DialogueCondition` gates nodes/choices on flags, items, or clues, so dialogue reacts to what the player has done and knows. Route every consequence through flags/clues.
- **Items are data:** `items/*.tres` (`ItemData`, `CombineRecipe`). Add an item = add a `.tres`; add a puzzle = add a recipe + set an `Interactable`'s required item. `Art.gd` slices the placeholder sheet by index.
- **Dialogue & clues are data:** conversations live in `dialogue/conversations/*.tres` (`ConversationData` → `DialogueNode`/`DialogueChoice`, sharing `DialogueCondition`/`DialogueEffect`); clues are `clues/*.tres` (`ClueData`) tracked by the `Clues` autoload (mirrors `Inventory`: `discover()`, `has(id)`, serializable). The same condition/effect model is the one reusable seam for branching dialogue and (planned) knowledge-gated examine/present verbs.
- **Feature folders:** `managers/ player/ interaction/ items/ dialogue/ clues/ ui/ world/ cutscene/ minigames/ debug/`.
- **Tiles:** rooms are painted in the editor against `world/tileset/court_tileset.tres`; if a placeholder tile reads wrong, repaint it or regenerate the atlas via `tools/BuildTileSet.tscn` (use `tools/AtlasViewer.tscn` for the numbered contact sheet).

## Code Style

- Follow the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): `snake_case` for variables/functions, `PascalCase` for classes/nodes, tabs for indentation.
- Add `class_name` to scripts that are reused/instanced elsewhere (components, entities) so they're easy to reference and autocomplete.
- Use typed GDScript (`var speed: float = 60.0`, typed function signatures) wherever practical — improves readability and catches bugs early.
- Keep functions short and single-purpose. If a function needs a comment to explain _what_ it does, consider splitting it or renaming for clarity instead.
- Group scripts/scenes by **feature folder** (e.g. `player/`, `npcs/`, `items/`, `interaction/`, `dialogue/`, `minigames/`, `puzzles/`, `ui/`, `managers/`) rather than by file type.

## What Claude Should Do

- Default to the **simplest working solution**; ask before introducing new systems, autoloads, or architectural patterns not already established in the codebase.
- When adding a set-piece mechanic, keep it **modular and self-contained** (own scene, signal-based results) rather than wiring it into core scripts.
- When disabling player control (cutscenes, dialogue, minigames), go through the **global control-mode**, make the sequence **skippable with a safe end-state**, and guarantee control is restored.
- When gameplay involves a **choice or consequence**, route it through the game-state system so it can persist and be queried later.
- Prefer **data-driven** content (items, recipes, dialogue, puzzle/minigame layouts as Resources) over hardcoding.
- Flag any code that might not perform well on Steam Deck (expensive per-frame work, heavy shaders/lighting, unbatched draw calls).
- Match existing naming/structure conventions found in the codebase before introducing new ones.

## What Claude Should Avoid

- Don't add **C#, third-party plugins, or GDExtension** without discussing first.
- Don't **pre-build mechanics or abstractions** that haven't been asked for — the "built for layering" goal is about keeping the core clean, not about speculatively implementing every future minigame.
- Don't **scatter story/choice flags** across scene scripts; keep them in the game-state system.
- Don't **couple set-piece mechanics into core scripts** (no `if in_minigame:` creeping into the player controller).
- Don't **disable input by reaching into the player script**, leave a cutscene un-skippable, or write one that can soft-lock the player without control.
- Don't build **pre-rendered/video cutscenes** or a custom cutscene timeline when `AnimationPlayer`/`Tween` + `await` already cover it.
- Don't add **direct-combat** systems — this game has none.
