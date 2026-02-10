local addonName, PBS = ...

local PeaversCommons = _G.PeaversCommons
local Utils = PeaversCommons.Utils

PBS.TooltipHook = {}
local TooltipHook = PBS.TooltipHook

-- Cache for player spec info
local playerClassID = nil
local playerSpecID = nil

-- Color constants
local COLORS = {
    BIS_PRIMARY = {r = 0.0, g = 1.0, b = 0.0},    -- Green for primary BiS
    BIS_ALT = {r = 1.0, g = 0.82, b = 0.0},        -- Gold for alternative
    BIS_OTHER = {r = 0.6, g = 0.6, b = 0.6},       -- Gray for other specs
    LABEL = {r = 1.0, g = 0.82, b = 0.0},          -- Gold for labels
    VALUE = {r = 1.0, g = 1.0, b = 1.0},           -- White for values
    HEADER = {r = 0.5, g = 0.8, b = 1.0},          -- Light blue for section header
}

-- Map character panel slot names to slot IDs
local SLOT_NAME_TO_ID = {
    CharacterHeadSlot = 1,
    CharacterNeckSlot = 2,
    CharacterShoulderSlot = 3,
    CharacterShirtSlot = 4,
    CharacterChestSlot = 5,
    CharacterWaistSlot = 6,
    CharacterLegsSlot = 7,
    CharacterFeetSlot = 8,
    CharacterWristSlot = 9,
    CharacterHandsSlot = 10,
    CharacterFinger0Slot = 11,
    CharacterFinger1Slot = 12,
    CharacterTrinket0Slot = 13,
    CharacterTrinket1Slot = 14,
    CharacterBackSlot = 15,
    CharacterMainHandSlot = 16,
    CharacterSecondaryHandSlot = 17,
}

-- Get player class and spec IDs
local function UpdatePlayerInfo()
    local _, _, classIndex = UnitClass("player")
    playerClassID = classIndex

    local currentSpec = GetSpecialization()
    if currentSpec then
        playerSpecID = GetSpecializationInfo(currentSpec)
    end

    Utils.Debug(PBS, "Player info updated: classID=" .. tostring(playerClassID) .. ", specID=" .. tostring(playerSpecID))
end

-- Get spec name from specID
local function GetSpecName(specID)
    if not specID then return "Unknown" end
    local _, specName = GetSpecializationInfoByID(specID)
    return specName or "Unknown"
end

-- Get class name from classID
local function GetClassName(classID)
    if not classID then return "Unknown" end
    local className = GetClassInfo(classID)
    return className or "Unknown"
end

-- Format the BiS label based on priority and settings
local function FormatBiSLabel(priority, contentType, compact)
    local contentLabel = contentType == "raid" and "Raid" or "M+"

    if compact then
        if priority == 1 then
            return contentLabel .. " BiS"
        else
            return contentLabel .. " Alt"
        end
    else
        if priority == 1 then
            return contentLabel .. " Best in Slot"
        else
            return contentLabel .. " Alternative #" .. priority
        end
    end
end

-- Check if an item's source type passes the filter
local function PassesSourceFilter(sourceType)
    if not sourceType then return true end

    local st = sourceType:lower()

    -- Raid drops
    if st == "raid" then
        return PBS.Config.showRaidDrops
    end

    -- Dungeon drops
    if st == "dungeon" then
        return PBS.Config.showDungeonDrops
    end

    -- Crafted, catalyst, and other sources
    if st == "crafted" or st == "catalyst" or st == "world" or st == "pvp" then
        return PBS.Config.showCraftedItems
    end

    -- Unknown source types - show by default
    return true
end

-- Add BiS info for a specific slot to the tooltip
function TooltipHook:AddSlotBiSInfo(tooltip, slotID)
    if not PBS.Config.enabled then return end

    if not playerClassID or not playerSpecID then
        UpdatePlayerInfo()
    end
    if not playerClassID or not playerSpecID then return end

    -- Get PeaversBestInSlotData API
    local BiSData = _G.PeaversBestInSlotData
    if not BiSData or not BiSData.API then
        Utils.Debug(PBS, "PeaversBestInSlotData not available")
        return
    end

    -- Get BiS items for this slot
    local allItems = BiSData.API.GetBiSForSlot(playerClassID, playerSpecID, slotID, PBS.Config.contentType, PBS.Config.dataSource)

    if not allItems or #allItems == 0 then
        Utils.Debug(PBS, "No BiS data for slot " .. tostring(slotID) .. " (class: " .. playerClassID .. ", spec: " .. playerSpecID .. ")")
        return
    end

    -- Filter items based on source settings
    local items = {}
    for _, item in ipairs(allItems) do
        if PassesSourceFilter(item.sourceType) then
            table.insert(items, item)
        end
    end

    if #items == 0 then
        Utils.Debug(PBS, "No BiS items for slot " .. slotID .. " after source filtering")
        return
    end

    Utils.Debug(PBS, "Adding BiS info for slot " .. slotID .. " - showing " .. #items .. " of " .. #allItems .. " items")

    -- Add separator
    tooltip:AddLine(" ")

    -- Add header
    local contentLabel = PBS.Config.contentType == "raid" and "Raid" or "M+"
    tooltip:AddLine(
        contentLabel .. " Best in Slot:",
        COLORS.HEADER.r, COLORS.HEADER.g, COLORS.HEADER.b
    )

    -- Show BiS items (primary and alternatives)
    for i, item in ipairs(items) do
        if i > 3 then break end -- Limit to 3 items max

        local color = item.priority == 1 and COLORS.BIS_PRIMARY or COLORS.BIS_ALT
        local priorityText = ""
        if PBS.Config.showPriority and item.priority > 1 then
            priorityText = " (Alt #" .. item.priority .. ")"
        end

        -- Source type indicator
        local sourceIndicator = ""
        if item.sourceType then
            local st = item.sourceType:lower()
            if st == "raid" then
                sourceIndicator = " [R]"
            elseif st == "dungeon" then
                sourceIndicator = " [M+]"
            elseif st == "crafted" then
                sourceIndicator = " [C]"
            elseif st == "catalyst" then
                sourceIndicator = " [Cat]"
            end
        end

        -- Item name line with source indicator
        tooltip:AddLine(
            item.itemName .. priorityText .. sourceIndicator,
            color.r, color.g, color.b
        )

        -- Drop source line (indented)
        if PBS.Config.showDropSource and item.dropSource then
            tooltip:AddLine(
                "  " .. item.dropSource,
                COLORS.VALUE.r, COLORS.VALUE.g, COLORS.VALUE.b
            )
        end
    end
end

-- Process tooltip for items (shows if hovered item IS BiS)
function TooltipHook:ProcessTooltipData(tooltip, tooltipData)
    if not PBS.Config.enabled then return end
    if not tooltipData then return end

    -- Get PeaversBestInSlotData API
    local BiSData = _G.PeaversBestInSlotData
    if not BiSData or not BiSData.API then
        Utils.Debug(PBS, "PeaversBestInSlotData not available")
        return
    end

    local itemID = tooltipData.id
    if not itemID then return end

    -- Check if we're hovering over a character panel slot
    local slotID = self:GetCurrentSlotID()

    Utils.Debug(PBS, "Processing tooltip for itemID: " .. tostring(itemID) .. ", slotID: " .. tostring(slotID))

    -- If we're hovering over a character slot, show BiS for that slot
    if slotID then
        self:AddSlotBiSInfo(tooltip, slotID)
        -- Don't return - also show if current item is BiS below
    end

    -- Otherwise, check if this item is BiS
    local bisInfo = BiSData.API.IsItemBiS(itemID, nil, PBS.Config.dataSource)
    if not bisInfo then return end

    -- Find if item is BiS for current player spec
    local forCurrentSpec = nil
    local forOtherSpecs = {}

    for _, info in ipairs(bisInfo) do
        -- Filter by configured content type
        if info.contentType == PBS.Config.contentType then
            if info.classID == playerClassID and info.specID == playerSpecID then
                if not forCurrentSpec or info.priority < forCurrentSpec.priority then
                    forCurrentSpec = info
                end
            else
                table.insert(forOtherSpecs, info)
            end
        end
    end

    -- Only show if item is BiS for something
    if not forCurrentSpec and #forOtherSpecs == 0 then
        return
    end

    -- Add separator line
    tooltip:AddLine(" ")

    -- Show BiS status for current spec
    if forCurrentSpec then
        local bisLabel = FormatBiSLabel(forCurrentSpec.priority, forCurrentSpec.contentType, PBS.Config.compactMode)
        local color = forCurrentSpec.priority == 1 and COLORS.BIS_PRIMARY or COLORS.BIS_ALT

        if PBS.Config.showDropSource and forCurrentSpec.dropSource then
            tooltip:AddDoubleLine(
                bisLabel,
                forCurrentSpec.dropSource,
                color.r, color.g, color.b,
                COLORS.VALUE.r, COLORS.VALUE.g, COLORS.VALUE.b
            )
        else
            tooltip:AddLine(
                bisLabel,
                color.r, color.g, color.b
            )
        end
    end

    -- Optionally show BiS for other specs
    if PBS.Config.showOtherSpecs and #forOtherSpecs > 0 then
        -- Group by class/spec to avoid duplicates
        local specsSeen = {}
        for _, info in ipairs(forOtherSpecs) do
            local key = info.classID .. "-" .. info.specID
            if not specsSeen[key] then
                specsSeen[key] = info
            end
        end

        local count = 0
        for _, info in pairs(specsSeen) do
            if count < PBS.Config.maxOtherSpecs then
                local className = GetClassName(info.classID)
                local specName = GetSpecName(info.specID)

                local label = PBS.Config.compactMode and "Also BiS:" or "Also BiS for:"
                local specText = specName .. " " .. className

                tooltip:AddDoubleLine(
                    label,
                    specText,
                    COLORS.BIS_OTHER.r, COLORS.BIS_OTHER.g, COLORS.BIS_OTHER.b,
                    COLORS.BIS_OTHER.r, COLORS.BIS_OTHER.g, COLORS.BIS_OTHER.b
                )
                count = count + 1
            end
        end
    end
end

-- Track which slot we're currently hovering over
local currentHoveredSlotID = nil

-- Hook character panel slots
function TooltipHook:HookCharacterSlots()
    for slotName, slotID in pairs(SLOT_NAME_TO_ID) do
        if slotID ~= 4 then -- Skip shirt slot
            local slotFrame = _G[slotName]
            if slotFrame then
                slotFrame:HookScript("OnEnter", function(self)
                    currentHoveredSlotID = slotID
                end)

                slotFrame:HookScript("OnLeave", function(self)
                    currentHoveredSlotID = nil
                end)

                Utils.Debug(PBS, "Hooked slot: " .. slotName .. " (ID: " .. slotID .. ")")
            end
        end
    end
end

-- Get current hovered slot ID (used by tooltip processor)
function TooltipHook:GetCurrentSlotID()
    return currentHoveredSlotID
end

function TooltipHook:Initialize()
    -- Update player info
    UpdatePlayerInfo()

    -- Register for spec changes
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        UpdatePlayerInfo()
    end)

    -- Hook using modern TooltipDataProcessor API for general item tooltips
    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, tooltipData)
            self:ProcessTooltipData(tooltip, tooltipData)
        end)
        Utils.Debug(PBS, "TooltipDataProcessor hook registered")
    else
        -- Fallback for older API (pre-10.0)
        local tooltips = {
            GameTooltip,
            ItemRefTooltip,
            _G["ShoppingTooltip1"],
            _G["ShoppingTooltip2"],
        }

        for _, tooltip in ipairs(tooltips) do
            if tooltip and tooltip.HookScript then
                tooltip:HookScript("OnTooltipSetItem", function(self)
                    local _, itemLink = self:GetItem()
                    if itemLink then
                        local itemID = tonumber(itemLink:match("item:(%d+)"))
                        if itemID then
                            TooltipHook:ProcessTooltipData(self, {id = itemID})
                        end
                    end
                end)
            end
        end
        Utils.Debug(PBS, "Legacy tooltip hooks registered")
    end

    -- Hook character panel slots
    self:HookCharacterSlots()

    Utils.Print(PBS, "Tooltip hooks initialized - classID: " .. tostring(playerClassID) .. ", specID: " .. tostring(playerSpecID))
end

return TooltipHook
