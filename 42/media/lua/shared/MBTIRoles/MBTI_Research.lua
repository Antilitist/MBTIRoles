--[[
  MBTIRoles — Analyst research speed (P2 add-on)
  Vanilla B42 "Research" is a timed action (ISResearchRecipe), not a skill perk.
  Analysts finish research faster (design: systems / abstract learning).
]]

require "TimedActions/ISResearchRecipe"

MBTIRoles = MBTIRoles or {}
MBTIRoles.Research = MBTIRoles.Research or {}

local D = MBTIRoles.Data

--- Research duration multiplier for player (1.0 = no change; lower = faster)
function MBTIRoles.Research.getTimeMultiplier(character)
    if not character or not D then return 1.0 end
    if MBTIRoles.Config and not MBTIRoles.Config.isEnabled() then return 1.0 end

    local md = character:getModData() and character:getModData().MBTIRoles
    if not md or not md.roleId then
        if MBTIRoles.Player and MBTIRoles.Player.syncFromTraits then
            MBTIRoles.Player.syncFromTraits(character, { announce = false })
            md = character:getModData().MBTIRoles
        end
    end
    -- Only Analysts get research speed (design)
    if not md or md.roleId ~= "Analyst" then return 1.0 end

    if MBTIRoles.Config and MBTIRoles.Config.getResearchTimeMult then
        return MBTIRoles.Config.getResearchTimeMult()
    end

    local effects = D.RoleEffects and D.RoleEffects.Analyst
    if not effects or not effects.researchTimeMult then return 1.0 end
    return effects.researchTimeMult
end

local _origGetDuration = ISResearchRecipe.getDuration

function ISResearchRecipe:getDuration()
    local time = _origGetDuration(self)
    if not time or time <= 1 then
        return time
    end

    local mult = MBTIRoles.Research.getTimeMultiplier(self.character)
    if mult ~= 1.0 then
        time = time * mult
        if time < 1 then time = 1 end
    end
    return time
end

print("[MBTIRoles] Analyst research speed hook loaded.")
