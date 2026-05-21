-- trimon_menu_trademenu.lua
-- X4 Widescreen UI Fix — Trade Menu layout corrections
--
-- Table-based layout (commodity rows, buy/sell columns, price history).
-- Primary fix: clamp the outer frame width. Column widths inside may need
-- proportional scaling if they're computed from the full viewport width.
--
-- TODO(Phase 3): Decompile kuertee_menu_trademenu.xpl with unluac.
-- Focus audit on: outer frame width, column width computation.

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
    if not trimon.isMenuActive("trademenu") then return end

    -- TODO(Phase 3): Verify the registered menu name and registerCallback() API shape.
    local TradeMenu = Menus.Find("TradeMenu")  -- TODO(Phase 3): confirm name
    if not TradeMenu then
        DebugError("TriMon: TradeMenu not found — verify menu name and UIX installation")
        return
    end

    -- TODO(Phase 3): Register callbacks after auditing kuertee_menu_trademenu.xpl.
    -- Expected: hook at outer frame width; possibly at column width computation.
    -- TradeMenu.registerCallback("...", ModLua.onFrameWidth, "trimon_fix")
end

function ModLua.onFrameWidth(frameProps)
    frameProps.width = trimon.clampWidth(frameProps.width)
    frameProps.x = trimon.getCenterOffsetX()
    return frameProps
end

-- Scale a column width that was computed as a fraction of the full screen width.
function ModLua.scaleColumnWidth(colWidth)
    return trimon.scaleWidth(colWidth)
end

ModLua.init()
