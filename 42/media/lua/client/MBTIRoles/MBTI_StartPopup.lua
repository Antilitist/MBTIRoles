--[[
  MBTIRoles — start-of-game summary popup
  Collapsable window (X to close). Opaque background for readability.
]]

require "ISUI/ISCollapsableWindow"
require "ISUI/ISRichTextPanel"

MBTIRoles = MBTIRoles or {}
MBTIRoles.UI = MBTIRoles.UI or {}

local TYPE_NAME = {
    INTJ = "Architect", INTP = "Logician", ENTJ = "Commander", ENTP = "Debater",
    INFJ = "Advocate", INFP = "Mediator", ENFJ = "Protagonist", ENFP = "Campaigner",
    ISTJ = "Logistician", ISFJ = "Defender", ESTJ = "Executive", ESFJ = "Consul",
    ISTP = "Virtuoso", ISFP = "Adventurer", ESTP = "Entrepreneur", ESFP = "Entertainer",
}

local TYPE_FOCUS = {
    INTJ = "Mechanics", INTP = "Electrical", ENTJ = "Strength", ENTP = "Metalworking",
    INFJ = "First Aid", INFP = "Literature", ENFJ = "First Aid", ENFP = "Foraging",
    ISTJ = "Maintenance", ISFJ = "First Aid", ESTJ = "Blunt", ESFJ = "Cooking",
    ISTP = "Short Blade", ISFP = "Foraging", ESTP = "Aiming", ESFP = "Lightfoot",
}

-- Avoid bare % in UI text. Use "pct".
local function pctLabel(n)
    return tostring(math.floor((tonumber(n) or 0) + 0.5)) .. " pct"
end

local function secondaryPct(roleP)
    roleP = tonumber(roleP) or 0
    if roleP <= 0 then return 0 end
    return math.floor(roleP * 10 / 15 + 0.5)
end

local function showPopupEnabled()
    if not MBTIRoles.Config or not MBTIRoles.Config.isEnabled or not MBTIRoles.Config.isEnabled() then
        return false
    end
    if SandboxVars and SandboxVars.MBTIRoles and SandboxVars.MBTIRoles.ShowStartPopup ~= nil then
        return SandboxVars.MBTIRoles.ShowStartPopup and true or false
    end
    return true
end

function MBTIRoles.UI.buildStartSummaryText(player)
    if not player then return nil end

    if MBTIRoles.Player and MBTIRoles.Player.syncFromTraits then
        MBTIRoles.Player.syncFromTraits(player, { announce = false })
    end

    local md = player:getModData() and player:getModData().MBTIRoles
    if not md or (not md.roleId and not md.typeCode) then
        return nil
    end

    local C = MBTIRoles.Config
    local roleP = C and C.getRoleXPPercent and C.getRoleXPPercent() or 15
    local penP = C and C.getRoleXPPenaltyPercent and C.getRoleXPPenaltyPercent() or 10
    local typeP = C and C.getTypeXPPercent and C.getTypeXPPercent() or 5
    local resP = C and C.getResearchSpeedPercent and C.getResearchSpeedPercent() or 15
    local moodP = C and C.getMoodStrengthPercent and C.getMoodStrengthPercent() or 15
    local secP = secondaryPct(roleP)

    local roleId = md.roleId or "Unknown"
    local typeCode = md.typeCode or "----"
    local typeName = TYPE_NAME[typeCode] or typeCode
    local typeFocus = TYPE_FOCUS[typeCode] or "skills"

    local lines = {}
    table.insert(lines, " <H1> MBTI Roles </H1>")
    table.insert(lines, " <LINE> ")
    table.insert(lines, " <TEXT> Your personality: <BR>")
    table.insert(lines, " <TEXT> <RGB:0.7,0.85,1> Role: " .. tostring(roleId) .. " </RGB> <BR>")
    table.insert(lines, " <TEXT> <RGB:0.7,0.9,0.75> Type: " .. tostring(typeCode) .. " (" .. tostring(typeName) .. ") </RGB> <BR>")
    table.insert(lines, " <LINE> ")
    table.insert(lines, " <TEXT> Active sandbox values: <BR>")
    table.insert(lines, " <TEXT> Role XP " .. pctLabel(roleP) .. " | Penalty " .. pctLabel(penP)
        .. " | Type XP " .. pctLabel(typeP) .. " <BR>")
    table.insert(lines, " <TEXT> Research speed " .. pctLabel(resP) .. " | Mood strength " .. pctLabel(moodP) .. " <BR>")
    table.insert(lines, " <LINE> ")

    if roleId == "Analyst" then
        table.insert(lines, " <TEXT> <RGB:0.7,0.55,0.9> ANALYST </RGB> <BR>")
        table.insert(lines, " <TEXT> +" .. pctLabel(roleP) .. " Electrical and Mechanics XP <BR>")
        table.insert(lines, " <TEXT> +" .. pctLabel(secP) .. " Literature XP <BR>")
        table.insert(lines, " <TEXT> -" .. pctLabel(penP) .. " Foraging XP <BR>")
        table.insert(lines, " <TEXT> Research " .. pctLabel(resP) .. " faster <BR>")
        table.insert(lines, " <TEXT> Mood: researching new recipes <BR>")
    elseif roleId == "Diplomat" then
        table.insert(lines, " <TEXT> <RGB:0.4,0.75,0.45> DIPLOMAT </RGB> <BR>")
        table.insert(lines, " <TEXT> +" .. pctLabel(roleP) .. " First Aid XP <BR>")
        table.insert(lines, " <TEXT> +" .. pctLabel(secP) .. " Literature XP <BR>")
        table.insert(lines, " <TEXT> Mood: photos, picture books, mementos <BR>")
    elseif roleId == "Sentinel" then
        table.insert(lines, " <TEXT> <RGB:0.35,0.55,0.9> SENTINEL </RGB> <BR>")
        table.insert(lines, " <TEXT> +" .. pctLabel(roleP) .. " Farming and Maintenance XP <BR>")
        table.insert(lines, " <TEXT> Mood: harvesting crops <BR>")
    elseif roleId == "Explorer" then
        table.insert(lines, " <TEXT> <RGB:0.9,0.75,0.25> EXPLORER </RGB> <BR>")
        table.insert(lines, " <TEXT> +" .. pctLabel(roleP) .. " Foraging XP <BR>")
        table.insert(lines, " <TEXT> +" .. pctLabel(secP) .. " Aiming XP <BR>")
        table.insert(lines, " <TEXT> -" .. pctLabel(penP) .. " Literature XP <BR>")
        table.insert(lines, " <TEXT> Mood: Brochures and Fliers; small forage boost <BR>")
    else
        table.insert(lines, " <TEXT> Role effects: none selected <BR>")
    end

    if typeCode and TYPE_FOCUS[typeCode] then
        table.insert(lines, " <LINE> ")
        table.insert(lines, " <TEXT> Type fine-tune: +" .. pctLabel(typeP) .. " " .. typeFocus .. " XP <BR>")
    end

    table.insert(lines, " <LINE> ")
    table.insert(lines, " <TEXT> Change values in Sandbox > MBTI Roles. <BR>")
    table.insert(lines, " <TEXT> Trait tooltips list defaults only. <BR>")
    table.insert(lines, " <LINE> ")
    table.insert(lines, " <TEXT> Close with the X in the corner. <BR>")

    return table.concat(lines)
end

function MBTIRoles.UI.showStartPopup(player)
    if not showPopupEnabled() then return end
    if not player then
        player = getPlayer and getPlayer() or nil
    end
    if not player then return end

    local text = MBTIRoles.UI.buildStartSummaryText(player)
    if not text then return end

    local width = 480
    local height = 480
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    if width > screenW - 40 then width = screenW - 40 end
    if height > screenH - 40 then height = screenH - 40 end

    local x = (screenW - width) / 2
    local y = (screenH - height) / 2

    local win = ISCollapsableWindow:new(x, y, width, height)
    win:initialise()
    win:instantiate()
    win:setResizable(false)
    win:setDrawFrame(true)
    -- Nearly solid black so world does not show through text
    win.backgroundColor = { r = 0.05, g = 0.05, b = 0.08, a = 0.94 }
    win.borderColor = { r = 0.55, g = 0.55, b = 0.6, a = 1 }
    if win.setTitle then
        win:setTitle("MBTI Roles")
    end
    win.title = "MBTI Roles"

    local titleH = 16
    pcall(function()
        if win.titleBarHeight then titleH = win:titleBarHeight() end
    end)

    local margin = 12
    local body = ISRichTextPanel:new(margin, titleH + 6, width - margin * 2, height - titleH - margin * 2)
    body:initialise()
    body:instantiate()
    body.background = true
    body.backgroundColor = { r = 0.05, g = 0.05, b = 0.08, a = 0.94 }
    body.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    body.marginLeft = 10
    body.marginRight = 10
    body.marginTop = 6
    body.marginBottom = 10
    body.autosetheight = false
    body.text = text
    body:paginate()

    local textH = 280
    pcall(function() textH = body:getScrollHeight() end)
    if textH < 200 then textH = 200 end

    local needH = titleH + 6 + textH + margin
    local maxH = screenH - 40
    if needH > maxH then needH = maxH end
    if needH < 320 then needH = 320 end

    win:setHeight(needH)
    win:setY((screenH - needH) / 2)
    win:setX((screenW - width) / 2)

    local bodyH = needH - titleH - 6 - margin
    body:setHeight(bodyH)
    body:setWidth(width - margin * 2)
    body:paginate()

    win:addChild(body)
    win:addToUIManager()
    win:setVisible(true)

    -- Keep a reference so GC does not drop it early
    MBTIRoles.UI._startPopup = win

    print("[MBTIRoles] Start popup shown (opaque, X to close).")
end

local waitTicks = 0
local waiting = false

local function onTickWait()
    waitTicks = waitTicks + 1
    if waitTicks < 45 then return end
    Events.OnTick.Remove(onTickWait)
    waiting = false
    pcall(function()
        MBTIRoles.UI.showStartPopup(getPlayer())
    end)
end

local function scheduleStartPopup()
    if waiting then return end
    if isServer and isServer() and not isClient() then return end
    waitTicks = 0
    waiting = true
    Events.OnTick.Add(onTickWait)
end

Events.OnGameStart.Add(scheduleStartPopup)

print("[MBTIRoles] Start popup module loaded.")
