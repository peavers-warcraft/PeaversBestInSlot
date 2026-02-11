local addonName, PBS = ...

local PeaversCommons = _G.PeaversCommons
local ConfigManager = PeaversCommons.ConfigManager

local Config = ConfigManager:New(addonName, {
    enabled = true,
    debugMode = false,

    -- Content type preference
    contentType = "both",           -- "both", "raid", or "dungeon" (which BiS list to show)
    dataSource = nil,               -- nil = all sources, "archon" for specific

    -- Display options
    showOtherSpecs = false,         -- Show if item is BiS for other specs
    maxOtherSpecs = 3,              -- Max other specs to show
    showDropSource = true,          -- Show where the item drops from
    showPriority = true,            -- Show priority indicator (BiS vs Alt)
    compactMode = false,            -- Use shorter text
})

PBS.Config = Config

return Config
