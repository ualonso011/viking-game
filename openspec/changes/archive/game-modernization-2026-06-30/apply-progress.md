# Apply Progress: game-modernization

## Status: Applied (partial — placeholder sprites deferred)

## Commits

| Commit | Message | Phase |
|--------|---------|-------|
| `2c440ec` | fix(blockers): autoload casing + level transitions + touch shapes + stretch config | 1 |
| `eaafb5f` | feat(polish): Viking theme + menu animations + HUD vignette | 2 |

## Phase 1 — Fix Blockers

- [x] 1.1 Rename `GameState`→`game_state` in game_manager.gd
- [x] 1.2 Wire fury setter in game_state.gd
- [x] 1.3 Replace `GameState.`→`game_state.` in hud.gd, player.gd, touch_controls.gd, all level_*.gd
- [x] 1.4 Replace `GameManager.` → `game_manager.` in main_menu.gd
- [x] 1.5 Replace `NarrativeDB.` → `narrative_db.` in level scripts
- [x] 1.6 Replace `main.load_level(` → `game_manager.load_level(` in all 7 level scripts
- [x] 1.7 Fix level_07.gd ending → game_manager.return_to_menu()
- [x] 1.8 Add return_to_menu() + stretch config to game_manager.gd
- [x] 1.9 Assign CircleShape2D to 7 TouchScreenButton in touch_controls.gd (r=80 action, r=60 move)
- [x] 1.10 Remove InputEventScreenTouch from project.godot Input Map
- [ ] 1.11 ~~Run generate_placeholders.gd~~ BLOCKED: aarch64 host can't run x86_64 Godot binary. Requires manual execution in Godot editor.
- [x] 1.12 Commit & push Phase 1

## Phase 2 — Visual Modernization

- [x] 2.1 Create assets/themes/viking_theme.tres with palette + font refs
- [x] 2.2 Add title fade-in tween + palette tints to main_menu.gd
- [x] 2.3 Add button hover glow tween to main_menu.gd
- [x] 2.4 Add smooth HP lerp to hud.gd
- [x] 2.5 Add Vignette ColorRect with GradientTexture2D to hud.tscn
- [x] 2.6 return_to_menu() added in Phase 1 — complete
- [x] 2.7 Commit & push Phase 2

## Phase 3 — Validation

- [x] 3.1 grep: zero PascalCase autoload refs remaining
- [x] 3.2 grep: zero main.load_level / main.current_state / InputEventScreenTouch
- [ ] 3.3 ~~Docker headless export~~ Requires x86_64 Docker, not tested
- [ ] 3.4 ~~Manual test on device~~ Out of scope for this automation
- [ ] 3.5 ~~Document test checklist~~ Will be in PR description
- [x] 3.6 Verification greps passed

## Notes

- Placeholder sprite generation (task 1.11) cannot run on aarch64 Godot. Must run `generate_placeholders.gd` in the Godot editor on x86_64.
- CI auto-runs on push. Both pushes succeeded to origin/main.
- Docker export and Android device testing require x86_64 environment.
