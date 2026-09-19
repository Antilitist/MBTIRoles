--[[
  MBTI Roles — CharacterTrait registries (B42.20+)
  Source of truth for trait keys used by hasTrait / character_trait_definition.
]]

MBTIRolesRegistries = MBTIRolesRegistries or {}

---------------------------------------------------------
----                     ROLES                       ----
---------------------------------------------------------
MBTIRolesRegistries.Analyst  = CharacterTrait.register("MBTIRoles:Analyst")
MBTIRolesRegistries.Diplomat = CharacterTrait.register("MBTIRoles:Diplomat")
MBTIRolesRegistries.Sentinel = CharacterTrait.register("MBTIRoles:Sentinel")
MBTIRolesRegistries.Explorer = CharacterTrait.register("MBTIRoles:Explorer")

---------------------------------------------------------
----                    TYPES                        ----
---------------------------------------------------------
-- Analysts
MBTIRolesRegistries.INTJ = CharacterTrait.register("MBTIRoles:INTJ")
MBTIRolesRegistries.INTP = CharacterTrait.register("MBTIRoles:INTP")
MBTIRolesRegistries.ENTJ = CharacterTrait.register("MBTIRoles:ENTJ")
MBTIRolesRegistries.ENTP = CharacterTrait.register("MBTIRoles:ENTP")

-- Diplomats
MBTIRolesRegistries.INFJ = CharacterTrait.register("MBTIRoles:INFJ")
MBTIRolesRegistries.INFP = CharacterTrait.register("MBTIRoles:INFP")
MBTIRolesRegistries.ENFJ = CharacterTrait.register("MBTIRoles:ENFJ")
MBTIRolesRegistries.ENFP = CharacterTrait.register("MBTIRoles:ENFP")

-- Sentinels
MBTIRolesRegistries.ISTJ = CharacterTrait.register("MBTIRoles:ISTJ")
MBTIRolesRegistries.ISFJ = CharacterTrait.register("MBTIRoles:ISFJ")
MBTIRolesRegistries.ESTJ = CharacterTrait.register("MBTIRoles:ESTJ")
MBTIRolesRegistries.ESFJ = CharacterTrait.register("MBTIRoles:ESFJ")

-- Explorers
MBTIRolesRegistries.ISTP = CharacterTrait.register("MBTIRoles:ISTP")
MBTIRolesRegistries.ISFP = CharacterTrait.register("MBTIRoles:ISFP")
MBTIRolesRegistries.ESTP = CharacterTrait.register("MBTIRoles:ESTP")
MBTIRolesRegistries.ESFP = CharacterTrait.register("MBTIRoles:ESFP")
