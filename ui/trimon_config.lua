-- trimon_config.lua
-- X4 Widescreen UI Fix — user configuration
-- Loaded immediately after trimon_utils.lua. Overrides trimon.config defaults.
--
-- To change a setting: uncomment the line and edit the value.
-- Restart the game after saving changes.

if not trimon then
    DebugError("TriMon: trimon_utils.lua not loaded — check ui.xml file ordering")
    return
end

-- ============================================================
-- OVERRIDE DEFAULTS HERE
-- ============================================================

-- Master enable/disable switch.
-- trimon.config.enabled = true

-- Aspect ratio above which the mod activates (default: 2.4).
-- 2560x1080 = 2.37:1 and 3440x1440 = 2.39:1 — both below 2.4, so vanilla 21:9 is unaffected.
-- Lower to 2.0 to also correct 21:9 menus. Raise to 3.5 for triple-monitor-only.
-- trimon.config.activationThreshold = 2.4

-- The aspect ratio menus are clamped to (default: 16/9 = 1.778).
-- Change to 2.39 to display menus across a 21:9 center region instead of 16:9.
-- trimon.config.targetAspect = 16 / 9

-- Per-menu toggles — set to false to leave a specific menu unmodified.
-- trimon.config.menus.map             = true
-- trimon.config.menus.detailmonitor   = true
-- trimon.config.menus.interactmenu    = true
-- trimon.config.menus.shipconfig      = true
-- trimon.config.menus.stationoverview = true
-- trimon.config.menus.missionoffer    = true
-- trimon.config.menus.trademenu       = true
-- trimon.config.menus.gameoptions     = true
-- trimon.config.menus.encyclopedia    = true
-- trimon.config.menus.toplevel        = true

-- ============================================================
-- PHASE 6: EXTENSION OPTIONS INTEGRATION (NOT YET IMPLEMENTED)
-- ============================================================
-- X4's in-game Extension Options system will replace manual edits to this file.
-- Implementation requires:
--   1. An MD script (md/trimon_setup.xml) to register option definitions and persist values.
--   2. UIX option-change callbacks to read saved values and apply them to trimon.config.
--   3. Calls to trimon.resetCache() if activationThreshold changes at runtime.
-- Reference: kuertee_ui_extensions sample mod + MD cue documentation.
