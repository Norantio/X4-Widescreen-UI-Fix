-- trimon_menu_gameoptions.lua
-- X4 Widescreen UI Fix — Game Options / Settings menu layout corrections
--
-- Full-screen settings overlay. Low complexity — primarily needs centering
-- and outer frame width clamping. Individual option rows are fixed-width.
--
-- TODO(Phase 3): Decompile kuertee_menu_gameoptions.xpl with unluac.
-- Focus audit on: outer frame width and X anchor.

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
    if not trimon.isMenuActive("gameoptions") then return end

    -- TODO(Phase 3): Verify the registered menu name and registerCallback() API shape.
    local GameOptions = Menus.Find("GameOptions")  -- TODO(Phase 3): confirm name
    if not GameOptions then
        DebugError("TriMon: GameOptions not found — verify menu name and UIX installation")
        return
    end

    -- TODO(Phase 3): Register callback after auditing kuertee_menu_gameoptions.xpl.
    -- GameOptions.registerCallback("...", ModLua.onFrameWidth, "trimon_fix")
end

function ModLua.onFrameWidth(frameProps)
    frameProps.width = trimon.clampWidth(frameProps.width)
    frameProps.x = trimon.getCenterOffsetX()
    return frameProps
end

ModLua.init()
