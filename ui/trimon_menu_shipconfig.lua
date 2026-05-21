-- trimon_menu_shipconfig.lua
-- X4 Widescreen UI Fix — Ship Configuration menu layout corrections
--
-- Multi-panel layout with equipment slots, loadout columns, and mod slots.
-- Width clamping on the outer frame plus column-width adjustments inside.
--
-- TODO(Phase 3): Decompile kuertee_menu_ship_configuration.xpl with unluac.
-- Focus audit on: outer frame width, column layout, equipment slot grid.

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
    if not trimon.isMenuActive("shipconfig") then return end

    -- TODO(Phase 3): Verify the registered menu name and registerCallback() API shape.
    local ShipConfig = Menus.Find("ShipConfig")  -- TODO(Phase 3): confirm name
    if not ShipConfig then
        DebugError("TriMon: ShipConfig not found — verify menu name and UIX installation")
        return
    end

    -- TODO(Phase 3): Register callbacks after auditing kuertee_menu_ship_configuration.xpl.
    -- Expected: hook at outer frame width assignment; possibly at column layout.
    -- ShipConfig.registerCallback("...", ModLua.onFrameWidth, "trimon_fix")
end

function ModLua.onFrameWidth(frameProps)
    frameProps.width = trimon.clampWidth(frameProps.width)
    frameProps.x = trimon.getCenterOffsetX()
    return frameProps
end

ModLua.init()
