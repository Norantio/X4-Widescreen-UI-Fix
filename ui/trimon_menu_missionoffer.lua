-- trimon_menu_missionoffer.lua
-- X4 Widescreen UI Fix — Mission Offer / Briefing overlay corrections
--
-- Simple overlay panel (mission description, rewards, accept/decline).
-- Primary fix: center the panel on the active viewport region.
-- Low complexity — likely a single callback at frame construction.
--
-- TODO(Phase 3): Decompile kuertee_menu_missionoffer.xpl with unluac.
-- Focus audit on: frame X/Y anchor, frame width.

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
    if not trimon.isMenuActive("missionoffer") then return end

    -- TODO(Phase 3): Verify the registered menu name and registerCallback() API shape.
    local MissionOffer = Menus.Find("MissionOffer")  -- TODO(Phase 3): confirm name
    if not MissionOffer then
        DebugError("TriMon: MissionOffer not found — verify menu name and UIX installation")
        return
    end

    -- TODO(Phase 3): Register callback after auditing kuertee_menu_missionoffer.xpl.
    -- MissionOffer.registerCallback("...", ModLua.onFrameCreate, "trimon_fix")
end

function ModLua.onFrameCreate(frameProps)
    -- Center the panel within the active viewport region
    frameProps.x = trimon.getCenterOffsetX() + math.floor((trimon.getEffectiveWidth() - (frameProps.width or 0)) / 2)
    return frameProps
end

ModLua.init()
