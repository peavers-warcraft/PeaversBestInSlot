local addonName, PBS = ...

local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

PBS = PBS or {}
PBS.name = addonName
PBS.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-- Register slash commands
PeaversCommons.SlashCommands:Register(addonName, "pbs", {
    default = function()
        PBS.ConfigUI:Open()
    end,
    toggle = function()
        PBS.Config.enabled = not PBS.Config.enabled
        PBS.Config:Save()
        Utils.Print(PBS, "Tooltips " .. (PBS.Config.enabled and "enabled" or "disabled"))
    end,
    config = function()
        PBS.ConfigUI:Open()
    end,
    help = function()
        Utils.Print(PBS, "Commands:")
        print("  /pbs - Open configuration")
        print("  /pbs toggle - Toggle tooltips")
    end
})

-- Additional slash command
PeaversCommons.SlashCommands:Register(addonName, "bestinslot", {
    default = function()
        PBS.ConfigUI:Open()
    end
})

-- Initialize the addon
PeaversCommons.Events:Init(addonName, function()
    PBS.Config:Initialize()
    PBS.ConfigUI:Initialize()
    PBS.TooltipHook:Initialize()

    C_Timer.After(0.5, function()
        PeaversCommons.SettingsUI:CreateRedirectPage(PBS, "PeaversBestInSlot", "Peavers Best In Slot")
    end)
    -- Register with PeaversConfig registry
    if PeaversCommons.ConfigRegistry then
        PeaversCommons.ConfigRegistry:Register({
            name = "PeaversBestInSlot",
            displayName = "Best In Slot",
            description = "BiS gear information in item tooltips",
            addonRef = PBS,
            config = PBS.Config,
            pages = PBS.ConfigUI:GetPages(),
            order = 8,
        })
    end
end, {
    suppressAnnouncement = true
})

-- Export addon table
_G.PeaversBestInSlot = PBS

return PBS
