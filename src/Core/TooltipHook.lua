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
local function FormatBiSLabel(priority, compact)
    if compact then
        return priority == 1 and "BiS" or "Alt"
    end
    return priority == 1 and "Best in Slot" or ("Alternative #" .. priority)
end

-- Normalize paired slots (second ring/trinket -> first) since BiS data only uses slots 11 and 13
local function NormalizeSlotID(slotID)
    if slotID == 12 then return 11 end  -- Finger1 -> Finger0
    if slotID == 14 then return 13 end  -- Trinket1 -> Trinket0
    return slotID
end

-- Get BiS items for a slot
local function GetSlotItems(BiSData, slotID)
    local items = BiSData.API.GetBiSForSlot(playerClassID, playerSpecID, NormalizeSlotID(slotID))
    if not items or #items == 0 then return nil end
    return items
end

-- The list an item belongs to, when its spec has more than one -- a hero talent,
-- or a Mythic+ list beside the general one. Empty for most specs, which publish
-- a single recommendation and have nothing to tell apart.
local function VariantSuffix(item)
    if not item.variant or item.variant == "" then return "" end
    return " (" .. item.variant .. ")"
end

-- Set consistent font on the last added tooltip line (left side)
local function SetLastLineFont(tooltip, fontObject)
    local lineNum = tooltip:NumLines()
    local leftText = _G[tooltip:GetName() .. "TextLeft" .. lineNum]
    if leftText then
        leftText:SetFontObject(fontObject)
    end
end

-- Set consistent font on the last added double line (both sides)
local function SetLastDoubleLineFont(tooltip, fontObject)
    local lineNum = tooltip:NumLines()
    local leftText = _G[tooltip:GetName() .. "TextLeft" .. lineNum]
    local rightText = _G[tooltip:GetName() .. "TextRight" .. lineNum]
    if leftText then
        leftText:SetFontObject(fontObject)
    end
    if rightText then
        rightText:SetFontObject(fontObject)
    end
end

-- Add a standard tooltip line with consistent font
local function AddTooltipLine(tooltip, text, r, g, b)
    tooltip:AddLine(text, r, g, b)
    SetLastLineFont(tooltip, GameFontNormal)
end

-- Add a small-font subtitle line (used for location/source)
local function AddSubtitleLine(tooltip, text, r, g, b)
    tooltip:AddLine(text, r, g, b)
    SetLastLineFont(tooltip, GameFontNormalSmall)
end

-- Add a standard double line with consistent font
local function AddTooltipDoubleLine(tooltip, leftText, rightText, lr, lg, lb, rr, rg, rb)
    tooltip:AddDoubleLine(leftText, rightText, lr, lg, lb, rr, rg, rb)
    SetLastDoubleLineFont(tooltip, GameFontNormal)
end

-- Render a single slot item line in the tooltip with source below
local function RenderSlotItem(tooltip, item)
    local color = item.priority == 1 and COLORS.BIS_PRIMARY or COLORS.BIS_ALT
    local priorityText = ""
    if PBS.Config.showPriority and item.priority > 1 then
        priorityText = " (Alt)"
    end

    -- Item name line
    AddTooltipLine(tooltip, item.itemName .. priorityText, color.r, color.g, color.b)

    -- Subtitle: where it drops, and which list wants it when the spec has more
    -- than one. Skipped entirely when there is neither.
    local parts = {}
    if PBS.Config.showDropSource and item.dropSource and item.dropSource ~= "" then
        table.insert(parts, item.dropSource)
    end
    if item.variant and item.variant ~= "" then
        table.insert(parts, item.variant)
    end
    if #parts > 0 then
        AddSubtitleLine(tooltip, table.concat(parts, " · "),
            COLORS.BIS_OTHER.r, COLORS.BIS_OTHER.g, COLORS.BIS_OTHER.b)
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

    local items = GetSlotItems(BiSData, slotID)
    if not items then
        Utils.Debug(PBS, "No BiS data for slot " .. tostring(slotID))
        return
    end

    Utils.Debug(PBS, "Adding BiS info for slot " .. slotID .. " - showing " .. #items .. " items")

    tooltip:AddLine(" ")
    AddTooltipLine(tooltip, "Best in Slot:", COLORS.HEADER.r, COLORS.HEADER.g, COLORS.HEADER.b)

    for i, item in ipairs(items) do
        if i > 3 then break end
        RenderSlotItem(tooltip, item)
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
    local bisInfo = BiSData.API.IsItemBiS(itemID)
    if not bisInfo then return end

    -- Find the best entry for the current spec, and collect the other specs
    local currentSpecMatch = nil
    local forOtherSpecs = {}

    for _, info in ipairs(bisInfo) do
        if info.classID == playerClassID and info.specID == playerSpecID then
            if not currentSpecMatch or info.priority < currentSpecMatch.priority then
                currentSpecMatch = info
            end
        else
            table.insert(forOtherSpecs, info)
        end
    end

    -- Only show if item is BiS for something
    if not currentSpecMatch and #forOtherSpecs == 0 then
        return
    end

    -- Add separator line
    tooltip:AddLine(" ")

    -- Show BiS status for current spec
    if currentSpecMatch then
        local color = currentSpecMatch.priority == 1 and COLORS.BIS_PRIMARY or COLORS.BIS_ALT
        AddTooltipLine(tooltip,
            FormatBiSLabel(currentSpecMatch.priority, PBS.Config.compactMode) .. VariantSuffix(currentSpecMatch),
            color.r, color.g, color.b)

        -- Location subtitle if available
        if PBS.Config.showDropSource and currentSpecMatch.dropSource and currentSpecMatch.dropSource ~= "" then
            AddSubtitleLine(tooltip, currentSpecMatch.dropSource,
                COLORS.BIS_OTHER.r, COLORS.BIS_OTHER.g, COLORS.BIS_OTHER.b)
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

                AddTooltipDoubleLine(tooltip,
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
                slotFrame:HookScript("OnEnter", function(_)
                    currentHoveredSlotID = slotID
                end)

                slotFrame:HookScript("OnLeave", function(_)
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
    eventFrame:SetScript("OnEvent", function(_, event, ...)
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
                tooltip:HookScript("OnTooltipSetItem", function(tip)
                    local _, itemLink = tip:GetItem()
                    if itemLink then
                        local itemID = tonumber(itemLink:match("item:(%d+)"))
                        if itemID then
                            TooltipHook:ProcessTooltipData(tip, {id = itemID})
                        end
                    end
                end)
            end
        end
        Utils.Debug(PBS, "Legacy tooltip hooks registered")
    end

    -- Hook character panel slots
    self:HookCharacterSlots()
end

return TooltipHook
