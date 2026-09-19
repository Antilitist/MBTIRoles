--[[
  MBTIRoles — sandbox config (P3)
  Reads SandboxVars.MBTIRoles with safe defaults.
  Percent options are 0–25 unless noted.
]]

MBTIRoles = MBTIRoles or {}
MBTIRoles.Config = MBTIRoles.Config or {}

local DEFAULTS = {
    Enabled = true,
    RoleXPPercent = 15,
    RoleXPPenaltyPercent = 10,
    TypeXPPercent = 5,
    ResearchSpeedPercent = 15,
    MoodStrengthPercent = 15,
    TypeHooksEnabled = true,
    TypeHooksStrength = 12, -- 0-25; all 16 type micro-hooks
    TypeHooksDebug = false, -- verbose TRY/MISS/SKIP console logs
}

-- Design baselines used to scale secondary bonuses relative to primary
local DESIGN_ROLE_BONUS = 0.15   -- 15% primary role XP
local DESIGN_ROLE_PENALTY = 0.10 -- 10% role XP penalty
local DESIGN_MOOD = 15           -- moodStrengthPercent at full design mood

local function sv()
    if SandboxVars and SandboxVars.MBTIRoles then
        return SandboxVars.MBTIRoles
    end
    return nil
end

local function getBool(key, default)
    local s = sv()
    if s and s[key] ~= nil then
        return s[key] and true or false
    end
    return default
end

local function getInt(key, default, minV, maxV)
    local s = sv()
    local v = default
    if s and s[key] ~= nil then
        v = tonumber(s[key]) or default
    end
    v = math.floor(v + 0.5)
    if minV and v < minV then v = minV end
    if maxV and v > maxV then v = maxV end
    return v
end

function MBTIRoles.Config.isEnabled()
    return getBool("Enabled", DEFAULTS.Enabled)
end

function MBTIRoles.Config.getRoleXPPercent()
    return getInt("RoleXPPercent", DEFAULTS.RoleXPPercent, 0, 25)
end

function MBTIRoles.Config.getRoleXPPenaltyPercent()
    return getInt("RoleXPPenaltyPercent", DEFAULTS.RoleXPPenaltyPercent, 0, 25)
end

function MBTIRoles.Config.getTypeXPPercent()
    return getInt("TypeXPPercent", DEFAULTS.TypeXPPercent, 0, 25)
end

function MBTIRoles.Config.getResearchSpeedPercent()
    return getInt("ResearchSpeedPercent", DEFAULTS.ResearchSpeedPercent, 0, 25)
end

function MBTIRoles.Config.getMoodStrengthPercent()
    return getInt("MoodStrengthPercent", DEFAULTS.MoodStrengthPercent, 0, 25)
end

function MBTIRoles.Config.isTypeHooksEnabled()
    if not MBTIRoles.Config.isEnabled() then return false end
    return getBool("TypeHooksEnabled", DEFAULTS.TypeHooksEnabled)
end

function MBTIRoles.Config.getTypeHooksStrength()
    return getInt("TypeHooksStrength", DEFAULTS.TypeHooksStrength, 0, 25)
end

function MBTIRoles.Config.isTypeHooksDebug()
    return getBool("TypeHooksDebug", DEFAULTS.TypeHooksDebug)
end

--- Scale a 0-100 "chance percent" design value by TypeHooksStrength / 15
function MBTIRoles.Config.scaleTypeHookChance(designChance)
    if not designChance or designChance <= 0 then return 0 end
    if not MBTIRoles.Config.isTypeHooksEnabled() then return 0 end
    local s = MBTIRoles.Config.getTypeHooksStrength()
    if s <= 0 then return 0 end
    return designChance * (s / 15.0)
end

--- Scale type-hook mood deltas using TypeHooksStrength (15 = design)
function MBTIRoles.Config.scaleTypeHookMoodCfg(cfg)
    if not cfg then return nil end
    if not MBTIRoles.Config.isTypeHooksEnabled() then return nil end
    local s = MBTIRoles.Config.getTypeHooksStrength()
    if s <= 0 then return nil end
    local scale = s / 15.0
    local out = {}
    for k, v in pairs(cfg) do
        if k == "unhappiness" or k == "boredom" or k == "stress" then
            out[k] = v * scale
        else
            out[k] = v
        end
    end
    return out
end

--- Scale a design xpMult using sandbox percents.
-- designMult 1.15 → positive scaled by RoleXPPercent
-- designMult 0.90 → penalty scaled by RoleXPPenaltyPercent
function MBTIRoles.Config.scaleRoleXpMult(designMult)
    if not designMult or designMult == 1.0 then return 1.0 end
    if not MBTIRoles.Config.isEnabled() then return 1.0 end

    if designMult > 1.0 then
        local designBonus = designMult - 1.0
        local roleP = MBTIRoles.Config.getRoleXPPercent() / 100.0
        if roleP <= 0 then return 1.0 end
        local ratio = designBonus / DESIGN_ROLE_BONUS
        return 1.0 + (ratio * roleP)
    end

    if designMult < 1.0 then
        local designPen = 1.0 - designMult
        local penP = MBTIRoles.Config.getRoleXPPenaltyPercent() / 100.0
        if penP <= 0 then return 1.0 end
        local ratio = designPen / DESIGN_ROLE_PENALTY
        local out = 1.0 - (ratio * penP)
        if out < 0.5 then out = 0.5 end -- never more than 50% cut
        return out
    end

    return 1.0
end

--- Type fine-tune: design 1.05 → 1 + TypeXPPercent/100 when type has a bonus
function MBTIRoles.Config.scaleTypeXpMult(designMult)
    if not designMult or designMult == 1.0 then return 1.0 end
    if not MBTIRoles.Config.isEnabled() then return 1.0 end
    if designMult > 1.0 then
        local typeP = MBTIRoles.Config.getTypeXPPercent() / 100.0
        if typeP <= 0 then return 1.0 end
        return 1.0 + typeP
    end
    return 1.0
end

--- Research duration mult: 1 - ResearchSpeedPercent/100 (Analyst only)
function MBTIRoles.Config.getResearchTimeMult()
    if not MBTIRoles.Config.isEnabled() then return 1.0 end
    local p = MBTIRoles.Config.getResearchSpeedPercent()
    if p <= 0 then return 1.0 end
    local mult = 1.0 - (p / 100.0)
    if mult < 0.5 then mult = 0.5 end
    return mult
end

--- Scale mood deltas (negative numbers). 0 strength → all zero.
function MBTIRoles.Config.scaleMoodValue(designValue)
    if not designValue or designValue == 0 then return 0 end
    if not MBTIRoles.Config.isEnabled() then return 0 end
    local strength = MBTIRoles.Config.getMoodStrengthPercent()
    if strength <= 0 then return 0 end
    return designValue * (strength / DESIGN_MOOD)
end

function MBTIRoles.Config.scaleMoodCfg(cfg)
    if not cfg then return nil end
    if not MBTIRoles.Config.isEnabled() then return nil end
    if MBTIRoles.Config.getMoodStrengthPercent() <= 0 then return nil end

    local out = {}
    for k, v in pairs(cfg) do
        if k == "unhappiness" or k == "boredom" or k == "stress" then
            out[k] = MBTIRoles.Config.scaleMoodValue(v)
        else
            out[k] = v
        end
    end
    return out
end

print("[MBTIRoles] Config loaded (v0.7.0).")
