--[[
  MBTIRoles — Type micro-hooks for all 16 types (v0.7.0)
  A: INFJ | INFP | ISTJ | ISFP
  B: INTP | ENFP | ESTP | ISTP
  C: INTJ | ENTJ | ENTP | ENFJ | ISFJ | ESTJ | ESFJ | ESFP

  Logging:
    PROC always prints. TRY/MISS/SKIP only if Sandbox → Type micro-hooks debug log.
]]

require "TimedActions/ISReadABook"
require "TimedActions/ISResearchRecipe"
require "Farming/TimedActions/ISHarvestPlantAction"
require "Foraging/ISForageAction"
require "TimedActions/ISRepairClothing"
require "Vehicles/TimedActions/ISRepairEngine"
require "TimedActions/ISFitnessAction"
require "TimedActions/ISApplyBandage"
require "TimedActions/ISStitch"
require "TimedActions/ISCraftAction"
require "TimedActions/ISDismantleAction"
require "TimedActions/ISDestroyStuffAction"
require "TimedActions/ISBarricadeAction"

MBTIRoles = MBTIRoles or {}
MBTIRoles.TypeHooks = MBTIRoles.TypeHooks or {}

local D = MBTIRoles.Data

-- ---------------------------------------------------------------------------
-- Debug helpers (shared by all types)
-- ---------------------------------------------------------------------------
-- PROC always prints (players can verify). TRY/MISS/SKIP only with sandbox TypeHooksDebug.
local function dbg(kind, msg)
    local k = tostring(kind or "")
    if k ~= "PROC" then
        local verbose = false
        if MBTIRoles.Config and MBTIRoles.Config.isTypeHooksDebug then
            verbose = MBTIRoles.Config.isTypeHooksDebug()
        end
        if not verbose then return end
    end
    print("[MBTIRoles] Type hook " .. k .. ": " .. tostring(msg))
end

local function getTypeCode(player)
    if not player then return nil end
    if MBTIRoles.Player and MBTIRoles.Player.syncFromTraits then
        local md = player:getModData() and player:getModData().MBTIRoles
        if not md or not md.typeCode then
            MBTIRoles.Player.syncFromTraits(player, { announce = false })
        end
    end
    local md = player:getModData() and player:getModData().MBTIRoles
    return md and md.typeCode or nil
end

local function worldHours()
    local now = 0
    pcall(function() now = getGameTime():getWorldAgeHours() end)
    return now
end

local function worldDay()
    return math.floor(worldHours() / 24)
end

local function hooksOn()
    return MBTIRoles.Config and MBTIRoles.Config.isTypeHooksEnabled and MBTIRoles.Config.isTypeHooksEnabled()
end

local function typeCfg(typeCode, key)
    if not D or not D.TypeEffects or not D.TypeEffects[typeCode] then return nil end
    return D.TypeEffects[typeCode][key]
end

local function strengthScale()
    local s = 12
    if MBTIRoles.Config and MBTIRoles.Config.getTypeHooksStrength then
        s = MBTIRoles.Config.getTypeHooksStrength()
    end
    return (s or 0) / 15.0
end

local function effectiveChance(designChancePercent)
    local chance = designChancePercent or 0
    if MBTIRoles.Config and MBTIRoles.Config.scaleTypeHookChance then
        chance = MBTIRoles.Config.scaleTypeHookChance(designChancePercent)
    end
    if chance < 0 then chance = 0 end
    if chance > 100 then chance = 100 end
    return chance
end

--- Roll design chance; logs HIT/MISS with effective %
local function rollChance(tag, designChancePercent)
    local chance = effectiveChance(designChancePercent)
    if chance <= 0 then
        dbg("MISS", tag .. " chance=0% (hooks off or strength 0)")
        return false
    end
    local hit = ZombRand(10000) < (chance * 100)
    if hit then
        dbg("TRY", tag .. " chance HIT (" .. string.format("%.1f", chance) .. "%)")
    else
        dbg("MISS", tag .. " chance MISS (" .. string.format("%.1f", chance) .. "%)")
    end
    return hit
end

local function applyTypeMood(player, designCfg, cooldownKey, haloKey, debugTag)
    if not designCfg then
        dbg("SKIP", tostring(debugTag) .. " no mood cfg")
        return false
    end
    local scaled = designCfg
    if MBTIRoles.Config and MBTIRoles.Config.scaleTypeHookMoodCfg then
        scaled = MBTIRoles.Config.scaleTypeHookMoodCfg(designCfg)
        if not scaled then
            dbg("SKIP", tostring(debugTag) .. " mood scale blocked (hooks off/strength 0)")
            return false
        end
    end
    scaled.cooldownHours = designCfg.cooldownHours
    if MBTIRoles.Mood and MBTIRoles.Mood.applyPersonal then
        local ok = MBTIRoles.Mood.applyPersonal(player, scaled, cooldownKey, haloKey, true)
        if ok then
            dbg("PROC", debugTag)
        else
            dbg("SKIP", tostring(debugTag) .. " mood cooldown/blocked")
        end
        return ok
    end
    dbg("SKIP", tostring(debugTag) .. " Mood module missing")
    return false
end

local function isAlone(player)
    local alone = true
    pcall(function()
        local x, y, z = player:getX(), player:getY(), player:getZ()
        for i = 0, getNumActivePlayers() - 1 do
            local p = getSpecificPlayer(i)
            if p and p ~= player and not p:isDead() then
                local dx = p:getX() - x
                local dy = p:getY() - y
                if (dx * dx + dy * dy) < (12 * 12) and p:getZ() == z then
                    alone = false
                    break
                end
            end
        end
    end)
    return alone
end

local function isOutdoors(player)
    local out = false
    pcall(function()
        local sq = player:getCurrentSquare()
        if sq and sq:isOutside() then out = true end
        if player:isOutside() then out = true end
    end)
    return out
end

local function setTempXp(player, hours, mults)
    if MBTIRoles.XP and MBTIRoles.XP.setTempWindow then
        MBTIRoles.XP.setTempWindow(player, hours, mults)
        local parts = {}
        if mults then
            for skill, m in pairs(mults) do
                table.insert(parts, tostring(skill) .. "x" .. string.format("%.2f", m))
            end
        end
        dbg("TRY", "temp XP window " .. tostring(hours) .. "h [" .. table.concat(parts, ", ") .. "]")
    end
end

local function itemTypeKey(item)
    local key = nil
    pcall(function() key = item:getFullType() end)
    if not key then pcall(function() key = item:getType() end) end
    return key
end

-- INTP pattern family: prefer DisplayCategory so 3 different unread mags/books
-- in the same category can build a streak. Same fullType still works for research.
local function patternFamilyKey(item)
    local cat = nil
    pcall(function()
        if item.getDisplayCategory then cat = item:getDisplayCategory() end
    end)
    if cat and tostring(cat) ~= "" then
        return "cat:" .. tostring(cat)
    end
    local ft = itemTypeKey(item)
    if ft then return "type:" .. tostring(ft) end
    return nil
end

-- ---------------------------------------------------------------------------
-- INFJ — Quiet Reflection
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryINFJReflection(player)
    if not hooksOn() or getTypeCode(player) ~= "INFJ" then return end
    local cfg = typeCfg("INFJ", "reflection")
    if not cfg then return end
    if not isAlone(player) then
        dbg("MISS", "INFJ Quiet Reflection not alone")
        return
    end
    dbg("TRY", "INFJ Quiet Reflection (alone tick)")
    if not rollChance("INFJ Quiet Reflection", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastINFJReflectionHours", "UI_MBTI_INFJ_Reflect", "INFJ Quiet Reflection") then
        local mult = 1.0 + ((cfg.litXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.litXpHours or 2, { Literature = mult })
    end
end

-- ---------------------------------------------------------------------------
-- INFP — Memento Keeper
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryINFPMarkKeepsake(player, item)
    if not hooksOn() or getTypeCode(player) ~= "INFP" then return end
    if not item then return end
    if not MBTIRoles.Mood or not MBTIRoles.Mood.isMementoItem or not MBTIRoles.Mood.isMementoItem(item) then
        return
    end

    local cfg = typeCfg("INFP", "keepsake")
    if not cfg then return end

    local md = player:getModData()
    md.MBTIRoles = md.MBTIRoles or {}
    md.MBTIRoles.keepsakes = md.MBTIRoles.keepsakes or {}

    local key = itemTypeKey(item)
    if not key then return end

    for _, k in ipairs(md.MBTIRoles.keepsakes) do
        if k == key then
            dbg("SKIP", "INFP Keepsake already marked item=" .. tostring(key))
            return
        end
    end

    local maxK = cfg.maxKeepsakes or 5
    table.insert(md.MBTIRoles.keepsakes, key)
    while #md.MBTIRoles.keepsakes > maxK do
        table.remove(md.MBTIRoles.keepsakes, 1)
    end

    dbg("TRY", "INFP Keepsake new mark item=" .. tostring(key)
        .. " count=" .. tostring(#md.MBTIRoles.keepsakes) .. "/" .. tostring(maxK))
    applyTypeMood(player, cfg, "lastINFPKeepsakeMarkHours", "UI_MBTI_INFP_Keepsake",
        "INFP Keepsake marked item=" .. tostring(key))
end

local function inventoryHasKeepsake(player)
    local md = player:getModData() and player:getModData().MBTIRoles
    if not md or not md.keepsakes or #md.keepsakes == 0 then return false end
    local found = false
    pcall(function()
        local items = player:getInventory():getItems()
        if not items then return end
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local ft = it:getFullType()
            for _, k in ipairs(md.keepsakes) do
                if ft == k or it:getType() == k then
                    found = true
                    return
                end
            end
        end
    end)
    return found
end

function MBTIRoles.TypeHooks.tryINFPKeepsakeTick(player)
    if not hooksOn() or getTypeCode(player) ~= "INFP" then return end
    local cfg = typeCfg("INFP", "keepsake")
    if not cfg then return end
    if not inventoryHasKeepsake(player) then
        dbg("MISS", "INFP Keepsake comfort tick — no marked keepsake in inventory")
        return
    end
    dbg("TRY", "INFP Keepsake comfort tick")
    applyTypeMood(player, cfg, "lastINFPKeepsakeTickHours", "UI_MBTI_INFP_KeepsakeTick",
        "INFP Keepsake comfort tick")
end

-- ---------------------------------------------------------------------------
-- ISTJ — Duty Roster
-- ---------------------------------------------------------------------------
local function noteRoutineActivity(player, activityId)
    if not hooksOn() or getTypeCode(player) ~= "ISTJ" then return end
    local cfg = typeCfg("ISTJ", "routine")
    if not cfg then return end

    local md = player:getModData()
    md.MBTIRoles = md.MBTIRoles or {}
    local day = worldDay()
    local r = md.MBTIRoles.routine or { activity = nil, lastDay = -999, stack = 0 }
    md.MBTIRoles.routine = r

    if r.activity == activityId and r.lastDay == day then
        dbg("SKIP", "ISTJ Routine already logged today activity=" .. tostring(activityId)
            .. " stack=" .. tostring(r.stack))
        return
    end

    if r.activity == activityId and r.lastDay == day - 1 then
        r.stack = math.min((cfg.maxStack or 3), (r.stack or 0) + 1)
    else
        if r.activity == activityId then
            r.stack = 1
        else
            r.activity = activityId
            r.stack = 1
        end
    end
    r.lastDay = day
    md.MBTIRoles.routine = r

    dbg("TRY", "ISTJ Routine day=" .. tostring(day) .. " activity=" .. tostring(activityId)
        .. " stack=" .. tostring(r.stack))

    if (r.stack or 0) >= 2 then
        local mood = {
            unhappiness = (cfg.unhappiness or -3) * r.stack,
            boredom = (cfg.boredom or -4) * r.stack,
            stress = (cfg.stress or -3) * (0.5 + 0.5 * r.stack),
            cooldownHours = cfg.cooldownHours or 20,
        }
        applyTypeMood(player, mood, "lastISTJRoutineHours", "UI_MBTI_ISTJ_Routine",
            "ISTJ Routine stack=" .. tostring(r.stack) .. " activity=" .. tostring(activityId))
    else
        dbg("MISS", "ISTJ Routine stack=" .. tostring(r.stack) .. " need >=2 for mood")
    end
end

function MBTIRoles.TypeHooks.onHarvest(player)
    noteRoutineActivity(player, "farming")
end

function MBTIRoles.TypeHooks.onRead(player)
    noteRoutineActivity(player, "reading")
end

-- ---------------------------------------------------------------------------
-- ISFP — Sensory Anchor
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryISFPOutdoors(player)
    if not hooksOn() or getTypeCode(player) ~= "ISFP" then return end
    local cfg = typeCfg("ISFP", "outdoors")
    if not cfg then return end
    if not isOutdoors(player) then
        dbg("MISS", "ISFP Sensory Anchor not outdoors")
        return
    end
    dbg("TRY", "ISFP Sensory Anchor (outdoors tick)")
    applyTypeMood(player, cfg, "lastISFPOutdoorsHours", "UI_MBTI_ISFP_Outdoors",
        "ISFP Sensory Anchor (outdoors)")
end

-- ---------------------------------------------------------------------------
-- INTP — Pattern Spotter (Phase B)
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryINTPPattern(player, item)
    if not hooksOn() or getTypeCode(player) ~= "INTP" then return end
    if not item then return end
    local cfg = typeCfg("INTP", "pattern")
    if not cfg then return end

    local key = patternFamilyKey(item)
    if not key then return end
    local detail = itemTypeKey(item) or "?"

    -- NOTE: md.MBTIRoles.pattern is the role letter pattern string ("NT"/"NF"/...)
    -- from Player.syncFromTraits. Streak state must use a separate key.
    local md = player:getModData()
    if not md then return end
    md.MBTIRoles = md.MBTIRoles or {}
    local p = md.MBTIRoles.intpPattern
    if type(p) ~= "table" then
        p = { lastType = nil, streak = 0 }
    end
    if p.lastType == key then
        p.streak = (tonumber(p.streak) or 0) + 1
    else
        p.lastType = key
        p.streak = 1
    end
    md.MBTIRoles.intpPattern = p

    local need = cfg.needStreak or 3
    local streak = tonumber(p.streak) or 0
    dbg("TRY", "INTP Pattern streak " .. tostring(streak) .. "/" .. tostring(need)
        .. " key=" .. tostring(key) .. " item=" .. tostring(detail))

    if streak < need then return end
    if not rollChance("INTP Pattern Spotter", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastINTPPatternHours", "UI_MBTI_INTP_Curious",
        "INTP Pattern Spotter streak=" .. tostring(streak) .. " key=" .. tostring(key)
            .. " item=" .. tostring(detail)) then
        local mult = 1.0 + ((cfg.elecXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { Electricity = mult, Literature = mult })
        p.streak = 0
        md.MBTIRoles.intpPattern = p
    end
end

-- ---------------------------------------------------------------------------
-- ENFP — Spark of Possibility (Phase B)
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryENFPInspired(player, sourceTag)
    if not hooksOn() then return end
    if getTypeCode(player) ~= "ENFP" then return end
    local cfg = typeCfg("ENFP", "inspired")
    if not cfg then
        dbg("SKIP", "ENFP Inspired no cfg")
        return
    end

    local src = tostring(sourceTag or "event")
    dbg("TRY", "ENFP Inspired trigger source=" .. src)

    -- Hard cap: one success per world-day
    local md = player:getModData()
    if not md then return end
    md.MBTIRoles = md.MBTIRoles or {}
    local day = worldDay()
    if md.MBTIRoles.enfpInspiredDay == day then
        dbg("SKIP", "ENFP Inspired already procced today (day=" .. tostring(day) .. ")")
        return
    end

    if not rollChance("ENFP Inspired (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastENFPInspiredHours", "UI_MBTI_ENFP_Inspired",
        "ENFP Inspired (" .. src .. ")") then
        md.MBTIRoles.enfpInspiredDay = day
        local mult = 1.0 + ((cfg.randomXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        local pool = { "PlantScavenging", "Literature", "Lightfoot", "Doctor", "Cooking", "Mechanics" }
        local pick = pool[ZombRand(#pool) + 1]
        local mults = {}
        mults[pick] = mult
        setTempXp(player, cfg.xpHours or 2, mults)
        dbg("PROC", "ENFP Inspired XP window skill=" .. tostring(pick) .. " day=" .. tostring(day))
    end
end

-- ---------------------------------------------------------------------------
-- ESTP — Opportunistic Spark (Phase B)
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryESTPAlert(player, sourceTag)
    if not hooksOn() or getTypeCode(player) ~= "ESTP" then return end
    local cfg = typeCfg("ESTP", "alert")
    if not cfg then return end

    local src = tostring(sourceTag or "event")
    dbg("TRY", "ESTP Alert trigger source=" .. src)
    if not rollChance("ESTP Alert (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastESTPAlertHours", "UI_MBTI_ESTP_Alert",
        "ESTP Alert (" .. src .. ")") then
        local f = 1.0 + ((cfg.forageXpBonus or 0.08) * strengthScale())
        local s = 1.0 + ((cfg.sneakXpBonus or 0.06) * strengthScale())
        if f < 1.01 then f = 1.01 end
        if s < 1.01 then s = 1.01 end
        setTempXp(player, cfg.xpHours or 1.5, { PlantScavenging = f, Lightfoot = s })
    end
end

local function tryESTPNewCell(player)
    if not hooksOn() or getTypeCode(player) ~= "ESTP" then return end
    local md = player:getModData()
    if not md then return end
    md.MBTIRoles = md.MBTIRoles or {}
    local cx, cy = 0, 0
    pcall(function()
        cx = math.floor(player:getX() / 300)
        cy = math.floor(player:getY() / 300)
    end)
    local key = tostring(cx) .. "," .. tostring(cy)
    if md.MBTIRoles.lastCellKey == key then return end
    dbg("TRY", "ESTP new map cell " .. key
        .. " (was " .. tostring(md.MBTIRoles.lastCellKey or "none") .. ")")
    md.MBTIRoles.lastCellKey = key
    MBTIRoles.TypeHooks.tryESTPAlert(player, "new cell " .. key)
end

-- ---------------------------------------------------------------------------
-- ISTP — Practical Fixer (Phase B)
-- sourceTag: "padding" | "patch" | "clothing" | "engine" | ...
-- opts.skipCondCheck: true = always eligible (padding / engine)
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryISTPFixer(player, item, sourceTag, opts)
    if not hooksOn() or getTypeCode(player) ~= "ISTP" then return end
    local cfg = typeCfg("ISTP", "fixer")
    if not cfg then return end
    opts = opts or {}

    local src = tostring(sourceTag or "repair")
    local maxCond = cfg.maxCondition or 0.55
    local cond = 1
    pcall(function()
        if item and item.getCondition and item.getConditionMax then
            local c = item:getCondition()
            local m = item:getConditionMax()
            if m and m > 0 then cond = c / m end
        end
    end)

    -- Padding is reinforcing intact gear — skip "must be rough" gate.
    -- Engine repairs often have no clothing item condition to check.
    local skipCond = opts.skipCondCheck
        or src == "padding"
        or src == "engine"
        or item == nil

    dbg("TRY", "ISTP Fixer source=" .. src .. " cond=" .. string.format("%.2f", cond)
        .. " maxCond=" .. tostring(maxCond)
        .. (skipCond and " (cond check skipped)" or ""))

    if item and not skipCond and cond > maxCond then
        dbg("MISS", "ISTP Fixer cond too high (" .. string.format("%.2f", cond)
            .. " > " .. tostring(maxCond) .. ") — need rougher gear or use Add Padding")
        return
    end

    if applyTypeMood(player, cfg, "lastISTPFixerHours", "UI_MBTI_ISTP_Fixer",
        "ISTP Practical Fixer (" .. src .. ") cond=" .. string.format("%.2f", cond)) then
        local mult = 1.0 + ((cfg.maintXpBonus or 0.10) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { Maintenance = mult, Mechanics = mult })
    end
end

--- Classify ISRepairClothing as "padding" vs "patch" (hole > 0 on body part)
local function repairClothingSourceTag(action)
    local tag = "clothing"
    pcall(function()
        if not action or not action.clothing or not action.part then return end
        local hole = 0
        if action.clothing.getVisual then
            local vis = action.clothing:getVisual()
            if vis and vis.getHole then
                hole = vis:getHole(action.part) or 0
            end
        end
        if hole and hole > 0 then
            tag = "patch"
        else
            tag = "padding"
        end
    end)
    return tag
end

local function isNearOtherPlayers(player)
    return not isAlone(player)
end

--- Radio / device on (inventory) — soft SP proxy for social / entertainment
local function hasActiveRadio(player)
    local on = false
    pcall(function()
        local inv = player:getInventory()
        if not inv then return end
        local items = inv:getItems()
        if not items then return end
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it then
                if it.isPlayingSomething and it:isPlayingSomething() then
                    on = true
                    return
                end
                if it.getDeviceData then
                    local dd = it:getDeviceData()
                    if dd and dd.getIsTurnedOn and dd:getIsTurnedOn() then
                        on = true
                        return
                    end
                end
            end
        end
    end)
    return on
end

-- ---------------------------------------------------------------------------
-- Phase C — INTJ Strategic Solitude
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryINTJFocus(player, sourceTag)
    if not hooksOn() or getTypeCode(player) ~= "INTJ" then return end
    local cfg = typeCfg("INTJ", "focus")
    if not cfg then return end
    local src = tostring(sourceTag or "tick")

    if src == "alone" or src == "hourly" then
        if not isAlone(player) then
            dbg("MISS", "INTJ Focus not alone")
            return
        end
    end

    dbg("TRY", "INTJ Focus source=" .. src)
    if not rollChance("INTJ Focus (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastINTJFocusHours", "UI_MBTI_INTJ_Focus",
        "INTJ Strategic Solitude (" .. src .. ")") then
        local mult = 1.0 + ((cfg.mechXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { Mechanics = mult })
    end
end

-- ---------------------------------------------------------------------------
-- Phase C — ENTJ Command Presence
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryENTJCommand(player, sourceTag)
    if not hooksOn() or getTypeCode(player) ~= "ENTJ" then return end
    local cfg = typeCfg("ENTJ", "command")
    if not cfg then return end
    local src = tostring(sourceTag or "event")
    dbg("TRY", "ENTJ Command source=" .. src)
    if not rollChance("ENTJ Command (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastENTJCommandHours", "UI_MBTI_ENTJ_Command",
        "ENTJ Command Presence (" .. src .. ")") then
        local mult = 1.0 + ((cfg.strengthXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { Strength = mult })
    end
end

-- ---------------------------------------------------------------------------
-- Phase C — ENTP Improviser
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryENTPImprovise(player, sourceTag)
    if not hooksOn() or getTypeCode(player) ~= "ENTP" then return end
    local cfg = typeCfg("ENTP", "improvise")
    if not cfg then return end
    local src = tostring(sourceTag or "event")
    dbg("TRY", "ENTP Improvise source=" .. src)
    if not rollChance("ENTP Improvise (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastENTPImproviseHours", "UI_MBTI_ENTP_Improvise",
        "ENTP Improviser (" .. src .. ")") then
        local mult = 1.0 + ((cfg.weldXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { MetalWelding = mult })
    end
end

-- ---------------------------------------------------------------------------
-- Phase C — ENFJ Social Warmth
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryENFJSocial(player, sourceTag)
    if not hooksOn() or getTypeCode(player) ~= "ENFJ" then return end
    local cfg = typeCfg("ENFJ", "social")
    if not cfg then return end

    local near = isNearOtherPlayers(player)
    local radio = hasActiveRadio(player)
    if not near and not radio then
        dbg("MISS", "ENFJ Social — need nearby player or radio on")
        return
    end

    local src = tostring(sourceTag or "hourly")
    if near then src = src .. "+people" end
    if radio then src = src .. "+radio" end
    dbg("TRY", "ENFJ Social source=" .. src)
    if not rollChance("ENFJ Social (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastENFJSocialHours", "UI_MBTI_ENFJ_Social",
        "ENFJ Social Warmth (" .. src .. ")") then
        local mult = 1.0 + ((cfg.doctorXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { Doctor = mult })
    end
end

-- ---------------------------------------------------------------------------
-- Phase C — ISFJ Caregiver
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryISFJCare(player, sourceTag)
    if not hooksOn() or getTypeCode(player) ~= "ISFJ" then return end
    local cfg = typeCfg("ISFJ", "care")
    if not cfg then return end
    local src = tostring(sourceTag or "care")
    dbg("TRY", "ISFJ Care source=" .. src)
    if not rollChance("ISFJ Care (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastISFJCareHours", "UI_MBTI_ISFJ_Care",
        "ISFJ Caregiver (" .. src .. ")") then
        local mult = 1.0 + ((cfg.doctorXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { Doctor = mult })
    end
end

-- ---------------------------------------------------------------------------
-- Phase C — ESTJ Take Charge
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryESTJCharge(player, sourceTag)
    if not hooksOn() or getTypeCode(player) ~= "ESTJ" then return end
    local cfg = typeCfg("ESTJ", "charge")
    if not cfg then return end
    local src = tostring(sourceTag or "event")
    dbg("TRY", "ESTJ Charge source=" .. src)
    if not rollChance("ESTJ Charge (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastESTJChargeHours", "UI_MBTI_ESTJ_Charge",
        "ESTJ Take Charge (" .. src .. ")") then
        local mult = 1.0 + ((cfg.bluntXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { Blunt = mult })
    end
end

-- ---------------------------------------------------------------------------
-- Phase C — ESFJ Host
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryESFJHost(player, sourceTag)
    if not hooksOn() or getTypeCode(player) ~= "ESFJ" then return end
    local cfg = typeCfg("ESFJ", "host")
    if not cfg then return end
    local src = tostring(sourceTag or "event")
    dbg("TRY", "ESFJ Host source=" .. src)
    if not rollChance("ESFJ Host (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastESFJHostHours", "UI_MBTI_ESFJ_Host",
        "ESFJ Host (" .. src .. ")") then
        local mult = 1.0 + ((cfg.cookXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { Cooking = mult })
    end
end

-- ---------------------------------------------------------------------------
-- Phase C — ESFP Spotlight
-- ---------------------------------------------------------------------------
function MBTIRoles.TypeHooks.tryESFPVibe(player, sourceTag)
    if not hooksOn() or getTypeCode(player) ~= "ESFP" then return end
    local cfg = typeCfg("ESFP", "vibe")
    if not cfg then return end

    local outdoor = isOutdoors(player)
    local radio = hasActiveRadio(player)
    if not outdoor and not radio then
        dbg("MISS", "ESFP Vibe — need outdoors or radio on")
        return
    end

    local src = tostring(sourceTag or "hourly")
    if outdoor then src = src .. "+out" end
    if radio then src = src .. "+radio" end
    dbg("TRY", "ESFP Vibe source=" .. src)
    if not rollChance("ESFP Vibe (" .. src .. ")", cfg.chancePercent) then return end

    if applyTypeMood(player, cfg, "lastESFPVibeHours", "UI_MBTI_ESFP_Vibe",
        "ESFP Spotlight (" .. src .. ")") then
        local mult = 1.0 + ((cfg.lightfootXpBonus or 0.08) * strengthScale())
        if mult < 1.01 then mult = 1.01 end
        setTempXp(player, cfg.xpHours or 2, { Lightfoot = mult })
    end
end

-- ---------------------------------------------------------------------------
-- Timers + action hooks
-- ---------------------------------------------------------------------------
local function onEveryHours()
    if not hooksOn() then return end
    local p = getPlayer and getPlayer() or nil
    if not p or p:isDead() then return end
    pcall(function() MBTIRoles.TypeHooks.tryINFJReflection(p) end)
    pcall(function() MBTIRoles.TypeHooks.tryINFPKeepsakeTick(p) end)
    pcall(function() MBTIRoles.TypeHooks.tryISFPOutdoors(p) end)
    pcall(function() tryESTPNewCell(p) end)
    -- Phase C hourly
    pcall(function() MBTIRoles.TypeHooks.tryINTJFocus(p, "hourly") end)
    pcall(function() MBTIRoles.TypeHooks.tryENFJSocial(p, "hourly") end)
    pcall(function() MBTIRoles.TypeHooks.tryESFPVibe(p, "hourly") end)
end

local function onMinute()
    if not hooksOn() then return end
    local p = getPlayer and getPlayer() or nil
    if not p then return end
    local code = getTypeCode(p)
    if code == "INFP" then
        local item = nil
        pcall(function()
            item = p:getPrimaryHandItem()
            if not item then item = p:getSecondaryHandItem() end
        end)
        if item then
            pcall(function() MBTIRoles.TypeHooks.tryINFPMarkKeepsake(p, item) end)
        end
    end
    if code == "ESTP" then
        pcall(function() tryESTPNewCell(p) end)
    end
end

local _readComplete = ISReadABook.complete
function ISReadABook:complete()
    local result = _readComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryINFPMarkKeepsake(self.character, self.item)
            MBTIRoles.TypeHooks.onRead(self.character)
            MBTIRoles.TypeHooks.tryINTPPattern(self.character, self.item)
        end)
    end
    return result
end

local _researchComplete = ISResearchRecipe.complete
function ISResearchRecipe:complete()
    local result = _researchComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryINTPPattern(self.character, self.item)
            MBTIRoles.TypeHooks.tryINTJFocus(self.character, "research")
            MBTIRoles.TypeHooks.tryENTPImprovise(self.character, "research")
        end)
    end
    return result
end

local _harvestComplete = ISHarvestPlantAction.complete
function ISHarvestPlantAction:complete()
    local result = _harvestComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.onHarvest(self.character)
            MBTIRoles.TypeHooks.tryESFJHost(self.character, "harvest")
        end)
    end
    return result
end

local _forageComplete = ISForageAction.complete
function ISForageAction:complete()
    local result = _forageComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryENFPInspired(self.character, "forage")
            MBTIRoles.TypeHooks.tryESTPAlert(self.character, "forage")
        end)
    end
    return result
end

local _foragePerform = ISForageAction.perform
function ISForageAction:perform()
    _foragePerform(self)
    if self.character then
        local okServer = true
        pcall(function()
            if isServer and isServer() then okServer = false end
        end)
        if okServer then
            pcall(function()
                MBTIRoles.TypeHooks.tryENFPInspired(self.character, "forage-perform")
                MBTIRoles.TypeHooks.tryESTPAlert(self.character, "forage-perform")
            end)
        end
    end
end

local _repairClothes = ISRepairClothing.complete
function ISRepairClothing:complete()
    local srcTag = "clothing"
    pcall(function() srcTag = repairClothingSourceTag(self) end)
    local result = _repairClothes(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryISTPFixer(self.character, self.clothing, srcTag, {
                skipCondCheck = (srcTag == "padding"),
            })
        end)
    end
    return result
end

local _repairEngine = ISRepairEngine.complete
function ISRepairEngine:complete()
    local result = _repairEngine(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryISTPFixer(self.character, nil, "engine")
        end)
    end
    return result
end

-- Phase C action hooks
local _fitnessComplete = ISFitnessAction.complete
function ISFitnessAction:complete()
    local result = _fitnessComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryENTJCommand(self.character, "fitness")
        end)
    end
    return result
end

local _bandageComplete = ISApplyBandage.complete
function ISApplyBandage:complete()
    local result = _bandageComplete(self)
    if self.character and self.doIt then
        pcall(function()
            MBTIRoles.TypeHooks.tryISFJCare(self.character, "bandage")
        end)
    end
    return result
end

local _stitchComplete = ISStitch.complete
function ISStitch:complete()
    local result = _stitchComplete(self)
    if self.character and self.doIt then
        pcall(function()
            MBTIRoles.TypeHooks.tryISFJCare(self.character, "stitch")
        end)
    end
    return result
end

local _craftComplete = ISCraftAction.complete
function ISCraftAction:complete()
    local result = _craftComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryENTPImprovise(self.character, "craft")
            -- Cooking crafts also feed ESFJ host fantasy
            local isCook = false
            pcall(function()
                if self.recipe and self.recipe.getCategory then
                    local cat = tostring(self.recipe:getCategory() or "")
                    if string.find(string.lower(cat), "cook", 1, true) then
                        isCook = true
                    end
                end
                if self.recipe and self.recipe.getName then
                    local n = string.lower(tostring(self.recipe:getName() or ""))
                    if string.find(n, "cook", 1, true) or string.find(n, "soup", 1, true)
                        or string.find(n, "stew", 1, true) or string.find(n, "salad", 1, true) then
                        isCook = true
                    end
                end
            end)
            if isCook then
                MBTIRoles.TypeHooks.tryESFJHost(self.character, "cook")
            end
        end)
    end
    return result
end

local _dismantleComplete = ISDismantleAction.complete
function ISDismantleAction:complete()
    local result = _dismantleComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryENTPImprovise(self.character, "dismantle")
        end)
    end
    return result
end

local _destroyComplete = ISDestroyStuffAction.complete
function ISDestroyStuffAction:complete()
    local result = _destroyComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryESTJCharge(self.character, "destroy")
        end)
    end
    return result
end

local _barricadeComplete = ISBarricadeAction.complete
function ISBarricadeAction:complete()
    local result = _barricadeComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.TypeHooks.tryESTJCharge(self.character, "barricade")
        end)
    end
    return result
end

Events.EveryHours.Add(onEveryHours)
Events.EveryOneMinute.Add(onMinute)

print("[MBTIRoles] Type hooks loaded (all 16 types, v0.7.0).")
