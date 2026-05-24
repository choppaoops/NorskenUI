---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("WayFinder: Addon object not initialized. Check file load order!")
    return
end

---@class WayFinder: AceModule, AceEvent-3.0
local WF = NorskenUI:NewModule("WayFinder", "AceEvent-3.0")

function WF:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.WayFinder
end

function WF:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function WF:OnEnable()
    if not self.db.Enabled then return end
    self:RegisterSlashCommands()
end

function WF:OnDisable()
    self:UnregisterSlashCommands()
end

function WF:RegisterSlashCommands()
    SLASH_NRSKNWAY1 = "/way"
    SlashCmdList["NRSKNWAY"] = function(msg)
        self:HandleWayCommand(msg)
    end
end

function WF:UnregisterSlashCommands()
    SLASH_NRSKNWAY1 = nil
    SlashCmdList["NRSKNWAY"] = nil
end

---@param msg string
function WF:HandleWayCommand(msg)
    local x, y = msg:match("^(%d+%.?%d*)%s+(%d+%.?%d*)$")

    if not x or not y then
        NRSKNUI:Print("Usage: /way <x> <y>")
        return
    end

    x = tonumber(x) / 100
    y = tonumber(y) / 100

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        NRSKNUI:Print("Could not determine current map.")
        return
    end

    local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)

    C_Map.SetUserWaypoint(point)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)

    NRSKNUI:Print(string.format("Waypoint set to %.1f, %.1f", x * 100, y * 100))
end
