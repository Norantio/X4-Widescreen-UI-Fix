-- trimon_menu_stationoverview.lua
-- X4 Widescreen UI Fix — Station Overview (Builder) menu layout corrections
--
-- Complex interface: plan view, module list, budget panel, construction queue.
-- Multiple nested frames — expect the highest callback count of any P1 menu.
-- The plan view (2D blueprint canvas) may have its own coordinate system to handle.
--
-- TODO(Phase 3): Decompile kuertee_menu_station_overview.xpl with unluac.
-- Focus audit on: outer frame, plan canvas dimensions, side panel widths.

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
    if not trimon.isMenuActive("stationoverview") then return end

    -- TODO(Phase 3): Verify the registered menu name and registerCallback() API shape.
    local StationOverview = Menus.Find("StationOverview")  -- TODO(Phase 3): confirm name
    if not StationOverview then
        DebugError("TriMon: StationOverview not found — verify menu name and UIX installation")
        return
    end

    -- TODO(Phase 3): Register callbacks after auditing kuertee_menu_station_overview.xpl.
    -- Expected: hooks at outer frame, plan canvas, and side panel construction.
    -- StationOverview.registerCallback("...", ModLua.onFrameWidth, "trimon_fix")
end

function ModLua.onFrameWidth(frameProps)
    frameProps.width = trimon.clampWidth(frameProps.width)
    frameProps.x = trimon.getCenterOffsetX()
    return frameProps
end

ModLua.init()
