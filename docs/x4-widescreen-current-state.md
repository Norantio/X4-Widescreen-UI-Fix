# X4: Foundations — Current Widescreen & Multi-Monitor Support
## Research Findings (May 2026)

---

## 1. Engine Rendering Capability

> **Prerequisite:** All findings in this document assume GPU-level Surround/Eyefinity (or equivalent) is active — i.e., the OS presents all monitors as a single combined logical resolution (e.g., 5760×1080). If a user has three physical monitors but does **not** have Surround/Eyefinity enabled, X4 renders to whichever single monitor is selected in its settings and the UI scaling issues described here do not apply.

X4's engine will render at any resolution presented to it. If NVIDIA Surround or AMD Eyefinity combines multiple monitors into a single desktop (e.g., 5760×1080, 7680×1440), the game renders 3D content across the full span without issue. Cockpit views, space environments, ships, and stations all display correctly. Borderless window mode is the most common method to achieve this. The 3D rendering layer — skybox, ship models, station geometry, lighting — is fully functional and visually impressive at ultra-wide aspect ratios.

The game also accepts arbitrary custom resolutions through GPU driver settings (NVIDIA custom resolution, AMD Eyefinity). It does not require specific aspect ratios or resolution presets.

---

## 2. What Works

### Cockpit Flight View (Mostly)
The in-cockpit HUD has some built-in awareness for wider displays. On 32:9 monitors (e.g., Samsung Odyssey G9 at 5120×1440), the core flight HUD elements — crosshair, weapon indicators, speed readout, shield/hull status — remain centered on screen. This is actually desirable on a single wide display since peripheral vision can't track elements at the extreme edges of a 49" panel. These elements are screen-anchored and scale reasonably.

### UI Scale Slider
The game provides a **UI Scale** slider in the graphics settings. This is Egosoft's only official accommodation for widescreen users. At wider resolutions, reducing UI Scale (e.g., to 0.3–0.5) shrinks oversized elements back to approximately readable proportions. However, this is a blunt instrument — it affects text and panel sizes globally, making some elements too small while others remain disproportionate. Icon sizes in menus (e.g., station builder component icons) are unaffected by the slider.

### 3D Scene Rendering
Everything in the 3D world renders correctly at any aspect ratio: space combat, mining, flying through sectors, station exteriors, NPC ships, particle effects, weapon fire, explosions, nebulae. The game's visual presentation is genuinely excellent on a triple-monitor setup during flight gameplay.

### Mouse Cursor Accuracy
At least one triple-monitor user (5760×1080) has confirmed that the mouse cursor responds correctly with no position errors — clicks land where expected. This suggests the cursor alignment concern may be a non-issue, and the problems are purely visual (scaling, positioning) rather than input-related. This needs further verification across more configurations, but it's an encouraging data point.

---

## 3. What's Broken

### Root Cause: Horizontal Resolution-Based UI Scaling

The community-identified root cause — confirmed by multiple modders examining decompiled Lua across several game versions — is that the UI scaling system computes element sizes and layout widths relative to horizontal resolution (`GetScreenSizeX()`) rather than vertical resolution. At 16:9, this produces correct results. At wider ratios, every UI element balloons proportionally to the aspect ratio — roughly 2× at 32:9, roughly 3× at 48:9. This should be independently verified against the v8.0 decompiled Lua before the mod ships.

This is not a rendering bug — it's a layout math bug in the Lua menu scripts. The engine's C++ rendering layer works fine; the problem lives in the Lua code that constructs menus, computes table widths, positions frames, and sizes icons.

### Map Menu
The worst offender. At 32:9 and wider:
- Massive dead space between the left property list and the right info panel — the panels scale to the full viewport width instead of docking at fixed widths.
- Station builder component icons become enormous (UI Scale slider does not affect icon sizes, only text).
- The map itself is functional, but the surrounding UI panels are stretched to the point of being unwieldy.
- At 48:9 (triple monitors), the map menu is essentially unusable without reducing UI Scale to near-illegible levels.

### Ship Configuration / Shipyard Menus
- Equipment slot panels stretch across the full viewport width.
- Sliders for configuring equipment, loadouts, and modifications are barely usable — the slider track becomes so wide that fine adjustment is nearly impossible.
- Component icons in the builder are oversized (same icon scaling issue as the map).

### Trade Menus
- Trade offer tables stretch to full viewport width, creating enormous amounts of whitespace between columns.
- Sliders for setting trade quantities have the same usability issue as ship config sliders.

### Mission UI
- Mission briefing panels stretch or misalign.
- Some users report that mission UI elements fail to display entirely at very wide resolutions, particularly during HQ storyline missions.
- At least one user reported getting soft-locked during the signal-finding HQ mission because the video chat interface wouldn't render properly, requiring a switch to single-monitor resolution to progress. *(Single community report — source thread should be located and linked before citing this as confirmed behavior.)*

### Cockpit HUD Side Panels
- The Event Monitor (`con_em`, right side) and Message Ticker (`con_messageticker`, left side) are 3D-positioned in cockpit space for 16:9 viewing angles. *(Connection names per the Ultrawide HUD Fix mod — verify against extracted cockpit XML before implementation.)*
- At wider aspect ratios, these panels drift beyond the visible edges of the center monitor.
- This is a pure positioning issue — the panels still render, they're just not visible without turning the camera.
- Existing mod (Ultrawide HUD Fix) addresses this with static XML position patches for 3840×1024. Other resolutions require manual value editing.

### Station Overview / Builder
- The station planning interface stretches across the full viewport.
- Module placement UI and budget/resource panels are affected by the same horizontal scaling issue.

### General Menu Behavior
- Dialog boxes and popups are anchored to viewport center calculated at 16:9 and can appear off-center or partially off-screen.
- The game options / settings menu stretches but remains functional.
- The encyclopedia stretches but is readable (table-based layout handles width better than panel-based layouts).

---

## 4. Egosoft's Response (or Lack Thereof)

### No Official Fix
Egosoft has not addressed the widescreen UI scaling issue in any patch since launch. The v8.0 patch (September 2025, the most recent major update) includes general map layout improvements for readability and navigation, but contains no mention of widescreen, ultrawide, or multi-monitor UI fixes.

### No Multi-Monitor Settings
The game provides no multi-monitor-specific settings. There is no option to:
- Select a "center monitor" for UI
- Constrain menus to a portion of the viewport
- Choose between stretched and clamped UI layouts
- Offset HUD elements for wider aspect ratios

The only relevant setting is the global UI Scale slider.

### No Dual-Monitor Support
There is no native way to put the map, info panels, or any game UI on a second monitor. X4 renders to a single viewport. The game's monitor selector in settings allows choosing which single monitor to render on, but not spanning or splitting across multiple monitors independently.

### Community Perception
The consistent community sentiment across Steam discussions (2018–2025) is that the engine supports widescreen but Egosoft did not consider multi-monitor or ultra-ultrawide users when designing the GUI. This is characterized as a "known but ignored" issue. Feature requests for widescreen UI fixes and dual-monitor support appear regularly but have never received official acknowledgment.

---

## 5. Existing Mods

### Ultrawide HUD Fix
- **Nexus:** https://www.nexusmods.com/x4foundations/mods/447
- **What it does:** Static XML diff patches that reposition the cockpit HUD side panels (`con_em` and `con_messageticker`) inward so they're visible at wider aspect ratios.
- **Target resolution:** 3840×1024 (one specific triple-monitor config).
- **Limitations:** Static values — users on other resolutions must manually edit the `position.x` values in the XML. Provides no guidance on what values to use for different resolutions. Does not address menu scaling at all.
- **Customization:** Users can adjust `position.x` for horizontal placement and set quaternion values to `0, 0, 0, 1` for a flat (non-angled) HUD appearance. The mod author has provided guidance on this in the Nexus comments.

### 4:3 and 5:4 Aspect Ratio UI Adjustments
- **Nexus:** https://www.nexusmods.com/x4foundations/mods/180
- **What it does:** Fixes misaligned UI elements for narrow aspect ratios (4:3, 5:4).
- **Relevance:** Addresses the opposite end of the aspect ratio spectrum. Not applicable to widescreen, but confirms that the UI layout system is fragile across non-16:9 ratios in both directions.

### X4 External App
- **Nexus:** https://www.nexusmods.com/x4foundations/mods/818
- **What it does:** External companion application that displays game information (not a live map) on a separate monitor via a named pipe interface.
- **Relevance:** Not a UI fix — it's a workaround for the lack of dual-monitor support. Provides supplemental information but doesn't address the core widescreen scaling issues.

### UI Extensions and HUD (kuertee)
- **Nexus:** https://www.nexusmods.com/x4foundations/mods/552
- **What it does:** Modding framework that replaces core menu Lua files with callback-enabled versions. Not a widescreen fix itself, but it's the platform our mod will build on.
- **Relevant detail:** UIX v7.5.03 added a specific callback "to prevent problems with Trade Analytics mod on ultra-wide monitors" — confirming that the callback infrastructure can accommodate layout fixes and that kuertee is receptive to ultrawide-related callback requests. *(Version number and callback description should be verified directly against the UIX changelog or Nexus update history before using as an outreach justification with kuertee.)*

---

## 6. Gap Analysis — What Doesn't Exist Yet

| Need | Current Solution | Gap |
|---|---|---|
| Menu width clamping (map, trade, shipyard, etc.) | UI Scale slider (blunt, affects everything) | **No mod exists.** This is the primary gap. |
| Dynamic cockpit HUD repositioning | Ultrawide HUD Fix (static, single resolution) | Exists but resolution-specific. Needs a universal preset. |
| Dual-monitor support (map on second screen) | X4 External App (limited, not live map) | Engine limitation — cannot be solved by mods. |
| In-game widescreen configuration UI | Nothing | **No mod exists.** |
| Icon scaling fix in menus | Nothing (UI Scale doesn't affect icons) | **No mod exists.** In-game builder icons may use explicit pixel sizes in XML rather than screen-derived values — if so, patchable at the XML level without Lua. Requires investigation before treating as engine-limited. |
| Slider usability at wide resolutions | Nothing | Solvable via Lua — constrain slider track width. |

The largest unserved need is menu layout clamping — constraining the Lua-constructed menus to a readable center region instead of letting them stretch to full viewport width. This is exactly what the Widescreen UI Fix mod targets.

---

## 7. Tested Configurations (Community Reports)

| Resolution | Aspect Ratio | Setup | Reported Status |
|---|---|---|---|
| 3440×1440 | 21.5:9 (2.39:1) | Single ultrawide | Works well. Minor stretching, generally playable. |
| 2560×1080 | 21.3:9 (2.37:1) | Single ultrawide | Works. HUD panels slightly wide but visible. |
| 5120×1440 | 32:9 (3.56:1) | Single super-ultrawide (Samsung G9 etc.) | Menus broken. Flight gameplay fine. Needs UI Scale reduction. |
| 3840×1024 | ~3.75:1 | Triple monitors (1280×1024 each) — note: 1280×1024 is a 5:4 aspect ratio, an unusual config | Menus broken, HUD panels off-screen. Ultrawide HUD Fix mod targets this. |
| 3456×864 | 4:1 | Triple monitors (1152×864 each) | Sliders barely usable, mission UI fails to display, map is a mess. |
| 5760×1080 | 48:9 (5.33:1) | Triple monitors (1920×1080 each) — **primary developer test configuration** (3 × 32" 1080p) | UI massively oversized, menus unusable without extreme UI Scale reduction. Cursor reportedly works correctly. Mod effective width: 1920px (center monitor). Offset: 1920px each side. |
| 7680×1440 | 48:9 (5.33:1) | Triple monitors (2560×1440 each) | User-requested on Ultrawide HUD Fix Nexus page. No confirmed testing. |

---

## 8. Implications for Mod Development

1. **The problem is real, long-standing, and unsolved.** No existing mod addresses menu scaling. The market opportunity is clear.

2. **The UI Scale slider is not a substitute.** It's too blunt — it shrinks text globally while leaving icons untouched, and at the reduction levels needed for triple monitors (~0.3), text becomes illegibly small.

3. **Egosoft is unlikely to fix this.** After 7+ years with no fix and no acknowledgment, this is effectively a community problem to solve.

4. **The cursor works.** The most uncertain risk in the scope (Phase 5: click target alignment) may be a non-issue. At least one user confirms cursor accuracy at 48:9. This potentially eliminates an entire phase of work.

5. **The audience is broader than triple-monitor users.** The 32:9 super-ultrawide market (Samsung Odyssey G9, G9 Neo, Dell U4924DW, LG 49" displays) has the same problems and is a much larger user base. Marketing the mod as "Widescreen UI Fix" rather than "Triple Monitor Fix" captures this audience.

6. **UIX already has ultrawide precedent.** The v7.5.03 callback for Trade Analytics ultrawide compat confirms that kuertee accepts layout-related callback requests, reducing the risk of Phase 3 (callback audit / gap identification).
