--[[
  MBTIRoles — INFP starting keepsake on Customise Character screen
  Visible when INFP is selected. Default = Random (always get one if forgotten).
]]

require "OptionScreens/CharacterCreationMain"
require "OptionScreens/CharacterCreationProfession"
require "ISUI/ISComboBox"
require "ISUI/ISLabel"

MBTIRoles = MBTIRoles or {}
MBTIRoles.Chargen = MBTIRoles.Chargen or {}

local MEMENTO_OPTIONS = {
    { label = "Random memento", type = "RANDOM" },
    { label = "Photograph", type = "Base.Photo" },
    { label = "Old photograph", type = "Base.Photo_VeryOld" },
    { label = "Postcard", type = "Base.Postcard" },
    { label = "Birthday card", type = "Base.Card_Birthday" },
    { label = "Christmas card", type = "Base.Card_Christmas" },
    { label = "Doodle", type = "Base.Doodle" },
    { label = "Kid's doodle", type = "Base.DoodleKids" },
    { label = "Six-sided die", type = "Base.Dice_6" },
    { label = "Harmonica", type = "Base.Harmonica" },
    { label = "None (find one later)", type = nil },
}

local RANDOM_POOL = {
    "Base.Photo",
    "Base.Photo_VeryOld",
    "Base.Postcard",
    "Base.Card_Birthday",
    "Base.Card_Christmas",
    "Base.Doodle",
    "Base.DoodleKids",
    "Base.Dice_6",
    "Base.Harmonica",
}

local DEFAULT_INDEX = 1

local function playerHasINFPTrait()
    local ccp = CharacterCreationProfession and CharacterCreationProfession.instance
    if not ccp then return false end
    local list = ccp.listboxTraitSelected
    if not list or not list.items then return false end

    for i = 1, #list.items do
        local entry = list.items[i]
        if entry and entry.item then
            local trait = entry.item
            local label = nil
            -- getLabel is the safe chargen display string
            local okL, lab = pcall(function() return trait:getLabel() end)
            if okL and lab then label = tostring(lab) end
            if label and string.find(label, "INFP", 1, true) then
                return true
            end
            -- Fallback: description
            local okD, desc = pcall(function() return trait:getDescription() end)
            if okD and desc and string.find(tostring(desc), "INFP", 1, true) then
                return true
            end
        end
    end
    return false
end

local function applyComboSelection(combo)
    if not combo then
        MBTIRoles.Chargen.startingMemento = "RANDOM"
        return
    end
    local idx = combo.selected
    if not idx or idx < 1 then idx = DEFAULT_INDEX end
    local opt = MEMENTO_OPTIONS[idx]
    if not opt or not opt.type then
        MBTIRoles.Chargen.startingMemento = nil
    else
        MBTIRoles.Chargen.startingMemento = opt.type
    end
end

local function onMementoCombo(target, combo)
    applyComboSelection(combo or target)
end

local function updateINFPUI(main)
    if not main or not main.MBTI_INFP_Combo then return end
    local show = false
    local ok, res = pcall(playerHasINFPTrait)
    if ok then show = res end
    main.MBTI_INFP_Label:setVisible(show)
    main.MBTI_INFP_Combo:setVisible(show)
    if show then
        if not main.MBTI_INFP_Combo.selected or main.MBTI_INFP_Combo.selected < 1 then
            main.MBTI_INFP_Combo.selected = DEFAULT_INDEX
        end
        applyComboSelection(main.MBTI_INFP_Combo)
    else
        MBTIRoles.Chargen.startingMemento = nil
    end
end

local function ensureINFPUI(main)
    if not main or main.MBTI_INFP_Combo then return end

    local fontH = getTextManager():getFontHeight(UIFont.Small)
    local comboH = (BUTTON_HGT and BUTTON_HGT) or (fontH + 6)
    local margin = (UI_BORDER_SPACING and UI_BORDER_SPACING) or 10

    local y = main.height - comboH - margin - comboH - 8
    if main.backButton then
        y = main.backButton:getY() - comboH - margin
    end
    local x = margin + 4
    local labelW = getTextManager():MeasureStringX(UIFont.Small, "INFP keepsake:") + 12
    local comboW = 280

    local label = ISLabel:new(x, y + 2, fontH, "INFP keepsake:", 1, 1, 1, 1, UIFont.Small, true)
    label:initialise()
    label:instantiate()
    label:setAnchorTop(false)
    label:setAnchorBottom(true)
    label:setVisible(false)
    main:addChild(label)
    main.MBTI_INFP_Label = label

    local combo = ISComboBox:new(x + labelW, y, comboW, comboH, main, onMementoCombo)
    combo:initialise()
    combo:instantiate()
    combo:setAnchorTop(false)
    combo:setAnchorBottom(true)
    combo.openUpwards = true
    for _, opt in ipairs(MEMENTO_OPTIONS) do
        combo:addOption(opt.label)
    end
    combo.selected = DEFAULT_INDEX
    combo:setVisible(false)
    main:addChild(combo)
    main.MBTI_INFP_Combo = combo

    MBTIRoles.Chargen.startingMemento = "RANDOM"
end

local _create = CharacterCreationMain.create
function CharacterCreationMain:create()
    _create(self)
    pcall(function()
        ensureINFPUI(self)
        updateINFPUI(self)
    end)
end

local _setVisible = CharacterCreationMain.setVisible
function CharacterCreationMain:setVisible(bVisible, joypadData)
    _setVisible(self, bVisible, joypadData)
    if bVisible then
        pcall(function()
            ensureINFPUI(self)
            updateINFPUI(self)
        end)
    end
end

local function resolveItemType(sel)
    if not sel then return nil end
    if sel == "RANDOM" then
        return RANDOM_POOL[ZombRand(#RANDOM_POOL) + 1]
    end
    return sel
end

local function giveStartingMemento(player)
    if not player then return end

    local isINFP = false
    pcall(function()
        if MBTIRoles.Player then
            MBTIRoles.Player.syncFromTraits(player, { announce = false })
            local md = player:getModData().MBTIRoles
            if md and md.typeCode == "INFP" then isINFP = true end
        end
    end)
    if not isINFP then
        pcall(function()
            if MBTIRolesRegistries and MBTIRolesRegistries.INFP and player:hasTrait(MBTIRolesRegistries.INFP) then
                isINFP = true
            end
        end)
    end
    if not isINFP then return end

    local sel = MBTIRoles.Chargen and MBTIRoles.Chargen.startingMemento
    if sel == nil then sel = "RANDOM" end
    local itemType = resolveItemType(sel)
    if not itemType then return end

    local item = nil
    pcall(function() item = player:getInventory():AddItem(itemType) end)
    if not item then
        local short = string.gsub(itemType, "^Base%.", "")
        pcall(function() item = player:getInventory():AddItem(short) end)
    end
    if not item then
        print("[MBTIRoles] INFP starting memento failed: " .. tostring(itemType))
        return
    end

    pcall(function()
        local md = player:getModData()
        md.MBTIRoles = md.MBTIRoles or {}
        md.MBTIRoles.keepsakes = md.MBTIRoles.keepsakes or {}
        local key = item:getFullType() or itemType
        local found = false
        for _, k in ipairs(md.MBTIRoles.keepsakes) do
            if k == key then found = true break end
        end
        if not found then
            table.insert(md.MBTIRoles.keepsakes, key)
        end
    end)

    print("[MBTIRoles] INFP started with memento: " .. tostring(itemType))
    if MBTIRoles.Chargen then
        MBTIRoles.Chargen.startingMemento = nil
    end
end

Events.OnNewGame.Add(function(player, square)
    pcall(function() giveStartingMemento(player) end)
end)

print("[MBTIRoles] INFP keepsake dropdown on Customise Character (default Random).")
