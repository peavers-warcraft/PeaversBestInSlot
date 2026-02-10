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
local function FormatBiSLabel(priority, contentLabel, compact)
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

-- Determine content label for an item (Raid or M+)
local function GetContentLabel(item)
    return item.sourceType == "raid" and "Raid" or "M+"
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

-- Get filtered BiS items for a specific content type and slot
local function GetFilteredSlotItems(BiSData, slotID, contentType)
    local allItems = BiSData.API.GetBiSForSlot(playerClassID, playerSpecID, slotID, contentType, PBS.Config.dataSource)
    if not allItems or #allItems == 0 then return nil end

    local items = {}
    for _, item in ipairs(allItems) do
        if PassesSourceFilter(item.sourceType) then
            table.insert(items, item)
        end
    end

    if #items == 0 then return nil end
    return items
end

-- Add a small-font subtitle line to the tooltip
local function AddSubtitleLine(tooltip, text, r, g, b)
    tooltip:AddLine(text, r, g, b)
    local lineNum = tooltip:NumLines()
    local fontString = _G[tooltip:GetName() .. "TextLeft" .. lineNum]
    if fontString then
        fontString:SetFontObject(GameFontNormalSmall)
    end
end

-- Render a single slot item line in the tooltip with source below
local function RenderSlotItem(tooltip, item, contentLabel)
    local color = item.priority == 1 and COLORS.BIS_PRIMARY or COLORS.BIS_ALT
    local priorityText = ""
    if PBS.Config.showPriority and item.priority > 1 and not contentLabel then
        priorityText = " (Alt)"
    end

    -- Item name line
    tooltip:AddLine(item.itemName .. priorityText, color.r, color.g, color.b)

    -- Source subtitle below item name
    local hasDropSource = item.dropSource and item.dropSource ~= ""

    if contentLabel then
        -- "Both" mode: show content label to distinguish items
        if hasDropSource and PBS.Config.showDropSource then
            AddSubtitleLine(tooltip, contentLabel .. " · " .. item.dropSource,
                COLORS.BIS_OTHER.r, COLORS.BIS_OTHER.g, COLORS.BIS_OTHER.b)
        else
            AddSubtitleLine(tooltip, contentLabel,
                COLORS.BIS_OTHER.r, COLORS.BIS_OTHER.g, COLORS.BIS_OTHER.b)
        end
    else
        -- Single mode: show drop source if available
        if hasDropSource and PBS.Config.showDropSource then
            AddSubtitleLine(tooltip, item.dropSource,
                COLORS.BIS_OTHER.r, COLORS.BIS_OTHER.g, COLORS.BIS_OTHER.b)
        end
    end
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

    if PBS.Config.contentType == "both" then
        -- Both mode: show #1 item from each content type
        local raidItems = GetFilteredSlotItems(BiSData, slotID, "raid")
        local dungeonItems = GetFilteredSlotItems(BiSData, slotID, "dungeon")

        if not raidItems and not dungeonItems then
            Utils.Debug(PBS, "No BiS data for slot " .. tostring(slotID) .. " in either content type")
            return
        end

        tooltip:AddLine(" ")
        tooltip:AddLine(
            "Best in Slot:",
            COLORS.HEADER.r, COLORS.HEADER.g, COLORS.HEADER.b
        )

        local raidTop = raidItems and raidItems[1]
        local dungeonTop = dungeonItems and dungeonItems[1]

        -- Deduplicate: same item in both lists, show once without content type
        if raidTop and dungeonTop and raidTop.itemID == dungeonTop.itemID then
            RenderSlotItem(tooltip, raidTop, nil)
        else
            if raidTop then
                RenderSlotItem(tooltip, raidTop, GetContentLabel(raidTop))
            end
            if dungeonTop then
                RenderSlotItem(tooltip, dungeonTop, GetContentLabel(dungeonTop))
            end
        end
    else
        -- Single mode: show up to 3 items for the selected content type
        local items = GetFilteredSlotItems(BiSData, slotID, PBS.Config.contentType)

        if not items then
            Utils.Debug(PBS, "No BiS data for slot " .. tostring(slotID) .. " after source filtering")
            return
        end

        Utils.Debug(PBS, "Adding BiS info for slot " .. slotID .. " - showing " .. #items .. " items")

        tooltip:AddLine(" ")

        local contentLabel = PBS.Config.contentType == "raid" and "Raid" or "M+"
        tooltip:AddLine(
            contentLabel .. " Best in Slot:",
            COLORS.HEADER.r, COLORS.HEADER.g, COLORS.HEADER.b
        )

        for i, item in ipairs(items) do
            if i > 3 then break end
            RenderSlotItem(tooltip, item, nil)
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

    -- If we're hovering over a character slot, show BiS for that slot and stop
    if slotID then
        self:AddSlotBiSInfo(tooltip, slotID)
        return
    end

    -- Otherwise, check if this item is BiS
    local bisInfo = BiSData.API.IsItemBiS(itemID, nil, PBS.Config.dataSource)
    if not bisInfo then return end

    -- Determine which content types to show
    local contentTypesToShow
    if PBS.Config.contentType == "both" then
        contentTypesToShow = { raid = true, dungeon = true }
    else
        contentTypesToShow = { [PBS.Config.contentType] = true }
    end

    -- Find if item is BiS for current player spec (per content type)
    local currentSpecMatches = {}  -- keyed by contentType
    local forOtherSpecs = {}

    for _, info in ipairs(bisInfo) do
        if contentTypesToShow[info.contentType] then
            if info.classID == playerClassID and info.specID == playerSpecID then
                local existing = currentSpecMatches[info.contentType]
                if not existing or info.priority < existing.priority then
                    currentSpecMatches[info.contentType] = info
                end
            else
                table.insert(forOtherSpecs, info)
            end
        end
    end

    -- Only show if item is BiS for something
    local hasCurrentSpec = next(currentSpecMatches) ~= nil
    if not hasCurrentSpec and #forOtherSpecs == 0 then
        return
    end

    -- Add separator line
    tooltip:AddLine(" ")

    -- Show BiS status for current spec
    if hasCurrentSpec then
        local orderedTypes = { "raid", "dungeon" }
        local raidMatch = currentSpecMatches["raid"]
        local dungeonMatch = currentSpecMatches["dungeon"]

        -- Deduplicate: same item in both content types (same priority, no drop source)
        local isDedup = raidMatch and dungeonMatch
            and (not raidMatch.dropSource or raidMatch.dropSource == "")
            and (not dungeonMatch.dropSource or dungeonMatch.dropSource == "")

        if isDedup then
            -- Same item in both - show once as generic "Best in Slot"
            local bestPriority = math.min(raidMatch.priority, dungeonMatch.priority)
            local bisLabel = FormatBiSLabel(bestPriority, "Raid & M+", PBS.Config.compactMode)
            local color = bestPriority == 1 and COLORS.BIS_PRIMARY or COLORS.BIS_ALT
            tooltip:AddLine(bisLabel, color.r, color.g, color.b)
        else
            for _, ct in ipairs(orderedTypes) do
                local match = currentSpecMatches[ct]
                if match then
                    local contentLabel = match.contentType == "raid" and "Raid" or "M+"
                    local bisLabel = FormatBiSLabel(match.priority, contentLabel, PBS.Config.compactMode)
                    local color = match.priority == 1 and COLORS.BIS_PRIMARY or COLORS.BIS_ALT

                    tooltip:AddLine(bisLabel, color.r, color.g, color.b)

                    -- Source subtitle
                    local hasDropSource = match.dropSource and match.dropSource ~= ""
                    if hasDropSource and PBS.Config.showDropSource then
                        AddSubtitleLine(tooltip, match.dropSource,
                            COLORS.BIS_OTHER.r, COLORS.BIS_OTHER.g, COLORS.BIS_OTHER.b)
                    end
                end
            end
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
