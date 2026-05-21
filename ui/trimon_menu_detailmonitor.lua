-- trimon_menu_detailmonitor.lua
-- X4 Widescreen UI Fix — Detail Monitor layout corrections
--
-- The detail monitor is the always-visible side panel (ship/station status, property).
-- Width computation is relatively self-contained — likely 1-2 callbacks needed.
--
-- TODO(Phase 3): Decompile kuertee_menu_detailmonitor.xpl with unluac.
-- Focus audit on: frame construction, panel width assignment.

if not trimon then
    DebugError("TriMon: trimon_utils.lua not loaded — check ui.xml file ordering")
    return
end

if not Menus then
    DebugError("TriMon: Menus global not available — is UIX loaded?")
    return
end

local ModLua = {}

function ModLua.init()
    if not trimon.isMenuActive("detailmonitor") then return end

    -- TODO(Phase 3): Verify the registered menu name and registerCallback() API shape.
    local DetailMonitor = Menus.Find("DetailMonitor")  -- TODO(Phase 3): confirm name
    if not DetailMonitor then
        DebugError("TriMon: DetailMonitor not found — verify menu name and UIX installation")
        return
    end

    -- TODO(Phase 3): Register callbacks after auditing kuertee_menu_detailmonitor.xpl.
    -- Expected: a hook at frame width assignment and possibly at panel layout.
    -- DetailMonitor.registerCallback("...", ModLua.onFrameWidth, "trimon_fix")
end

function ModLua.onFrameWidth(frameProps)
    frameProps.width = trimon.clampWidth(frameProps.width)
    frameProps.x = trimon.getCenterOffsetX()
    return frameProps
end

ModLua.init()
