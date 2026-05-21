-- trimon_utils.lua
-- X4 Widescreen UI Fix — shared utility module
-- Dynamically detects viewport geometry and provides layout clamping helpers.
-- Completely inert at standard aspect ratios (16:9, 16:10, 21:9).
--
-- This file MUST be first in ui/ui.xml. It sets _G.trimon so every
-- subsequent file can access it as a plain global.

local trimon = {}

-- ============================================================
-- USER-CONFIGURABLE (overridden by trimon_config.lua / Extension Options)
-- ============================================================

trimon.config = {
    enabled = true,

    -- Aspect ratio above which the mod activates.
    -- 2.4 ≈ wider than 21:9 (2560×1080 = 2.37:1, 3440×1440 = 2.39:1).
    -- Set lower (e.g. 2.0) to also fix 21:9, or higher (e.g. 3.5) for triple-only.
    activationThreshold = 2.4,

    -- Target aspect ratio for UI clamping.
    -- 16/9 = 1.778 (default). Set to 2.39 to clamp menus to a 21:9 center region.
    targetAspect = 16 / 9,

    -- Per-menu enable/disable flags (all true by default).
    menus = {
        map             = true,
        detailmonitor   = true,
        interactmenu    = true,
        shipconfig      = true,
        stationoverview = true,
        missionoffer    = true,
        trademenu       = true,
        gameoptions     = true,
        encyclopedia    = true,
        toplevel        = true,
    }
}

-- ============================================================
-- RUNTIME DETECTION
-- ============================================================

-- Cache ONLY physical screen dimensions (won't change mid-session).
-- Classification (isStandard, isUltrawide, isTriple) is recomputed each call so
-- changes to trimon.config.activationThreshold (via Extension Options) take effect
-- immediately without needing resetCache().
--
-- ⚠ API NAMES: Verify against your game version before shipping.
-- Common alternatives to try if these return nil:
--   C.GetScreenWidth() / C.GetScreenHeight()  (C FFI table)
--   GetScreenWidth() / GetScreenHeight()
local _dimsCache = nil

local function _getDims()
    if _dimsCache then return _dimsCache end
    -- Defensive fallback: wrong API name → 1920×1080 (16:9) instead of nil crash.
    -- Mod stays inert and logs a warning until the correct name is confirmed.
    local w = (GetScreenSizeX and GetScreenSizeX())
           or (C and C.GetScreenWidth and C.GetScreenWidth())
           or 1920
    local h = (GetScreenSizeY and GetScreenSizeY())
           or (C and C.GetScreenHeight and C.GetScreenHeight())
           or 1080
    if w == 1920 and h == 1080 then
        DebugError("TriMon WARNING: screen size API returned nil — verify GetScreenSizeX/Y names")
    end
    _dimsCache = { width = w, height = h, aspect = w / h }
    return _dimsCache
end

function trimon.getScreenInfo()
    local dims = _getDims()
    local t = trimon.config.activationThreshold
    local info = {
        width       = dims.width,
        height      = dims.height,
        aspect      = dims.aspect,
        isStandard  = (dims.aspect <= t),
        isUltrawide = (dims.aspect > t and dims.aspect <= 3.6),
        isTriple    = (dims.aspect > 3.6),
        label       = "standard",
    }
    if info.isTriple    then info.label = "triple"
    elseif info.isUltrawide then info.label = "ultrawide+" end
    return info
end

-- Invalidate dims cache (only needed if resolution changes mid-session — very unlikely).
-- Note: changing trimon.config.activationThreshold does NOT require resetCache().
function trimon.resetCache()
    _dimsCache = nil
end

-- ============================================================
-- LAYOUT CLAMPING
-- ============================================================

-- Returns the width in pixels of the target aspect ratio region centered on the viewport.
-- e.g. at 7680×1440 with targetAspect 16:9 → 2560 (one monitor's worth).
function trimon.getEffectiveWidth()
    local info = trimon.getScreenInfo()
    if info.isStandard then return info.width end
    local maxWidth = math.floor(info.height * trimon.config.targetAspect)
    return math.min(info.width, maxWidth)
end

-- Returns the X offset (pixels) to center a clamped element on the full viewport.
-- e.g. at 7680×1440 → (7680 - 2560) / 2 = 2560.
function trimon.getCenterOffsetX()
    local info = trimon.getScreenInfo()
    local effective = trimon.getEffectiveWidth()
    return math.floor((info.width - effective) / 2)
end

-- Scale a value computed relative to full screen width down to the effective width.
function trimon.scaleWidth(value)
    local info = trimon.getScreenInfo()
    if info.isStandard then return value end
    local effective = trimon.getEffectiveWidth()
    return value * (effective / info.width)
end

-- Clamp a requested width to the effective region.
function trimon.clampWidth(requestedWidth)
    local effective = trimon.getEffectiveWidth()
    return math.min(requestedWidth, effective)
end

-- Master check: should the mod do anything at all?
function trimon.isActive()
    if not trimon.config.enabled then return false end
    return not trimon.getScreenInfo().isStandard
end

-- Per-menu check. Returns false at standard aspect ratios or if the menu is disabled.
function trimon.isMenuActive(menuName)
    if not trimon.isActive() then return false end
    if trimon.config.menus[menuName] == nil then return true end  -- default: on
    return trimon.config.menus[menuName]
end

-- ============================================================
-- DEBUG / INFO
-- ============================================================

function trimon.getDebugString()
    local info = trimon.getScreenInfo()
    return string.format(
        "TriMon: %dx%d (%.2f:1) [%s] active=%s effective=%d offset=%d",
        info.width, info.height, info.aspect, info.label,
        tostring(trimon.isActive()),
        trimon.getEffectiveWidth(),
        trimon.getCenterOffsetX()
    )
end

-- ============================================================
-- GLOBAL EXPORT
-- ============================================================

-- Expose as a global so per-menu files can access it directly.
-- X4's Lua environment loads all ui.xml <file> entries into a shared namespace,
-- so _G.trimon is visible in every file declared after this one in ui.xml.
-- require() with extension-relative paths is NOT supported in X4's Lua sandbox.
_G.trimon = trimon
return trimon  -- kept for forward-compat; not relied upon
