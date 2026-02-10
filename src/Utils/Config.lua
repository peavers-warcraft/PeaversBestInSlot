local addonName, PBS = ...

local PeaversCommons = _G.PeaversCommons
local ConfigManager = PeaversCommons.ConfigManager

local Config = ConfigManager:New(addonName, {
    enabled = true,
    debugMode = false,

    -- Content type preference
    contentType = "both",           -- "both", "raid", or "dungeon" (which BiS list to show)
    dataSource = nil,               -- nil = all sources, "archon" for specific

    -- Source filtering (where items drop from)
    showRaidDrops = true,           -- Show items that drop from raids
    showDungeonDrops = true,        -- Show items that drop from M+ dungeons
    showCraftedItems = true,        -- Show crafted/catalyst items

    -- Display options
    showOtherSpecs = false,         -- Show if item is BiS for other specs
    maxOtherSpecs = 3,              -- Max other specs to show
    showDropSource = true,          -- Show where the item drops from
    showPriority = true,            -- Show priority indicator (BiS vs Alt)
    compactMode = false,            -- Use shorter text
})

PBS.Config = Config

return Config
