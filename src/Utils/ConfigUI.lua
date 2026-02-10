local addonName, PBS = ...

local ConfigUI = {}
PBS.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

function ConfigUI:InitializeOptions()
    local panel = PeaversCommons.ConfigUIUtils.CreateSettingsPanel(
        "Settings",
        "Configuration options for PeaversBestInSlot"
    )

    local content = panel.content
    local yPos = panel.yPos
    local baseSpacing = panel.baseSpacing
    local sectionSpacing = panel.sectionSpacing

    yPos = self:CreateGeneralOptions(content, yPos, baseSpacing, sectionSpacing)
    yPos = self:CreateSourceFilterOptions(content, yPos, baseSpacing, sectionSpacing)
    yPos = self:CreateDisplayOptions(content, yPos, baseSpacing, sectionSpacing)
    yPos = self:CreateDataOptions(content, yPos, baseSpacing, sectionSpacing)

    panel:UpdateContentHeight(yPos)

    return panel
end

function ConfigUI:CreateGeneralOptions(content, yPos, baseSpacing, sectionSpacing)
    local controlIndent = baseSpacing + 15

    local header, newY = PeaversCommons.ConfigUIUtils.CreateSectionHeader(content, "General Settings", baseSpacing, yPos)
    yPos = newY - 10

    local _, newY = PeaversCommons.ConfigUIUtils.CreateCheckbox(
        content,
        "PBSEnabledCheckbox",
        "Enable BiS tooltips",
        controlIndent, yPos,
        PBS.Config.enabled,
        function(checked)
            PBS.Config.enabled = checked
            PBS.Config:Save()
        end
    )
    yPos = newY - 8

    -- Content type dropdown
    local contentTypes = {
        raid = "Raid BiS",
        dungeon = "Mythic+ BiS"
    }

    local contentContainer, contentDropdown = PeaversCommons.ConfigUIUtils.CreateDropdown(
        content, "PBSContentTypeDropdown",
        "Content Type", contentTypes,
        contentTypes[PBS.Config.contentType] or "Raid BiS", 400,
        function(value)
            PBS.Config.contentType = value
            PBS.Config:Save()
        end
    )
    contentContainer:SetPoint("TOPLEFT", controlIndent, yPos)
    yPos = yPos - 65

    local _, newY = PeaversCommons.ConfigUIUtils.CreateCheckbox(
        content,
        "PBSDebugCheckbox",
        "Enable debug messages",
        controlIndent, yPos,
        PBS.Config.debugMode,
        function(checked)
            PBS.Config.debugMode = checked
            PBS.Config.DEBUG_ENABLED = checked
            PBS.Config:Save()
        end
    )
    yPos = newY - 15

    return yPos
end

function ConfigUI:CreateSourceFilterOptions(content, yPos, baseSpacing, sectionSpacing)
    local controlIndent = baseSpacing + 15

    local _, newY = PeaversCommons.ConfigUIUtils.CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15

    local header, newY = PeaversCommons.ConfigUIUtils.CreateSectionHeader(content, "Item Source Filter", baseSpacing, yPos)
    yPos = newY - 5

    local infoText = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", controlIndent, yPos)
    infoText:SetText("Filter BiS items by where they drop from:")
    infoText:SetTextColor(0.7, 0.7, 0.7)
    yPos = yPos - 18

    local _, newY = PeaversCommons.ConfigUIUtils.CreateCheckbox(
        content,
        "PBSShowRaidDropsCheckbox",
        "Show items from Raids",
        controlIndent, yPos,
        PBS.Config.showRaidDrops,
        function(checked)
            PBS.Config.showRaidDrops = checked
            PBS.Config:Save()
        end
    )
    yPos = newY - 8

    local _, newY = PeaversCommons.ConfigUIUtils.CreateCheckbox(
        content,
        "PBSShowDungeonDropsCheckbox",
        "Show items from Mythic+ Dungeons",
        controlIndent, yPos,
        PBS.Config.showDungeonDrops,
        function(checked)
            PBS.Config.showDungeonDrops = checked
            PBS.Config:Save()
        end
    )
    yPos = newY - 8

    local _, newY = PeaversCommons.ConfigUIUtils.CreateCheckbox(
        content,
        "PBSShowCraftedCheckbox",
        "Show Crafted / Catalyst items",
        controlIndent, yPos,
        PBS.Config.showCraftedItems,
        function(checked)
            PBS.Config.showCraftedItems = checked
            PBS.Config:Save()
        end
    )
    yPos = newY - 15

    return yPos
end

function ConfigUI:CreateDisplayOptions(content, yPos, baseSpacing, sectionSpacing)
    local controlIndent = baseSpacing + 15

    local _, newY = PeaversCommons.ConfigUIUtils.CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15

    local header, newY = PeaversCommons.ConfigUIUtils.CreateSectionHeader(content, "Display Options", baseSpacing, yPos)
    yPos = newY - 10

    local _, newY = PeaversCommons.ConfigUIUtils.CreateCheckbox(
        content,
        "PBSShowDropSourceCheckbox",
        "Show drop source (boss/dungeon name)",
        controlIndent, yPos,
        PBS.Config.showDropSource,
        function(checked)
            PBS.Config.showDropSource = checked
            PBS.Config:Save()
        end
    )
    yPos = newY - 8

    local _, newY = PeaversCommons.ConfigUIUtils.CreateCheckbox(
        content,
        "PBSShowPriorityCheckbox",
        "Show priority indicator (BiS vs Alternative)",
        controlIndent, yPos,
        PBS.Config.showPriority,
        function(checked)
            PBS.Config.showPriority = checked
            PBS.Config:Save()
        end
    )
    yPos = newY - 8

    local _, newY = PeaversCommons.ConfigUIUtils.CreateCheckbox(
        content,
        "PBSShowOtherSpecsCheckbox",
        "Show if item is BiS for other specs",
        controlIndent, yPos,
        PBS.Config.showOtherSpecs,
        function(checked)
            PBS.Config.showOtherSpecs = checked
            PBS.Config:Save()
        end
    )
    yPos = newY - 8

    local _, newY = PeaversCommons.ConfigUIUtils.CreateCheckbox(
        content,
        "PBSCompactModeCheckbox",
        "Compact mode (shorter text)",
        controlIndent, yPos,
        PBS.Config.compactMode,
        function(checked)
            PBS.Config.compactMode = checked
            PBS.Config:Save()
        end
    )
    yPos = newY - 15

    return yPos
end

function ConfigUI:CreateDataOptions(content, yPos, baseSpacing, sectionSpacing)
    local controlIndent = baseSpacing + 15

    local _, newY = PeaversCommons.ConfigUIUtils.CreateSeparator(content, baseSpacing, yPos)
    yPos = newY - 15

    local header, newY = PeaversCommons.ConfigUIUtils.CreateSectionHeader(content, "Data Source", baseSpacing, yPos)
    yPos = newY - 10

    -- Check if PeaversBestInSlotData is available
    local BiSData = _G.PeaversBestInSlotData
    if BiSData and BiSData.API then
        local updates = BiSData.API.GetLastUpdate()

        if updates then
            for source, contentTypes in pairs(updates) do
                local sourceLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                sourceLabel:SetPoint("TOPLEFT", controlIndent, yPos)
                sourceLabel:SetText(source:sub(1, 1):upper() .. source:sub(2) .. ":")
                sourceLabel:SetTextColor(1, 0.82, 0)

                local updateText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                updateText:SetPoint("TOPLEFT", sourceLabel, "TOPRIGHT", 10, 0)

                local updateTimes = {}
                for contentType, timestamp in pairs(contentTypes) do
                    if timestamp then
                        table.insert(updateTimes, contentType .. ": " .. timestamp)
                    end
                end
                updateText:SetText(table.concat(updateTimes, ", "))

                yPos = yPos - 20
            end
        end
    else
        local errorText = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        errorText:SetPoint("TOPLEFT", controlIndent, yPos)
        errorText:SetText("PeaversBestInSlotData not available")
        errorText:SetTextColor(1, 0, 0)
        yPos = yPos - 20
    end

    yPos = yPos - 15

    return yPos
end

function ConfigUI:Initialize()
    self.panel = self:InitializeOptions()
end

function ConfigUI:Open()
    if Settings then
        Settings.OpenToCategory(addonName)
    end
end

return ConfigUI
