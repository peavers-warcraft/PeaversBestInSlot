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
    raid = function()
        PBS.Config.contentType = "raid"
        PBS.Config:Save()
        Utils.Print(PBS, "Now showing best in slot items for raid content")
    end,
    dungeon = function()
        PBS.Config.contentType = "dungeon"
        PBS.Config:Save()
        Utils.Print(PBS, "Now showing best in slot items for mythic+ content")
    end,
    both = function()
        PBS.Config.contentType = "both"
        PBS.Config:Save()
        Utils.Print(PBS, "Now showing best in slot items for all content")
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
        print("  /pbs raid - Show raid items only")
        print("  /pbs dungeon - Show mythic+ items only")
        print("  /pbs both - Show all items")
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

    -- Create settings pages
    C_Timer.After(0.5, function()
        PeaversCommons.SettingsUI:CreateSettingsPages(
            PBS,
            "PeaversBestInSlot",
            "Peavers Best In Slot",
            "Shows Best in Slot gear information in item tooltips.",
            {
                "/pbs - Open configuration",
                "/pbs raid - Show raid items only",
                "/pbs dungeon - Show mythic+ items only",
                "/pbs both - Show all items"
            }
        )
    end)
end, {
    suppressAnnouncement = true
})

-- Export addon table
_G.PeaversBestInSlot = PBS

return PBS
