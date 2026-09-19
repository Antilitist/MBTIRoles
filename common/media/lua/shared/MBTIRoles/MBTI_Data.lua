--[[
  MBTIRoles — locked data (source of truth)
  See docs/DESIGN-LOCK.md
  Trait keys: MBTIRoles:<Role> / MBTIRoles:<TypeCode>  (registries.lua)
]]

MBTIRoles = MBTIRoles or {}
MBTIRoles.Data = MBTIRoles.Data or {}

local D = MBTIRoles.Data

-- ---------------------------------------------------------------------------
-- Roles (step 1)
-- ---------------------------------------------------------------------------
D.Roles = {
    Analyst = {
        id = "Analyst",
        registryKey = "Analyst",
        name = "Analyst",
        pattern = "NT",
        blurb = "Systems, plans, and ideas. You solve the apocalypse like a puzzle.",
        types = { "INTJ", "INTP", "ENTJ", "ENTP" },
    },
    Diplomat = {
        id = "Diplomat",
        registryKey = "Diplomat",
        name = "Diplomat",
        pattern = "NF",
        blurb = "Meaning, people, and growth. You keep hope — and the wounded — alive.",
        types = { "INFJ", "INFP", "ENFJ", "ENFP" },
    },
    Sentinel = {
        id = "Sentinel",
        registryKey = "Sentinel",
        name = "Sentinel",
        pattern = "SJ",
        blurb = "Duty, order, and sustain. The base stands because you do.",
        types = { "ISTJ", "ISFJ", "ESTJ", "ESFJ" },
    },
    Explorer = {
        id = "Explorer",
        registryKey = "Explorer",
        name = "Explorer",
        pattern = "SP",
        blurb = "Improvise, move, act now. The world is a toolkit — and a playground.",
        types = { "ISTP", "ISFP", "ESTP", "ESFP" },
    },
}

D.RoleOrder = { "Analyst", "Diplomat", "Sentinel", "Explorer" }

-- ---------------------------------------------------------------------------
-- Types (step 2) — each belongs to exactly one role
-- ---------------------------------------------------------------------------
D.Types = {
    INTJ = { code = "INTJ", role = "Analyst",  name = "Architect",    letters = { E = false, S = false, T = true,  J = true  } },
    INTP = { code = "INTP", role = "Analyst",  name = "Logician",     letters = { E = false, S = false, T = true,  J = false } },
    ENTJ = { code = "ENTJ", role = "Analyst",  name = "Commander",    letters = { E = true,  S = false, T = true,  J = true  } },
    ENTP = { code = "ENTP", role = "Analyst",  name = "Debater",      letters = { E = true,  S = false, T = true,  J = false } },

    INFJ = { code = "INFJ", role = "Diplomat", name = "Advocate",     letters = { E = false, S = false, T = false, J = true  } },
    INFP = { code = "INFP", role = "Diplomat", name = "Mediator",     letters = { E = false, S = false, T = false, J = false } },
    ENFJ = { code = "ENFJ", role = "Diplomat", name = "Protagonist",  letters = { E = true,  S = false, T = false, J = true  } },
    ENFP = { code = "ENFP", role = "Diplomat", name = "Campaigner",   letters = { E = true,  S = false, T = false, J = false } },

    ISTJ = { code = "ISTJ", role = "Sentinel", name = "Logistician",  letters = { E = false, S = true,  T = true,  J = true  } },
    ISFJ = { code = "ISFJ", role = "Sentinel", name = "Defender",     letters = { E = false, S = true,  T = false, J = true  } },
    ESTJ = { code = "ESTJ", role = "Sentinel", name = "Executive",    letters = { E = true,  S = true,  T = true,  J = true  } },
    ESFJ = { code = "ESFJ", role = "Sentinel", name = "Consul",       letters = { E = true,  S = true,  T = false, J = true  } },

    ISTP = { code = "ISTP", role = "Explorer", name = "Virtuoso",     letters = { E = false, S = true,  T = true,  J = false } },
    ISFP = { code = "ISFP", role = "Explorer", name = "Adventurer",   letters = { E = false, S = true,  T = false, J = false } },
    ESTP = { code = "ESTP", role = "Explorer", name = "Entrepreneur", letters = { E = true,  S = true,  T = true,  J = false } },
    ESFP = { code = "ESFP", role = "Explorer", name = "Entertainer",  letters = { E = true,  S = true,  T = false, J = false } },
}

D.TypeOrder = {
    "INTJ", "INTP", "ENTJ", "ENTP",
    "INFJ", "INFP", "ENFJ", "ENFP",
    "ISTJ", "ISFJ", "ESTJ", "ESFJ",
    "ISTP", "ISFP", "ESTP", "ESFP",
}

function MBTIRoles.Data.getTypesForRole(roleId)
    local role = D.Roles[roleId]
    if not role then return {} end
    return role.types
end

function MBTIRoles.Data.getRoleForType(typeCode)
    local t = D.Types[typeCode]
    return t and t.role or nil
end

function MBTIRoles.Data.isValidCombo(roleId, typeCode)
    local t = D.Types[typeCode]
    return t ~= nil and t.role == roleId
end

--- Registry object from MBTIRolesRegistries (if loaded)
function MBTIRoles.Data.roleRegistry(roleId)
    if not MBTIRolesRegistries then return nil end
    return MBTIRolesRegistries[roleId]
end

function MBTIRoles.Data.typeRegistry(typeCode)
    if not MBTIRolesRegistries then return nil end
    return MBTIRolesRegistries[typeCode]
end

--- Script / registry id string (e.g. "MBTIRoles:INTJ")
function MBTIRoles.Data.roleTraitId(roleId)
    if not D.Roles[roleId] then return nil end
    return "MBTIRoles:" .. roleId
end

function MBTIRoles.Data.typeTraitId(typeCode)
    if not D.Types[typeCode] then return nil end
    return "MBTIRoles:" .. typeCode
end

-- Back-compat aliases used in P0 docs
function MBTIRoles.Data.roleTrait(roleId)
    return MBTIRoles.Data.roleTraitId(roleId)
end

function MBTIRoles.Data.typeTrait(typeCode)
    return MBTIRoles.Data.typeTraitId(typeCode)
end

-- ---------------------------------------------------------------------------
-- MVP effect defaults (strength scaled later by sandbox) — live in P2+
-- xpMult: 1.0 = no change; 1.15 = +15%
-- ---------------------------------------------------------------------------
-- Mood: unhappiness/boredom/stress deltas are negative = good (reduction)
D.RoleEffects = {
    Analyst = {
        xpMult = { Electricity = 1.15, Mechanics = 1.15, Literature = 1.10, PlantScavenging = 0.90 },
        -- B42 recipe research timed action (ISResearchRecipe). 0.85 = 15% faster.
        researchTimeMult = 0.85,
        -- Mood when researching a new craft recipe from an item
        researchMood = {
            unhappiness = -6,
            boredom = -8,
            stress = -4,
            cooldownHours = 0.25,
        },
    },
    Diplomat = {
        xpMult = { Doctor = 1.15, Literature = 1.10 },
        flags = { empathyStress = true, pictureMood = true, mementoMood = true },
        pictureMood = {
            unhappiness = -8,
            boredom = -5,
            stress = -3,
            cooldownHours = 0.5,
        },
        -- Cards, keepsakes, doodles, and other base:ismemento items
        mementoMood = {
            unhappiness = -7,
            boredom = -5,
            stress = -4,
            cooldownHours = 0.5,
        },
    },
    Sentinel = {
        xpMult = { Farming = 1.15, Maintenance = 1.15 },
        flags = { routineMood = true, harvestMood = true },
        -- Mood when harvesting a plant (duty / garden payoff)
        harvestMood = {
            unhappiness = -6,
            boredom = -4,
            stress = -5,
            cooldownHours = 0.35,
        },
    },
    Explorer = {
        xpMult = { PlantScavenging = 1.15, Aiming = 1.10, Literature = 0.90 },
        flags = { brochureMood = true, forageMood = true },
        -- Primary: reading Brochures / Fliers (local maps, ads, places to go)
        brochureMood = {
            unhappiness = -7,
            boredom = -10,
            stress = -4,
            cooldownHours = 0.35,
        },
        -- Small secondary: forage finds
        forageMood = {
            unhappiness = -2,
            boredom = -3,
            stress = -1,
            cooldownHours = 0.5,
        },
    },
}

D.TypeEffects = {
    -- Phase C: Strategic Solitude (alone / research)
    INTJ = {
        xpMult = { Mechanics = 1.05 },
        flags = { aloneComfort = true, strategicSolitude = true },
        focus = {
            chancePercent = 20,
            unhappiness = -5,
            boredom = -4,
            stress = -3,
            cooldownHours = 6,
            mechXpBonus = 0.08,
            xpHours = 2,
        },
    },
    -- Phase B: Pattern Spotter
    INTP = {
        xpMult = { Electricity = 1.05 },
        flags = { patternSpotter = true },
        pattern = {
            needStreak = 3,
            chancePercent = 75,
            unhappiness = -3,
            boredom = -6,
            stress = -2,
            cooldownHours = 4,
            elecXpBonus = 0.08,
            xpHours = 2,
        },
    },
    -- Phase C: Command Presence (fitness / discipline)
    ENTJ = {
        xpMult = { Strength = 1.05 },
        flags = { commandPresence = true },
        command = {
            chancePercent = 35,
            unhappiness = -3,
            boredom = -4,
            stress = -3,
            cooldownHours = 4,
            strengthXpBonus = 0.08,
            xpHours = 2,
        },
    },
    -- Phase C: Improviser (craft / research variety)
    ENTP = {
        xpMult = { MetalWelding = 1.05 },
        flags = { improviser = true },
        improvise = {
            chancePercent = 22,
            unhappiness = -2,
            boredom = -7,
            stress = -2,
            cooldownHours = 3,
            weldXpBonus = 0.08,
            xpHours = 2,
        },
    },

    -- Phase A type hooks (v0.5)
    INFJ = {
        xpMult = { Doctor = 1.05 },
        flags = { quietReflection = true },
        reflection = {
            chancePercent = 15,
            unhappiness = -5,
            boredom = -3,
            stress = -4,
            cooldownHours = 8,
            litXpBonus = 0.08,
            litXpHours = 2,
        },
    },
    INFP = {
        xpMult = { Literature = 1.05 },
        flags = { mementoKeeper = true },
        keepsake = {
            maxKeepsakes = 5,
            unhappiness = -4,
            boredom = -3,
            stress = -3,
            cooldownHours = 6,
        },
    },
    -- Phase C: Social Warmth (near people / radio)
    ENFJ = {
        xpMult = { Doctor = 1.05 },
        flags = { socialComfort = true },
        social = {
            chancePercent = 25,
            unhappiness = -5,
            boredom = -4,
            stress = -3,
            cooldownHours = 5,
            doctorXpBonus = 0.08,
            xpHours = 2,
        },
    },
    -- Phase B: Spark of Possibility
    ENFP = {
        xpMult = { PlantScavenging = 1.05 },
        flags = { sparkOfPossibility = true },
        inspired = {
            chancePercent = 12,
            unhappiness = -4,
            boredom = -7,
            stress = -2,
            cooldownHours = 20, -- ~1/day at most
            randomXpBonus = 0.08,
            xpHours = 2,
        },
    },

    ISTJ = {
        xpMult = { Maintenance = 1.05 },
        flags = { dutyRoster = true },
        routine = {
            unhappiness = -3,
            boredom = -4,
            stress = -3,
            maxStack = 3,
            cooldownHours = 20,
        },
    },
    -- Phase C: Caregiver (bandage / stitch)
    ISFJ = {
        xpMult = { Doctor = 1.05 },
        flags = { caregiver = true },
        care = {
            chancePercent = 40,
            unhappiness = -5,
            boredom = -3,
            stress = -4,
            cooldownHours = 3,
            doctorXpBonus = 0.08,
            xpHours = 2,
        },
    },
    -- Phase C: Take Charge (barricade / destroy)
    ESTJ = {
        xpMult = { Blunt = 1.05 },
        flags = { takeCharge = true },
        charge = {
            chancePercent = 30,
            unhappiness = -3,
            boredom = -4,
            stress = -4,
            cooldownHours = 3,
            bluntXpBonus = 0.08,
            xpHours = 2,
        },
    },
    -- Phase C: Host (harvest / cooking care)
    ESFJ = {
        xpMult = { Cooking = 1.05 },
        flags = { host = true },
        host = {
            chancePercent = 35,
            unhappiness = -4,
            boredom = -4,
            stress = -2,
            cooldownHours = 4,
            cookXpBonus = 0.08,
            xpHours = 2,
        },
    },

    -- Phase B: Practical Fixer (patch low-condition gear, add padding, engine)
    ISTP = {
        xpMult = { SmallBlade = 1.05 },
        flags = { practicalFixer = true },
        fixer = {
            maxCondition = 0.55, -- patch/repair gate; Add Padding always eligible
            unhappiness = -3,
            boredom = -4,
            stress = -2,
            cooldownHours = 3,
            maintXpBonus = 0.10,
            xpHours = 2,
        },
    },
    ISFP = {
        xpMult = { PlantScavenging = 1.05 },
        flags = { sensoryAnchor = true },
        outdoors = {
            unhappiness = -3,
            boredom = -5,
            stress = -2,
            cooldownHours = 3,
        },
    },
    -- Phase B: Opportunistic Spark
    ESTP = {
        xpMult = { Aiming = 1.05 },
        flags = { opportunisticSpark = true },
        alert = {
            chancePercent = 18,
            unhappiness = -2,
            boredom = -5,
            stress = -3,
            cooldownHours = 3,
            forageXpBonus = 0.08,
            sneakXpBonus = 0.06,
            xpHours = 1.5,
        },
    },
    -- Phase C: Spotlight (radio / outdoors vibe)
    ESFP = {
        xpMult = { Lightfoot = 1.05 },
        flags = { spotlight = true },
        vibe = {
            chancePercent = 22,
            unhappiness = -4,
            boredom = -6,
            stress = -2,
            cooldownHours = 4,
            lightfootXpBonus = 0.08,
            xpHours = 2,
        },
    },
}

print("[MBTIRoles] Data locked: 4 roles x 4 types loaded.")
