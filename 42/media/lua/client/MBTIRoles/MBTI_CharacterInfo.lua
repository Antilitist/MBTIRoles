--[[
  MBTIRoles — character info display (P1)
  Shows Role - Type on the character screen under the name line.
]]

require "XpSystem/ISUI/ISCharacterScreen"

MBTIRoles = MBTIRoles or {}
MBTIRoles.UI = MBTIRoles.UI or {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local AVATAR_BORDER = 2

local _origRender = ISCharacterScreen.render

function ISCharacterScreen:render()
    _origRender(self)

    if not self.char then return end
    if not MBTIRoles or not MBTIRoles.Player then return end

    -- Keep modData fresh if traits changed mid-session (admin / debug)
    local roleId, typeCode = MBTIRoles.Player.scanTraits(self.char)
    local md = self.char:getModData().MBTIRoles
    if not md or md.roleId ~= roleId or md.typeCode ~= typeCode then
        MBTIRoles.Player.syncFromTraits(self.char, { announce = false })
    end

    local label = MBTIRoles.Player.formatLabel(self.char)
    if not label or label == "" then return end

    local prefix = getText("UI_MBTI_CharLabel")
    local text = prefix .. " " .. label

    -- Place to the right of the character name (same row), avoiding Weight row
    local nameText = self.char:getDescriptor():getForename() .. " " .. self.char:getDescriptor():getSurname()
    local nameX = self.avatarX + self.avatarWidth + AVATAR_BORDER + UI_BORDER_SPACING
    local nameWid = getTextManager():MeasureStringX(UIFont.Medium, nameText)
    local x = nameX + nameWid + UI_BORDER_SPACING * 2
    local z = UI_BORDER_SPACING + 4

    local r, g, b, a = 0.75, 0.85, 1.0, 1.0
    if md and md.complete then
        r, g, b = 0.70, 0.90, 0.75
    elseif md and md.roleId and not md.typeCode then
        r, g, b = 0.95, 0.85, 0.50
    else
        r, g, b = 0.65, 0.65, 0.65
    end

    self:drawText(text, x, z, r, g, b, a, UIFont.Small)

    local textWid = getTextManager():MeasureStringX(UIFont.Small, text)
    local need = x + textWid + UI_BORDER_SPACING
    if need > self.width then
        self:setWidthAndParentWidth(need)
    end
end

print("[MBTIRoles] Character info display (P1) loaded.")
