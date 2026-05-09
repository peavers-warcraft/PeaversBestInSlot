--------------------------------------------------------------------------------
-- PeaversBestInSlot Configuration
-- Uses PeaversCommons.ConfigManager with AceDB-3.0 for profile management
--------------------------------------------------------------------------------

local addonName, PBS = ...

local PeaversCommons = _G.PeaversCommons
local ConfigManager = PeaversCommons.ConfigManager

local PBS_DEFAULTS = {
    enabled = true,
    debugMode = false,
    contentType = "both",
    dataSource = nil,
    showOtherSpecs = false,
    maxOtherSpecs = 3,
    showDropSource = true,
    showPriority = true,
    compactMode = false,
}

-- Create the AceDB-backed config
PBS.Config = ConfigManager:NewWithAceDB(
    PBS,
    PBS_DEFAULTS,
    {
        savedVariablesName = "PeaversBestInSlotDB",
        profileType = "shared",
    }
)

return PBS.Config
