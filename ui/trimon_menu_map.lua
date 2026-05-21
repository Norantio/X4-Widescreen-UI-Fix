-- trimon_menu_map.lua
-- X4 Widescreen UI Fix — Map Menu layout corrections
--
-- The map menu is the most complex menu in the game: multiple nested frames,
-- dynamic resizing, and side info panels. Expect multiple callback registrations
-- and the most Phase 3 audit work of any single menu.
--
-- TODO(Phase 3): Decompile kuertee_menu_map.xpl with unluac and audit all
-- callback insertion points. Focus on:
--   - createMainFrame() — where frameWidth is set from GetScreenSizeX()
--   - createInfoFrame() / createInfoContent() — side panel width
--   - Any dynamic resize handlers

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
    if not trimon.isMenuActive("map") then return end

    -- TODO(Phase 3): Verify the registered menu name. Search kuertee_menu_map.xpl
    -- (decompiled) for the string passed to Menus.Add() or equivalent.
    -- Also verify registerCallback() is the correct API — UIX may use a different
    -- call such as: kuertee_ui_extensions.addCallback("map", hookName, fn)
    local MapMenu = Menus.Find("MapMenu")  -- TODO(Phase 3): confirm name
    if not MapMenu then
        DebugError("TriMon: MapMenu not found — verify menu name and UIX installation")
        return
    end

    DebugError(trimon.getDebugString())  -- logs resolution info on first access

    -- TODO(Phase 3): Replace placeholder hook names with confirmed names from audit.
    MapMenu.registerCallback(
        "createMainFrame_on_before_set_width",  -- TODO(Phase 3): confirm hook name
        ModLua.onMapFrameWidth,
        "trimon_fix"
    )
    MapMenu.registerCallback(
        "createInfoFrame_on_start",             -- TODO(Phase 3): confirm hook name
        ModLua.onInfoFrameStart,
        "trimon_fix"
    )
end

-- Called before main map frame dimensions are committed.
-- Clamps frame width and re-centers it on the full viewport.
function ModLua.onMapFrameWidth(frameProps)
    frameProps.width = trimon.clampWidth(frameProps.width)
    frameProps.x = trimon.getCenterOffsetX()
    return frameProps
end

-- Called at the start of info frame creation.
-- Adjusts side panel width to fit within the clamped region.
function ModLua.onInfoFrameStart(frame, config)
    if config and config.width then
        config.width = trimon.clampWidth(config.width)
    end
    return frame, config
end

ModLua.init()
