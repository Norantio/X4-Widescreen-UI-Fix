-- trimon_menu_encyclopedia.lua
-- X4 Widescreen UI Fix — Encyclopedia menu layout corrections
--
-- Multi-panel reference layout: category list on the left, detail view on the right.
-- Similar structure to the map menu's info panels. Expect width clamping on the outer
-- frame and possibly on the detail panel width.
--
-- TODO(Phase 3): Decompile kuertee_menu_encyclopedia.xpl with unluac.
-- Focus audit on: outer frame width, left-panel / right-panel width split.

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
    if not trimon.isMenuActive("encyclopedia") then return end

    -- TODO(Phase 3): Verify the registered menu name and registerCallback() API shape.
    local Encyclopedia = Menus.Find("Encyclopedia")  -- TODO(Phase 3): confirm name
    if not Encyclopedia then
        DebugError("TriMon: Encyclopedia not found — verify menu name and UIX installation")
        return
    end

    -- TODO(Phase 3): Register callbacks after auditing kuertee_menu_encyclopedia.xpl.
    -- Expected: hook at outer frame width; possibly at detail panel width.
    -- Encyclopedia.registerCallback("...", ModLua.onFrameWidth, "trimon_fix")
end

function ModLua.onFrameWidth(frameProps)
    frameProps.width = trimon.clampWidth(frameProps.width)
    frameProps.x = trimon.getCenterOffsetX()
    return frameProps
end

ModLua.init()
