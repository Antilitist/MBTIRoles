--[[
  MBTIRoles — Role + Type XP multipliers (P3)
  Hooks Events.AddXP. Strength from SandboxVars.MBTIRoles (0–25%).
]]

MBTIRoles = MBTIRoles or {}
MBTIRoles.XP = MBTIRoles.XP or {}

local D = MBTIRoles.Data

local perkCache = nil

local function buildPerkCache()
    if perkCache then return perkCache end
    perkCache = {}
    if not Perks then return perkCache end

    local names = {
        "Electricity", "Mechanics", "Literature", "PlantScavenging",
        "Doctor", "Farming", "Maintenance", "Aiming",
        "Strength", "MetalWelding", "Blunt", "Cooking",
        "SmallBlade", "Lightfoot",
    }
    for _, name in ipairs(names) do
        local ok, perk = pcall(function() return Perks[name] end)
        if ok and perk then
            perkCache[name] = perk
        end
    end
    return perkCache
end

local function getPlayerMBTI(player)
    if not player or not player.getModData then return nil, nil end
    local md = player:getModData().MBTIRoles
    if not md or not md.roleId then
        if MBTIRoles.Player and MBTIRoles.Player.syncFromTraits then
            MBTIRoles.Player.syncFromTraits(player, { announce = false })
            md = player:getModData().MBTIRoles
        end
    end
    if not md then return nil, nil end
    return md.roleId, md.typeCode
end

local function multForPerkMap(xpMultMap, scaleFn, perk)
    if not xpMultMap or not scaleFn then return 1.0 end
    local cache = buildPerkCache()
    for name, designMult in pairs(xpMultMap) do
        local p = cache[name]
        if p and perk == p then
            return scaleFn(designMult)
        end
    end
    return 1.0
end

function MBTIRoles.XP.getRoleMultiplier(player, perk)
    if not player or not perk or not D then return 1.0 end
    if MBTIRoles.Config and not MBTIRoles.Config.isEnabled() then return 1.0 end

    local roleId = getPlayerMBTI(player)
    if not roleId then return 1.0 end

    local effects = D.RoleEffects and D.RoleEffects[roleId]
    if not effects or not effects.xpMult then return 1.0 end

    local scaleFn = function(m)
        if MBTIRoles.Config and MBTIRoles.Config.scaleRoleXpMult then
            return MBTIRoles.Config.scaleRoleXpMult(m)
        end
        return m
    end
    return multForPerkMap(effects.xpMult, scaleFn, perk)
end

function MBTIRoles.XP.getTypeMultiplier(player, perk)
    if not player or not perk or not D then return 1.0 end
    if MBTIRoles.Config and not MBTIRoles.Config.isEnabled() then return 1.0 end

    local _, typeCode = getPlayerMBTI(player)
    if not typeCode then return 1.0 end

    local effects = D.TypeEffects and D.TypeEffects[typeCode]
    if not effects or not effects.xpMult then return 1.0 end

    local scaleFn = function(m)
        if MBTIRoles.Config and MBTIRoles.Config.scaleTypeXpMult then
            return MBTIRoles.Config.scaleTypeXpMult(m)
        end
        return m
    end
    return multForPerkMap(effects.xpMult, scaleFn, perk)
end

--- Temporary XP window (type hooks): { untilHours, mults = { Literature = 1.08 } }
function MBTIRoles.XP.setTempWindow(player, durationHours, mults)
    if not player or not player.getModData then return end
    local md = player:getModData()
    md.MBTIRoles = md.MBTIRoles or {}
    local now = 0
    pcall(function() now = getGameTime():getWorldAgeHours() end)
    md.MBTIRoles.tempXp = {
        untilHours = now + (durationHours or 1),
        mults = mults or {},
    }
end

function MBTIRoles.XP.getTempMultiplier(player, perk)
    if not player or not perk then return 1.0 end
    local md = player:getModData() and player:getModData().MBTIRoles
    if not md or not md.tempXp or not md.tempXp.mults then return 1.0 end

    local now = 0
    pcall(function() now = getGameTime():getWorldAgeHours() end)
    if md.tempXp.untilHours and now > md.tempXp.untilHours then
        md.tempXp = nil
        return 1.0
    end

    local cache = buildPerkCache()
    for name, mult in pairs(md.tempXp.mults) do
        local p = cache[name]
        if p and perk == p then
            return mult
        end
    end
    return 1.0
end

--- Combined: role and type multiply (e.g. 1.15 * 1.05) * temp window
function MBTIRoles.XP.getMultiplier(player, perk)
    local roleM = MBTIRoles.XP.getRoleMultiplier(player, perk)
    local typeM = MBTIRoles.XP.getTypeMultiplier(player, perk)
    local tempM = MBTIRoles.XP.getTempMultiplier(player, perk)
    return roleM * typeM * tempM
end

local function onAddXP(player, perk, amount)
    if not player or not perk then return end
    if not amount or amount <= 0 then return end
    if MBTIRoles.Config and not MBTIRoles.Config.isEnabled() then return end

    local md = player:getModData()
    if not md then return end
    if md.MBTIRoles_XPProcessing then return end

    local mult = MBTIRoles.XP.getMultiplier(player, perk)
    if not mult or mult == 1.0 then return end

    local delta = amount * (mult - 1.0)
    if delta == 0 then return end
    if delta < 0 and math.abs(delta) > amount then
        delta = -amount
    end

    md.MBTIRoles_XPProcessing = true
    local ok, err = pcall(function()
        player:getXp():AddXP(perk, delta, false, false, false)
    end)
    md.MBTIRoles_XPProcessing = false

    if not ok then
        print("[MBTIRoles] XP adjust failed: " .. tostring(err))
    end
end

Events.AddXP.Add(onAddXP)

print("[MBTIRoles] Role+Type XP multipliers (P3) loaded.")
