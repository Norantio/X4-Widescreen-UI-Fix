# X4: Foundations — Ultrawide & Multi-Monitor UI Fix (UIX-Based)
## Project Scope Document

**Mod Name (working):** `X4 Widescreen UI Fix`
**Mod ID:** `trimon_fix`

---

## 1. Problem Statement

X4: Foundations will render across ultrawide and multi-monitor spans, but the UI breaks at aspect ratios wider than ~21:9:

- **UI scaling is computed from horizontal resolution** instead of vertical, so every UI element balloons proportionally to viewport width.
- **HUD cockpit panels** (event monitor, message ticker, radar) are positioned for 16:9 and get pushed off-screen or clipped at wider ratios.
- **Full-screen menus** (map, shipyard, encyclopedia, mission briefings, trade menus) stretch across the full viewport, with elements landing in bezel gaps or off edges entirely.
- **Click targets misalign** — the cursor position reported to the UI doesn't always match where you're actually clicking, especially near screen edges.
- **Dialog boxes and overlays** (mission info popups, hire builder, etc.) are anchored to viewport center at 16:9 and either vanish or become unusable.

The game is architecturally capable of the wide render — the 3D scene, skybox, and ship models look fantastic. The problem is entirely in the 2D UI/HUD layer.

### Design Principle: Monitor-Agnostic

This mod will **not** target a specific resolution. It detects the viewport aspect ratio at runtime and adapts dynamically. The goal is a single download that works for everyone:

| Tier | Aspect Ratio | Examples | Behavior |
|---|---|---|---|
| **Standard** | ≤ 2.4:1 | 16:9, 16:10, 21:9 (2560×1080, 3440×1440) | Mod is **inert** — zero changes applied |
| **Ultrawide+** | 2.4:1 – 3.6:1 | 32:9 (5120×1440), Samsung G9, etc. | UI clamped to center region, HUD adjusted |
| **Triple landscape** | > 3.6:1 | 48:9 (5760×1080, 7680×1440) | Full clamping + HUD repositioning |
| **Vertical stack** | ≤ 2.4:1 | 3240×1920, 4320×2560 | Mod is **inert** (monitors stacked vertically produce a normal aspect ratio) |

The activation threshold (default: 2.4:1) is user-configurable via Extension Options. Users with 21:9 ultrawide monitors who are happy with the vanilla UI can leave it off; users who find 21:9 menus too stretched can lower the threshold.

---

## 2. Architecture Overview — How X4 UI Works

### Layer 1: Cockpit HUD (XML Components)
- Defined in **component XML files** under `assets/cockpits/` and `assets/props/SurfaceElements/`.
- HUD panels are 3D-positioned elements with `<offset>` nodes containing `<position x y z/>` and `<quaternion qx qy qz qw/>`.
- Key connection names: `con_em` (event monitor — right), `con_messageticker` (left), `con_radar` (center bottom), `con_target` (target info).
- **Moddable via XML diff patches** — no Lua or binary editing needed.
- **Not part of UIX** — this layer is independent and uses standard XML diffing.

### Layer 2: In-Game Menus (Lua Scripts)
- All menus live in `ui/addons/ego_*/` as compiled `.xpl` files (Lua bytecode). Source `.lua` is extractable from the game's `.cat/.dat` archives.
- Each menu is a self-contained Lua script that constructs frames, tables, rows, and content, then calls `frame:display()`.
- The engine provides a Lua API for creating UI widgets (frames, tables, buttons, sliders, text, icons). Layout math is done in Lua — **this is where the scaling bug lives**.
- **This is the layer UIX operates on.** UIX replaces the base game's menu Lua files with versions that include callback hooks, allowing multiple mods to modify the same menus without conflicting.

### Layer 3: Core UI Framework (Engine-Level)
- The underlying UI renderer is part of the C++ engine — **not moddable**.
- However, the Lua scripts can query screen dimensions (`GetScreenSizeX()`, `GetScreenSizeY()`) and do their own math, so the fix goes in Lua.

### Layer 4: Fonts / Text Rendering
- Font scaling is partially engine-driven. The `config.textScalingFactor` in some Lua files affects text size.
- May need per-file adjustment via UIX callbacks.

---

## 3. Framework Decision: UI Extensions (UIX)

This mod will be built on **kuertee's UI Extensions and HUD** (UIX) framework. This is a foundational decision that shapes the entire implementation.

### What UIX Provides

UIX replaces the base game's core menu Lua files (map, interact menu, detail monitor, ship config, station overview, encyclopedia, etc.) with modified versions that inject **callback hooks** at key points in each menu's rendering pipeline. Multiple mods can register callbacks at the same hook point without conflicting.

### How UIX Callbacks Work

```lua
-- 1. Get a reference to the base game menu you want to modify
local menu = Menus.Find("MapMenu")  -- or whatever the menu's registered name is

-- 2. Register a callback at a specific hook point
menu.registerCallback("createInfoFrame_on_start", myCallbackFunction)

-- 3. Your callback receives the function's parameters and can modify behavior
function myCallbackFunction(frame, config, ...)
    -- Modify frame dimensions, table widths, etc.
    -- Return values expected by the callback (if any)
end
```

Each UIX menu file has dozens of named callback points inserted throughout its rendering functions. You search the UIX `.xpl` files for `"callback"` to find them all. If a callback doesn't exist where you need one, you coordinate with kuertee to add it.

### Why UIX (vs. standalone)

| Concern | Standalone | UIX-Based |
|---|---|---|
| Mod compatibility | Conflicts with any mod touching the same Lua files | Coexists via callbacks — the whole point of UIX |
| Community reach | Users must choose between this mod and UIX-dependent mods | Works alongside Trade Analytics, Emergent Missions, VRO UI tweaks, etc. |
| Maintenance burden | Must re-merge every Lua file on each game update | kuertee + contributors handle base Lua merges; your callbacks usually survive |
| Callback availability | N/A — you own the files | May need to request new callbacks from kuertee for layout-specific hooks |
| Dependency | None | Requires UIX installed + Protected UI Mode disabled |

### UIX Implications

- **Hard dependency:** UIX must be listed as a required download.
- **Protected UI Mode:** Must be disabled by the user — non-negotiable for any UIX-based mod.
- **Callback gaps:** UIX was built for adding functionality (buttons, panels, data), not for layout overhaul. Some of the hooks we need for width/position clamping **may not exist yet**. This is the primary risk — we may need to work with kuertee to add new callbacks at frame construction / dimension calculation points.
- **Update cadence:** UIX tracks Egosoft's release cycle closely (kuertee typically ships UIX updates within days of a game patch). Our mod benefits from this but is also gated by it.

---

## 4. Mod Structure

```
extensions/
  trimon_fix/
    content.xml                          ← mod metadata + UIX dependency
    ui/
      ui.xml                             ← declares our Lua files to the game
      trimon_config.lua                  ← user-facing config (resolution, offsets)
      trimon_utils.lua                   ← shared utility module (width clamping, scaling)
      trimon_menu_map.lua                ← map menu layout fixes (via UIX callbacks)
      trimon_menu_detailmonitor.lua      ← detail monitor fixes
      trimon_menu_interactmenu.lua       ← interact menu fixes
      trimon_menu_shipconfig.lua         ← ship config fixes
      trimon_menu_stationoverview.lua    ← station overview fixes
      trimon_menu_missionoffer.lua       ← mission briefing fixes
      trimon_menu_trademenu.lua          ← trade menu fixes
      trimon_menu_gameoptions.lua        ← settings menu fixes
      trimon_menu_encyclopedia.lua       ← encyclopedia fixes
      trimon_menu_toplevel.lua           ← HUD/toplevel overlay fixes
    assets/
      cockpits/
        (per-faction cockpit XML diffs)  ← HUD panel repositioning
      props/
        SurfaceElements/
          macros/
            (HUD element XML diffs)
    md/
      trimon_setup.xml                   ← MD script for init (if needed)
```

### content.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<content
    id="trimon_fix"
    name="Widescreen UI Fix"
    description="Dynamically fixes UI scaling, menu layout, and HUD positioning for ultrawide (32:9) and triple-monitor (48:9) setups. Auto-detects resolution — no configuration required. Requires UI Extensions."
    author="Nick"
    version="010"
    date="2026-05-20"
    save="false"
    sync="false"
    enabled="true">
  <dependency id="kuertee_ui_extensions" optional="false" name="UI Extensions and HUD" />
</content>
```

### ui/ui.xml

This is how the game discovers your Lua files. Each file is loaded alongside (not replacing) the base game + UIX Lua files:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<addon name="trimon_fix"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:noNamespaceSchemaLocation="../../ui/core/addon.xsd">
  <environment type="menus">
    <!-- Utility module — loaded first -->
    <file name="ui/trimon_utils.lua" />
    <file name="ui/trimon_config.lua" />

    <!-- Per-menu callback registrations -->
    <file name="ui/trimon_menu_map.lua" />
    <file name="ui/trimon_menu_detailmonitor.lua" />
    <file name="ui/trimon_menu_interactmenu.lua" />
    <file name="ui/trimon_menu_shipconfig.lua" />
    <file name="ui/trimon_menu_stationoverview.lua" />
    <file name="ui/trimon_menu_missionoffer.lua" />
    <file name="ui/trimon_menu_trademenu.lua" />
    <file name="ui/trimon_menu_gameoptions.lua" />
    <file name="ui/trimon_menu_encyclopedia.lua" />
    <file name="ui/trimon_menu_toplevel.lua" />

    <!-- Dependencies — ensure UIX menus load before our callback registrations -->
    <dependency name="ego_detailmonitor" />
    <dependency name="ego_mapMenu" />
    <dependency name="ego_interactMenu" />
    <dependency name="ego_shipconfig" />
    <dependency name="ego_stationoverview" />
    <dependency name="ego_missionoffer" />
    <dependency name="ego_trademenu" />
    <dependency name="ego_gameoptions" />
    <dependency name="ego_encyclopedia" />
  </environment>
</addon>
```

---

## 5. Core Utility Module: trimon_utils.lua

This is the heart of the mod — a shared module that every per-menu callback file imports. It encapsulates all resolution detection and layout clamping logic in one place. The key design decisions: it caches screen info (resolution doesn't change mid-session), it uses a configurable activation threshold so users can tune sensitivity, and it early-returns with zero overhead at standard aspect ratios.

```lua
-- trimon_utils.lua
-- X4 Widescreen UI Fix — shared utility module
-- Dynamically detects viewport geometry and provides layout clamping.
-- Completely inert at standard aspect ratios (16:9, 16:10, 21:9).

local trimon = {}

-- ============================================================
-- USER-CONFIGURABLE (overridden by trimon_config.lua / Extension Options)
-- ============================================================
trimon.config = {
    enabled = true,

    -- Aspect ratio above which the mod activates.
    -- 2.4 ≈ wider than 21:9 (2560×1080 = 2.37:1, 3440×1440 = 2.39:1).
    -- Set lower (e.g., 2.0) to also fix 21:9, or higher (e.g., 3.5) for triple-only.
    activationThreshold = 2.4,

    -- Target aspect ratio for UI clamping.
    -- 16:9 = 1.778 (default). Set to 2.39 to clamp to 21:9 center instead.
    targetAspect = 16 / 9,

    -- Per-menu enable/disable
    menus = {
        map = true,
        detailmonitor = true,
        interactmenu = true,
        shipconfig = true,
        stationoverview = true,
        missionoffer = true,
        trademenu = true,
        gameoptions = true,
        encyclopedia = true,
        toplevel = true,
    }
}

-- ============================================================
-- RUNTIME DETECTION
-- ============================================================

-- Cache ONLY physical screen dimensions (won't change mid-session).
-- Classification (isStandard, isUltrawide, isTriple) is recomputed each call so
-- changes to trimon.config.activationThreshold (via Extension Options) take effect
-- immediately without needing resetCache().
--
-- ⚠ API NAMES: Verify against your game version before shipping.
-- Common alternatives to try if these return nil:
--   C.GetScreenWidth() / C.GetScreenHeight()  (C FFI table)
--   GetScreenWidth() / GetScreenHeight()
local _dimsCache = nil

local function _getDims()
    if _dimsCache then return _dimsCache end
    -- Defensive fallback: wrong API name → 1920×1080 (16:9) instead of nil crash.
    -- Mod stays inert and logs a warning until the correct name is confirmed.
    local w = (GetScreenSizeX and GetScreenSizeX())
           or (C and C.GetScreenWidth and C.GetScreenWidth())
           or 1920
    local h = (GetScreenSizeY and GetScreenSizeY())
           or (C and C.GetScreenHeight and C.GetScreenHeight())
           or 1080
    if w == 1920 and h == 1080 then
        DebugError("TriMon WARNING: screen size API returned nil — verify GetScreenSizeX/Y names")
    end
    _dimsCache = { width = w, height = h, aspect = w / h }
    return _dimsCache
end

function trimon.getScreenInfo()
    local dims = _getDims()
    local t = trimon.config.activationThreshold
    local info = {
        width       = dims.width,
        height      = dims.height,
        aspect      = dims.aspect,
        isStandard  = (dims.aspect <= t),
        isUltrawide = (dims.aspect > t and dims.aspect <= 3.6),
        isTriple    = (dims.aspect > 3.6),
        label       = "standard",
    }
    if info.isTriple    then info.label = "triple"
    elseif info.isUltrawide then info.label = "ultrawide+" end
    return info
end

-- Invalidate dims cache (only needed if resolution changes mid-session — very unlikely).
-- Note: changing trimon.config.activationThreshold does NOT require resetCache().
function trimon.resetCache()
    _dimsCache = nil
end

-- ============================================================
-- LAYOUT CLAMPING
-- ============================================================

-- Get the "effective" width for UI layout.
-- Returns the width in pixels of the target aspect ratio region centered on the viewport.
-- e.g., at 7680×1440 with targetAspect 16:9 → returns 2560 (one monitor's worth).
function trimon.getEffectiveWidth()
    local info = trimon.getScreenInfo()
    if info.isStandard then return info.width end

    local maxWidth = math.floor(info.height * trimon.config.targetAspect)
    return math.min(info.width, maxWidth)
end

-- Get the X offset (in pixels) to center a clamped-width element on the full viewport.
-- e.g., at 7680×1440 → offset = (7680 - 2560) / 2 = 2560.
function trimon.getCenterOffsetX()
    local info = trimon.getScreenInfo()
    local effective = trimon.getEffectiveWidth()
    return math.floor((info.width - effective) / 2)
end

-- Scale a value that was computed relative to full screen width
-- down to the effective (clamped) width.
function trimon.scaleWidth(value)
    local info = trimon.getScreenInfo()
    if info.isStandard then return value end

    local effective = trimon.getEffectiveWidth()
    return value * (effective / info.width)
end

-- Clamp a width value to the effective region.
function trimon.clampWidth(requestedWidth)
    local effective = trimon.getEffectiveWidth()
    return math.min(requestedWidth, effective)
end

-- Master check: should the mod do anything at all?
function trimon.isActive()
    if not trimon.config.enabled then return false end
    local info = trimon.getScreenInfo()
    return not info.isStandard
end

-- Per-menu check.
function trimon.isMenuActive(menuName)
    if not trimon.isActive() then return false end
    if trimon.config.menus[menuName] == nil then return true end  -- default: on
    return trimon.config.menus[menuName]
end

-- ============================================================
-- DEBUG / INFO
-- ============================================================

function trimon.getDebugString()
    local info = trimon.getScreenInfo()
    return string.format(
        "TriMon: %dx%d (%.2f:1) [%s] active=%s effective=%d offset=%d",
        info.width, info.height, info.aspect, info.label,
        tostring(trimon.isActive()),
        trimon.getEffectiveWidth(),
        trimon.getCenterOffsetX()
    )
end

-- Expose as a global so per-menu files can access it directly.
-- X4's Lua environment loads all ui.xml <file> entries into a shared namespace,
-- so _G.trimon is visible in every file declared after this one in ui.xml.
-- require() with extension-relative paths is NOT supported in X4's Lua sandbox.
_G.trimon = trimon
return trimon  -- kept for forward-compat; not relied upon
```

---

## 6. Work Breakdown (UIX-Based)

### Phase 1: Setup & Environment (Effort: Low — ~3-5 hours)

**Goal:** Working dev environment with UIX installed and a skeleton mod that loads.

- [ ] Install X4 Customizer or XRCatTool to extract `.cat/.dat` archives
- [ ] Extract all Lua source from `ui/addons/ego_*` directories for reference
- [ ] Extract cockpit component XMLs from `assets/cockpits/` and `assets/props/SurfaceElements/`
- [ ] Install UIX from Nexus or clone from GitHub
- [ ] Copy UIX's `ui/` folder into the game's `ui/` folder (per UIX dev instructions)
- [ ] Launch game with `-prefersinglefiles -debug all -logfile debuglog.txt`
- [ ] Disable Protected UI Mode in Settings > Extensions
- [ ] Create the `trimon_fix` mod skeleton (content.xml, ui/ui.xml, trimon_utils.lua)
- [ ] Verify mod loads — check debuglog.txt for errors
- [ ] Verify UIX detects the dependency correctly

**Key gotcha (dev workflow only):** When actively editing UIX's `.xpl` files, copy them into the game's `ui/addons/` folder so the `-prefersinglefiles` flag picks them up as loose files without repacking cat/dat archives. This is a development convenience only — the installed layout (Section 11) correctly keeps UIX files under `extensions/kuertee_ui_extensions/ui/` and the extension system loads them from there at runtime. The copy step is purely for fast iteration during development.

### Phase 2: Cockpit HUD Repositioning (Effort: Low-Medium — ~4-8 hours)

**Goal:** Get all cockpit HUD panels visible and properly positioned across any widescreen config.

This phase is **independent of UIX** — it uses standard XML diff patches.

**The monitor-agnostic challenge:** XML diff values are static 3D world coordinates, baked in at game load. There is no Lua API to reposition cockpit connection points at runtime. However, this is less of a problem than it sounds:

- The HUD panel positions are in **3D space** relative to the cockpit, not in screen pixels. At wider viewports, the camera sees more of the cockpit, but the panels stay at their 3D positions.
- The fix is to move panels **inward** (smaller `|position.x|`) and optionally flatten their angle (quaternion closer to identity). This brings them into the center ~60% of the viewport.
- Because this is proportional geometry, a single set of "conservative center" values works across the full range of widescreen resolutions. At 32:9 the panels sit comfortably in view; at 48:9 they're still visible and readable; at 21:9 they're a touch more inward than vanilla but still natural.
- The difference between 5760×1080 and 7680×1440 in terms of 3D projection is negligible for HUD panel placement — what matters is the FOV and aspect ratio, not the pixel count.

**What to patch:**

| Element | Connection Name | Issue | Fix |
|---|---|---|---|
| Event Monitor | `con_em` | Drifts off right edge at wide ratios | Reduce `position.x`, flatten quaternion |
| Message Ticker | `con_messageticker` | Drifts off left edge | Mirror of `con_em` fix |
| Radar | `con_radar` | May clip at bottom | Verify position, adjust if needed |
| Target Monitor | `con_target` | Potential offset issues | Verify and adjust |
| Shield/Hull bars | Various | Positioning | Verify and adjust |

**Approach:**
- Use the existing [Ultrawide HUD Fix](https://www.nexusmods.com/x4foundations/mods/447) as a reference — it patches `con_em` and `con_messageticker` for 3840×1024.
- Tune values to be "safe center" — visible at 48:9, not awkwardly inward at 32:9.
- Flatten quaternion to `qx=0, qy=0, qz=0, qw=1` for a flat-on-screen look (reduces angle distortion at wide FOVs).
- Test at both 32:9 and 48:9 to verify the single set of values works across the range.

**Per-faction testing:** Cockpit geometry differs by faction (Argon, Paranid, Teladi, Split, Terran). Each may need its own XML diff file — the position values may differ because the cockpit models have different geometries. Budget for testing one ship per faction.

**Reference XML diff:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<diff xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <replace sel="/components/component/connections/connection[@name='con_em']/offset">
    <offset>
      <position x="0.3600" y="-0.145" z="0.4220"/>
      <quaternion qx="0" qy="0" qz="0" qw="1"/>
    </offset>
  </replace>
  <replace sel="/components/component/connections/connection[@name='con_messageticker']/offset">
    <offset>
      <position x="-0.3600" y="-0.145" z="0.4220"/>
      <quaternion qx="0" qy="0" qz="0" qw="1"/>
    </offset>
  </replace>
</diff>
```

**Limitation:** Because the XML is static, the HUD repositioning is a "one size fits most" solution. Users with unusual setups (e.g., 3 mismatched monitors, very high FOV overrides) may need to manually tweak the XML values. The Nexus Mods page should document the value format and how to adjust it.

**Milestone:** Playable cockpit view with all HUD elements visible at any widescreen resolution.

### Phase 3: UIX Callback Audit (Effort: Medium — ~6-10 hours)

**Goal:** Map which existing UIX callbacks can be used for layout fixes, and identify where new callbacks are needed.

This is a **research phase** that must happen before writing the actual menu fix code. The work:

0. **Decompile all UIX `.xpl` files before doing anything else.** `.xpl` is compiled Lua bytecode — you cannot read it in a text editor. Tool: [unluac](https://github.com/HansWessels/unluac) (Java JAR, no install needed).
   ```
   java -jar unluac.jar kuertee_menu_map.xpl > kuertee_menu_map_decompiled.lua
   ```
   Run on every file in the audit table below. Keep the decompiled `.lua` files locally (do not commit — they are derived from game IP).

1. **For each P0/P1 menu**, open the decompiled Lua file and search for all `callback` invocations.
2. **Document every callback** — its name, where in the rendering pipeline it fires, what parameters it receives, and what return values it expects.
3. **Identify layout-relevant callbacks** — specifically ones that fire:
   - At frame creation time (where width/height are set)
   - At table construction time (where column widths are computed)
   - Before `frame:display()` is called (last chance to adjust dimensions)
4. **Flag gaps** — places where the width calculation happens but no callback exists.
5. **Draft callback requests** for kuertee — specific function names, parameter lists, and insertion points.

**UIX menus to audit (files in UIX's `ui/` folder):**

| Priority | UIX File | Base Game Addon |
|---|---|---|
| P0 | `kuertee_menu_map.xpl` | `ego_mapMenu` |
| P0 | `kuertee_menu_detailmonitor.xpl` | `ego_detailmonitor` |
| P0 | `kuertee_menu_interactmenu.xpl` | `ego_interactMenu` |
| P1 | `kuertee_menu_ship_configuration.xpl` | `ego_shipconfig` |
| P1 | `kuertee_menu_station_overview.xpl` | `ego_stationOverview` |
| P1 | `kuertee_menu_missionoffer.xpl` | `ego_missionoffer` |
| P1 | `kuertee_menu_trademenu.xpl` | `ego_trademenu` |
| P2 | `kuertee_menu_gameoptions.xpl` | `ego_gameoptions` |
| P2 | `kuertee_menu_encyclopedia.xpl` | `ego_encyclopedia` |

**Expected outcome:** A callback map document + a list of new callback requests to send to kuertee. The requests should be specific:

> "In `kuertee_menu_map.xpl`, function `menu.createMainFrame()`, at line N where `frameWidth` is computed from `GetScreenSizeX()`, please add a callback `createMainFrame_on_before_set_width(frameProperties)` that passes the frame properties table before it's applied, and expects a modified table back."

**Important:** kuertee is responsive and the UIX project is actively maintained (most recent update: May 2026). He's added callbacks for Trade Analytics ultrawide fixes before, so this kind of request has precedent.

### Phase 4: Menu Layout Fixes via Callbacks (Effort: HIGH — ~20-35 hours)

**Goal:** Fix the most-used menus so they're usable at triple-monitor resolutions.

For each menu, the pattern is:

1. Register callbacks in the menu's frame/table construction functions.
2. In the callback, intercept width values and clamp them using `trimon_utils`.
3. Adjust X-offsets to center the clamped region.
4. Handle edge cases (scrollbars, nested frames, dynamic content).

**Per-menu Lua file template:**

```lua
-- trimon_menu_map.lua
-- Widescreen UI Fix — Map Menu layout corrections

-- trimon is a global set by trimon_utils.lua, which ui.xml loads first.
-- X4's Lua sandbox does not support require() with extension-relative paths.
if not trimon then
    DebugError("TriMon: trimon_utils.lua not loaded — check ui.xml file ordering")
    return
end

local ModLua = {}

function ModLua.init()
    if not trimon.isMenuActive("map") then return end

    -- ⚠ VERIFY IN PHASE 3: both the menu's registered name AND the registration
    -- API shape. UIX may use a different call than shown here, e.g.:
    --   kuertee_ui_extensions.addCallback("map", "hookName", fn)
    -- Consult the UIX sample mod (Section 10) for the canonical pattern.
    -- The menu name "MapMenu" is also a guess — search UIX source for
    -- the string passed to Menus.Add() or equivalent to confirm it.
    local MapMenu = Menus.Find("MapMenu")
    if not MapMenu then
        DebugError("TriMon: MapMenu not found — verify menu name and UIX installation")
        return
    end

    DebugError(trimon.getDebugString())  -- logs resolution info once

    -- Register callbacks at layout-critical points
    -- (Exact callback names AND registration API shape TBD from Phase 3 audit)
    MapMenu.registerCallback(
        "createMainFrame_on_before_set_width",
        ModLua.onMapFrameWidth,
        "trimon_fix"  -- UIX callback ID for deregistration support
    )
    MapMenu.registerCallback(
        "createInfoFrame_on_start",
        ModLua.onInfoFrameStart,
        "trimon_fix"
    )
end

function ModLua.onMapFrameWidth(frameProps)
    -- Clamp the frame width to center region
    frameProps.width = trimon.clampWidth(frameProps.width)
    frameProps.x = trimon.getCenterOffsetX()
    return frameProps
end

function ModLua.onInfoFrameStart(frame, config)
    -- Adjust info panel dimensions
    if config and config.width then
        config.width = trimon.clampWidth(config.width)
    end
    return frame, config
end

ModLua.init()
```

**Priority order:**

| Priority | Menu | Complexity | Notes |
|---|---|---|---|
| P0 | Map Menu | High | Most complex menu in the game; multiple nested frames, dynamic resizing, info panels |
| P0 | Detail Monitor | Medium | Always-visible side panel; width computation is relatively contained |
| P0 | Interact Menu | Low-Medium | Popup menu; mainly needs position clamping to center screen |
| P1 | Ship Configuration | Medium | Multi-panel layout with equipment slots |
| P1 | Station Overview | Medium-High | Complex builder interface with plan view |
| P1 | Trade Menu | Low-Medium | Table-based; mainly width clamping |
| P1 | Mission Offers | Low | Overlay panel; center it |
| P2 | Game Options | Low | Settings menu; center it |
| P2 | Encyclopedia | Medium | Multi-panel reference layout |
| P2 | Top Level / HUD overlays | Low | Miscellaneous HUD elements |

**Estimated per-menu effort:**
- Simple menus (interact, mission, options): 1-3 hours each
- Medium menus (detail monitor, ship config, trade, encyclopedia): 3-6 hours each
- Complex menus (map, station overview): 6-10 hours each

### Phase 5: Click Target / Cursor Alignment (Effort: Medium — ~4-10 hours)

**Goal:** Verify and fix cursor alignment issues.

**Approach:**
- After Phase 4, test click accuracy across all fixed menus.
- If the layout clamping fixes properly constrain the interactive regions, cursor alignment may self-correct — the engine maps mouse position to the actual rendered element positions.
- If misalignment persists, investigate whether the cursor coordinate system uses the full viewport or the menu's local space.
- **Worst case:** This is an engine-level issue and is unfixable from Lua. Document it as a known limitation and recommend users rely on keyboard navigation where possible.

### Phase 6: Polish, Config & Release (Effort: Medium — ~6-10 hours)

- [ ] **In-game configuration** via Extension Options menu:
  - Enable/disable per-menu
  - Aspect ratio override (e.g., force 16:9, allow 21:9 for ultrawide users who don't want full clamping)
  - HUD positioning presets (tight/default/wide)
- [ ] **Compatibility testing:**
  - Trade Analytics (known ultrawide callback already in UIX — `v7.5.03` added a callback specifically for ultrawide Trade Analytics compat)
  - VRO (Variety and Rebalance Overhaul)
  - StarWars Interworlds (heavily modded UI via UIX)
  - SirNukes' Mod Support APIs
- [ ] **DLC testing:** Split Vendetta, Cradle of Humanity, Tides of Avarice, Kingdom End, Timelines
- [ ] **Multi-resolution testing:** 5760×1080, 7680×1440, and at least one ultrawide (3440×1440) to ensure the mod is inert at sane aspect ratios
- [ ] **Documentation:** README, Nexus Mods page, installation instructions
- [ ] **Packaging:** Extension folder (no cat/dat packing needed for pure Lua + XML diff mods — loose files work fine)

---

## 7. Technical Risks & Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| **UIX lacks callbacks at layout-critical points** | High | Phase 3 audit identifies gaps early. kuertee is responsive — has added layout callbacks before (v7.5.03 ultrawide fix). Prepare specific, well-documented callback requests. Fallback: for menus without callbacks, provide standalone Lua overrides as a secondary package. |
| **Cursor misalignment is engine-level** | High | Test after Phase 4. If unfixable, document as known limitation. Check if `SetCursorOffset()` or similar API exists. |
| **Game updates break UIX callbacks** | Medium | Low risk — UIX tracks game versions closely. Your callbacks are registered by name; as long as kuertee doesn't rename them, they survive. Pin your mod to a UIX version range in docs. |
| **Some menus have width calculations deep in engine C++** | Medium | Accept partial fixes. Some frames may not be fully clampable from Lua. Document which menus have remaining issues. |
| **Different cockpit geometries per ship faction** | Low | Test one ship per faction. May need per-faction XML diff files (small effort, just tuning position values). |
| **Performance impact** | Low | UIX callbacks add negligible overhead. The `trimon.isActive()` early-return means zero cost on standard monitors. |
| **UIX adoption barrier** | Low | UIX is the most popular modding framework — most serious X4 mod users already have it. Document the requirement clearly. |

---

## 8. Effort Estimate Summary

| Phase | Hours (est.) | Difficulty | Deliverable |
|---|---|---|---|
| 1 — Setup & Environment | 3–5 | Easy | Working dev environment, mod skeleton loads |
| 2 — Cockpit HUD (XML) | 4–8 | Easy-Medium | All HUD panels visible at target resolution |
| 3 — UIX Callback Audit | 6–10 | Medium | Callback map document, new callback request list |
| 4 — Menu Layout Fixes | 20–35 | Hard | P0-P2 menus usable at triple-monitor res |
| 5 — Cursor Alignment | 4–10 | Medium-Hard | Verified click accuracy (or documented limitations) |
| 6 — Polish & Release | 6–10 | Medium | Configurable, tested, documented, published |
| **Total** | **43–78 hours** | | |

### Milestone Plan

| Milestone | After Phase | What Ships |
|---|---|---|
| **Alpha — "Playable"** | 2 | HUD-only fix. Cockpit is correct; menus still broken but usable with in-game UI Scale slider. |
| **Beta — "Usable"** | 4 (P0 menus) | Map, detail monitor, interact menu fixed. Core gameplay loop works on triple monitors. |
| **RC — "Good"** | 4 (P1 menus) | Ship config, station builder, trade, missions all fixed. |
| **v1.0 — "Complete"** | 6 | All menus fixed, in-game config, documented, community-tested. |

---

## 9. Coordination with kuertee

Building on UIX means working with its maintainer. Recommended approach:

1. **Join the Egosoft unofficial Discord** (https://discord.gg/RzAGhcY) — kuertee is active in the modding channel.
2. **After Phase 3**, send kuertee your callback request list with:
   - The specific UIX file and function name
   - The exact line/location where the callback should fire
   - What parameters it should pass to your callback
   - What return values it should accept
   - A brief explanation of why (ultrawide/triple monitor layout correction)
3. **Offer to submit the changes yourself** via GitHub PR — kuertee accepts contributor PRs (the README credits multiple contributors who've added callbacks).
4. **Coordinate release timing** — kuertee's process is to merge your callbacks and release UIX alongside your mod.

The existing precedent is encouraging: UIX v7.5.03 specifically added a callback "to prevent problems with Trade Analytics mod on ultra-wide monitors." Your use case is a natural extension of this.

---

## 10. Key Resources

| Resource | Purpose | URL |
|---|---|---|
| UI Extensions & HUD (Nexus) | Primary dependency | https://www.nexusmods.com/x4foundations/mods/552 |
| UI Extensions (GitHub) | Source code, PRs | https://github.com/kuertee/x4-mod-ui-extensions |
| UIX Sample Mod | Reference implementation | Available on UIX's Nexus page |
| Egosoft Discord (Modding) | Coordination with kuertee | https://discord.gg/RzAGhcY |
| Ultrawide HUD Fix (Nexus) | Reference for cockpit XML | https://www.nexusmods.com/x4foundations/mods/447 |
| X4 Customizer (GitHub) | Extract/repack cat/dat | https://github.com/bvbohnen/X4_Customizer/ |
| XML Diff/Patch Tool (Nexus) | Generate diff XMLs | https://www.nexusmods.com/x4foundations/mods/1578 |
| Egosoft Modding Wiki | Official docs, XPath ref | https://wiki.egosoft.com/X4%20Foundations%20Wiki/Modding%20Support/ |
| X4 Lua API Definitions | Community Lua type defs | https://github.com/LuaLS/LLS-Addons/issues/242 |

---

## 11. Key File Paths

```
X4 Foundations/
├── 01.cat / 01.dat ... 09.cat / 09.dat     ← base game archives
├── extensions/
│   ├── kuertee_ui_extensions/               ← UIX mod (DEPENDENCY)
│   │   ├── content.xml
│   │   └── ui/
│   │       ├── kuertee_menu_map.xpl         ← UIX's patched map menu
│   │       ├── kuertee_menu_detailmonitor.xpl
│   │       ├── kuertee_menu_interactmenu.xpl
│   │       ├── kuertee_menu_ship_configuration.xpl
│   │       ├── kuertee_menu_station_overview.xpl
│   │       └── ...
│   ├── trimon_fix/                          ← THIS MOD
│   │   ├── content.xml
│   │   ├── ui/
│   │   │   ├── ui.xml
│   │   │   ├── trimon_utils.lua
│   │   │   ├── trimon_config.lua
│   │   │   └── trimon_menu_*.lua            ← per-menu callback registrations
│   │   └── assets/
│   │       └── (cockpit XML diffs)
│   ├── ego_dlc_split/                       ← DLCs
│   ├── ego_dlc_terran/
│   ├── ego_dlc_pirate/
│   ├── ego_dlc_boron/
│   └── ego_dlc_timelines/
└── ui/                                      ← (dev only: UIX xpl files copied here)
    └── addons/
        └── ego_*/                           ← base game menu Lua (from cat/dat)
```

---

## 12. Publishing Plan

### Mod Identity

- **Nexus Mods name:** `Widescreen UI Fix` (or `Ultrawide & Multi-Monitor UI Fix`)
- **Category:** Miscellaneous → UI (on Nexus), or Utilities
- **Tags:** ultrawide, triple monitor, multi-monitor, UI fix, widescreen, 32:9, 48:9, surround, eyefinity
- **Don't call it "Triple Monitor Fix"** — that narrows the audience. The 32:9 super-ultrawide crowd (Samsung Odyssey G9, etc.) is a much larger user base and has the same problems.

### Nexus Mods Page Structure

1. **Hero screenshot:** Before/after comparison at 32:9 or 48:9. Map menu is the most dramatic.
2. **Description:** Lead with "Does your UI look broken on an ultrawide or multi-monitor setup? This mod fixes it."
3. **Features list:**
   - Auto-detects any resolution — zero configuration required
   - Clamps menus to a readable center region
   - Repositions cockpit HUD panels
   - Completely inert on standard 16:9 / 21:9 monitors — safe to install for everyone
   - Built on UI Extensions for maximum mod compatibility
   - Configurable via Extension Options
4. **Requirements:** UI Extensions and HUD (kuertee) — link prominently
5. **Compatibility:** List tested mods (Trade Analytics, VRO, SWI, etc.)
6. **Known issues:** Cursor alignment (if unresolved), specific menus not yet patched
7. **FAQ:**
   - "Do I need this on a regular monitor?" → No, it does nothing at 16:9.
   - "Does this work with [mod]?" → If it uses UIX, almost certainly yes.
   - "My HUD panels are in the wrong spot" → How to adjust the XML values.

### Steam Workshop

Steam Workshop is an option but has technical complications — Lua files need `.txt` extensions on Workshop due to Steam's file type restrictions, and `subst_01.cat/dat` packaging is required for certain file types. Nexus Mods is the primary distribution channel; Workshop can be added later if there's demand.

### Versioning

- **Alpha releases** (0.x): HUD fix only, limited menus
- **Beta releases** (0.9x): All P0-P1 menus fixed, seeking community testers
- **v1.0:** Full menu coverage, in-game config, documented
- **Post-1.0:** Track Egosoft game updates, UIX updates, community bug reports

### Community Testing Strategy

Publishing early (after Phase 2 + a couple P0 menus) is important for this mod specifically because:
- You can't personally test every monitor config — you need users with 32:9, various triple setups, different GPU vendors (NVIDIA Surround vs. AMD Eyefinity), etc.
- The cockpit HUD values need validation across multiple ship factions on multiple resolutions.
- Cursor alignment behavior may differ across configs.

Ask for:
- Resolution and setup description
- Screenshot of the map menu (most complex layout)
- Screenshot of cockpit HUD in different faction ships
- Any menus that still break

### License

Standard Nexus Mods permissions:
- Upload permission: credit required
- Modification permission: allowed with credit
- This is important because if you stop maintaining the mod, someone else can pick it up and update it for future game versions.

---

## 13. Summary Decision Matrix

| Question | Decision | Rationale |
|---|---|---|
| Framework? | UIX callbacks | Mod compatibility, maintenance burden, community standard |
| Monitor-agnostic? | Yes — runtime detection | Single download for all users, broader audience |
| Activation threshold? | 2.4:1 (configurable) | Excludes 21:9 by default (which mostly works), catches 32:9 and wider |
| Cockpit HUD approach? | Static XML, conservative center values | No runtime API for 3D HUD repositioning; single preset works across range |
| Clamp target? | 16:9 (configurable) | Center-screen experience matches what devs designed for |
| Publishing platform? | Nexus Mods (primary), Workshop (later) | Fewer packaging headaches, larger modding audience |
| Inert at 16:9? | Yes — zero overhead | Safe for anyone to install; trimon.isActive() returns false immediately |
