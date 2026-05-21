-- trimon_menu_toplevel.lua
-- X4 Widescreen UI Fix — Top-level / persistent HUD overlay corrections
--
-- NOTE ON SCOPE: This file targets the persistent Lua-driven HUD overlay managed
-- by UIX's toplevel layer (universe clock, notification toasts, context-sensitive
-- prompts, etc.). It is SEPARATE from the cockpit HUD panels (event monitor,
-- radar, message ticker) which are handled in Phase 2 via XML diff patches in
-- assets/cockpits/.
--
-- If UIX does not expose a toplevel hook, this file may be a no-op and the
-- relevant fixes instead belong in Phase 2.
--
-- TODO(Phase 3): Determine whether UIX's kuertee_toplevel.xpl (or equivalent)
-- exposes callback hooks for persistent overlay element positioning.
-- If not, coordinate with kuertee or note as known limitation.

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
    if not trimon.isMenuActive("toplevel") then return end

    -- TODO(Phase 3): Determine if UIX exposes a toplevel/HUD overlay menu handle.
    -- The toplevel layer may use a different registration mechanism than per-menu callbacks.
    -- local TopLevel = Menus.Find("TopLevel")  -- existence unconfirmed
    -- If no hook is available, document as known limitation.
    DebugError("TriMon: toplevel stub loaded — Phase 3 required to implement")
end

ModLua.init()
