# X4: Foundations — Widescreen UI Fix

Fixes broken UI scaling, menu layout, and cockpit HUD positioning for ultrawide (32:9) and triple-monitor (48:9) setups. Built on **kuertee's UI Extensions** framework for maximum compatibility with other mods.

**Auto-detects your resolution.** Completely inert on standard 16:9, 16:10, and 21:9 monitors — safe for anyone to install.

---

## Requirements

- **[UI Extensions and HUD](https://www.nexusmods.com/x4foundations/mods/552)** (kuertee) — hard dependency
- Protected UI Mode **disabled** (Settings → Extensions → Protected UI Mode)

---

## What It Fixes

| Issue | Fix |
|---|---|
| Menus stretch across the full ultrawide viewport | Clamped to a 16:9 center region |
| Cockpit HUD panels pushed off-screen | Repositioned inward via XML diff patches |
| Dialog boxes and overlays off-center | Centered on the active region |
| Click targets misaligned near screen edges | Corrected by proper layout clamping |

**Supported configurations:**

| Setup | Aspect Ratio | Behavior |
|---|---|---|
| Standard (16:9, 16:10, 21:9) | ≤ 2.4:1 | Mod is **inert** |
| Ultrawide+ (32:9 / Samsung G9) | 2.4:1 – 3.6:1 | UI clamped, HUD adjusted |
| Triple landscape (48:9) | > 3.6:1 | Full clamping + HUD repositioning |

---

## Installation

1. Install **UI Extensions and HUD** from Nexus Mods (link above).
2. Download this mod and copy the `trimon_fix` folder into your X4 `extensions/` directory:
   ```
   X4 Foundations/
   └── extensions/
       └── trimon_fix/        ← drop here
           ├── content.xml
           └── ui/
   ```
3. In-game: **Settings → Extensions → Protected UI Mode → OFF**
4. Restart the game.

---

## Configuration

Default behavior requires no configuration. To adjust, edit `ui/trimon_config.lua` directly:

| Setting | Default | Description |
|---|---|---|
| `activationThreshold` | `2.4` | Aspect ratio above which the mod activates. Lower to `2.0` to also fix 21:9. |
| `targetAspect` | `16/9` | The aspect ratio menus are clamped to. Change to `2.39` for a 21:9 center region. |
| `menus.<name>` | `true` | Enable/disable fixes per menu. |

> **Phase 6:** In-game Extension Options UI is planned. Until then, edit the config file directly.

---

## Compatibility

Built on UIX callbacks — coexists with any mod that also uses UIX (Trade Analytics, VRO, SWI, etc.).

Tested with:
- [ ] Trade Analytics
- [ ] Variety and Rebalance Overhaul (VRO)
- [ ] Star Wars Interworlds
- [ ] SirNukes' Mod Support APIs
- [ ] All base DLCs (Split Vendetta, Cradle of Humanity, Tides of Avarice, Kingdom End, Timelines)

---

## Known Issues / Limitations

- **Cockpit HUD repositioning** uses static XML values — a single "conservative center" preset that works across the 32:9–48:9 range. Users with highly unusual setups (mismatched monitors, extreme FOV overrides) may need to manually tune the values in `assets/cockpits/`.
- **Cursor alignment** near screen edges may persist on some configurations (engine-level limitation). Use keyboard navigation as a fallback.
- **Phase 3 callback audit not yet complete** — some menus are stubs pending UIX callback confirmation. See the [scope document](docs/x4-triple-monitor-mod-scope.md) for the full phase plan.

---

## Development

See [docs/x4-triple-monitor-mod-scope.md](docs/x4-triple-monitor-mod-scope.md) for the full architecture, phased work breakdown, and UIX coordination plan.

**Dev environment setup:**
```
X4 Foundations launch flags: -prefersinglefiles -debug all -logfile debuglog.txt
```

**Phase 3 — UIX callback audit** requires decompiling `.xpl` files:
- Tool: [unluac](https://github.com/HansWessels/unluac) (Java JAR)
- Usage: `java -jar unluac.jar kuertee_menu_map.xpl > kuertee_menu_map_decompiled.lua`
- Run on each UIX menu file listed in the scope doc before writing callback registrations.

---

## License

Standard Nexus Mods permissions: credit required for upload, modification allowed with credit.
