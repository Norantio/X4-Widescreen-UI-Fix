-- trimon_menu_interactmenu.lua
-- X4 Widescreen UI Fix — Interact Menu layout corrections
--
-- The interact menu is a context popup (right-click / default action menu).
-- Primary issue: anchored to screen center at 16:9 coordinates, so it appears
-- off-center at wide aspect ratios. Needs X/Y position clamping more than
-- width adjustment.
--
-- TODO(Phase 3): Decompile kuertee_menu_interactmenu.xpl with unluac.
-- Focus audit on: popup position calculation, frame anchor point.

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
    if not trimon.isMenuActive("interactmenu") then return end

    -- TODO(Phase 3): Verify the registered menu name and registerCallback() API shape.
    local InteractMenu = Menus.Find("InteractMenu")  -- TODO(Phase 3): confirm name
    if not InteractMenu then
        DebugError("TriMon: InteractMenu not found — verify menu name and UIX installation")
        return
    end

    -- TODO(Phase 3): Register callbacks after auditing kuertee_menu_interactmenu.xpl.
    -- Expected: a hook at popup position/anchor calculation.
    -- InteractMenu.registerCallback("...", ModLua.onPopupPosition, "trimon_fix")
end

-- Clamp popup X position into the active viewport region.
function ModLua.onPopupPosition(props)
    local offset = trimon.getCenterOffsetX()
    local effective = trimon.getEffectiveWidth()
    if props.x then
        -- Remap x from full-viewport space to clamped region
        props.x = math.max(offset, math.min(props.x, offset + effective))
    end
    return props
end

ModLua.init()
