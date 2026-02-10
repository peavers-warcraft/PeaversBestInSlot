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
    debug = function()
        PBS.Config.debugMode = not PBS.Config.debugMode
        PBS.Config.DEBUG_ENABLED = PBS.Config.debugMode
        PBS.Config:Save()
        Utils.Print(PBS, "Debug mode " .. (PBS.Config.debugMode and "enabled" or "disabled"))
    end,
    raid = function()
        PBS.Config.contentType = "raid"
        PBS.Config:Save()
        Utils.Print(PBS, "Now showing Raid BiS")
    end,
    dungeon = function()
        PBS.Config.contentType = "dungeon"
        PBS.Config:Save()
        Utils.Print(PBS, "Now showing Mythic+ BiS")
    end,
    toggle = function()
        PBS.Config.enabled = not PBS.Config.enabled
        PBS.Config:Save()
        Utils.Print(PBS, "BiS tooltips " .. (PBS.Config.enabled and "enabled" or "disabled"))
    end,
    raidonly = function()
        PBS.Config.showRaidDrops = true
        PBS.Config.showDungeonDrops = false
        PBS.Config.showCraftedItems = true
        PBS.Config:Save()
        Utils.Print(PBS, "Showing only Raid + Crafted items")
    end,
    dungeononly = function()
        PBS.Config.showRaidDrops = false
        PBS.Config.showDungeonDrops = true
        PBS.Config.showCraftedItems = true
        PBS.Config:Save()
        Utils.Print(PBS, "Showing only M+ + Crafted items")
    end,
    all = function()
        PBS.Config.showRaidDrops = true
        PBS.Config.showDungeonDrops = true
        PBS.Config.showCraftedItems = true
        PBS.Config:Save()
        Utils.Print(PBS, "Showing all item sources")
    end,
    config = function()
        PBS.ConfigUI:Open()
    end,
    help = function()
        Utils.Print(PBS, "Commands:")
        print("  /pbs - Open configuration")
        print("  /pbs raid - Switch to Raid BiS list")
        print("  /pbs dungeon - Switch to M+ BiS list")
        print("  /pbs raidonly - Show only raid drops")
        print("  /pbs dungeononly - Show only M+ drops")
        print("  /pbs all - Show all item sources")
        print("  /pbs toggle - Toggle BiS tooltips")
        print("  /pbs debug - Toggle debug mode")
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
            "Shows Best in Slot gear information in item tooltips. Use [R] for raid drops, [M+] for dungeon drops, [C] for crafted items.",
            {
                "/pbs - Open configuration",
                "/pbs raid - Show Raid BiS list",
                "/pbs dungeon - Show M+ BiS list",
                "/pbs raidonly - Filter to raid drops only",
                "/pbs dungeononly - Filter to M+ drops only",
                "/pbs all - Show all item sources"
            }
        )
    end)

    Utils.Print(PBS, "Loaded - Use /pbs for options")
end, {
    suppressAnnouncement = true
})

-- Export addon table
_G.PeaversBestInSlot = PBS

return PBS
