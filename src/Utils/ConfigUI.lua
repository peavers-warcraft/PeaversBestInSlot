local addonName, PBS = ...

local ConfigUI = {}
PBS.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
if not PeaversCommons then return end

local W = PeaversCommons.Widgets
local C = W.Colors

local INDENT = 25
local ROW = 26

--- Build a checkbox bound to a boolean field on PBS.Config.
--- Returns the next y cursor first so callers can write `y = ConfigCheckbox(...)`
--- without needing a throwaway variable.
--- @return number nextY
--- @return table checkbox
local function ConfigCheckbox(parent, label, key, y, description)
    local cb = W:CreateCheckbox(parent, label, {
        checked = PBS.Config[key],
        description = description,
        width = 420,
        onChange = function(checked)
            PBS.Config[key] = checked
            PBS.Config:Save()
        end,
    })
    cb:SetPoint("TOPLEFT", INDENT, y)
    return y - (description and ROW + 14 or ROW), cb
end

function ConfigUI:BuildGeneralPage(parentFrame)
    local y = -10

    local _, newY = W:CreateSectionHeader(parentFrame, "General Settings", INDENT, y)
    y = newY - 8

    y = ConfigCheckbox(parentFrame, "Enable BiS tooltips", "enabled", y)

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildDisplayPage(parentFrame)
    local y = -10

    local _, newY = W:CreateSectionHeader(parentFrame, "Display Options", INDENT, y)
    y = newY - 8

    local options = {
        { label = "Show drop source (boss/dungeon name)", key = "showDropSource" },
        { label = "Show priority indicator (BiS vs Alternative)", key = "showPriority" },
        { label = "Show if item is BiS for other specs", key = "showOtherSpecs" },
        { label = "Compact mode (shorter text)", key = "compactMode" },
    }

    for _, opt in ipairs(options) do
        y = ConfigCheckbox(parentFrame, opt.label, opt.key, y)
    end

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildDataPage(parentFrame)
    local y = -10

    local _, newY = W:CreateSectionHeader(parentFrame, "Data Source", INDENT, y)
    y = newY - 8

    local BiSData = _G.PeaversBestInSlotData
    if BiSData and BiSData.API then
        local label = W:CreateLabel(parentFrame, "Last updated", { color = C.textSec })
        label:SetPoint("TOPLEFT", INDENT, y)

        local value = W:CreateLabel(parentFrame,
            BiSData.API.GetLastUpdate() or "no data loaded", { color = C.text })
        value:SetPoint("TOPLEFT", INDENT + 110, y)

        y = y - 22
    else
        local err = W:CreateLabel(parentFrame,
            "PeaversBestInSlotData not available", { color = C.danger })
        err:SetPoint("TOPLEFT", INDENT, y)
        y = y - 22
    end

    parentFrame:SetHeight(math.abs(y) + 30)
end

function ConfigUI:BuildInfoPage(parentFrame)
    PeaversCommons.ConfigUIUtils.BuildInfoPage(parentFrame, "Best In Slot", {
        "Shows Best-in-Slot information directly on item tooltips for your class " ..
            "and spec, including where each piece drops.",
        { command = "/pbs", desc = "open the configuration panel" },
        { command = "/pbs toggle", desc = "turn the tooltip lines on or off" },

        { header = "Reading the tooltip" },
        "Green text marks an item that is your primary Best in Slot; gold text " ..
            "marks a strong alternative. The boss or dungeon it drops from is " ..
            "listed alongside, and optionally which other specs want it.",

        { header = "Where the data comes from" },
        "Rankings ship in the PeaversBestInSlotData companion addon and are " ..
            "refreshed automatically with updates, so the tooltips stay current " ..
            "without any manual imports.",
    })
end

function ConfigUI:GetPages()
    return {
        -- First entry renders leftmost and is the default-selected tab
        { key = "info", label = "Information", builder = function(f) ConfigUI:BuildInfoPage(f) end },
        { key = "general", label = "General", builder = function(f) ConfigUI:BuildGeneralPage(f) end },
        { key = "display", label = "Display", builder = function(f) ConfigUI:BuildDisplayPage(f) end },
        { key = "data", label = "Data", builder = function(f) ConfigUI:BuildDataPage(f) end },
    }
end

-- Legacy single-panel path, kept for the older ConfigRegistry `buildPanel` contract.
function ConfigUI:BuildIntoFrame(parentFrame)
    self:BuildGeneralPage(parentFrame)
    return parentFrame
end

function ConfigUI:Initialize()
end

function ConfigUI:Open()
    -- Prefer PeaversConfig if available
    if _G.PeaversConfig and _G.PeaversConfig.MainFrame then
        _G.PeaversConfig.MainFrame:Show()
        _G.PeaversConfig.MainFrame:SelectAddon("PeaversBestInSlot")
        return
    end

    local addon = _G[addonName]

    if Settings and Settings.OpenToCategory and addon then
        if addon.directSettingsCategoryID then
            local success = pcall(Settings.OpenToCategory, addon.directSettingsCategoryID)
            if success then return end
        end

        if addon.directCategoryID then
            local success = pcall(Settings.OpenToCategory, addon.directCategoryID)
            if success then return end
        end
    end

    if SettingsPanel then
        SettingsPanel:Open()
    end
end

return ConfigUI
