--[[
  MBTIRoles — role mood boosts (P2)
  Diplomat : pictures / picture books; mementos (ismemento / DisplayCategory Memento)
  Analyst  : research a new recipe (ISResearchRecipe)
  Sentinel : harvest crops (ISHarvestPlantAction)
  Explorer : Brochures / Fliers (primary); small forage mood
]]

require "TimedActions/ISReadABook"
require "TimedActions/ISResearchRecipe"
require "Farming/TimedActions/ISHarvestPlantAction"
require "Foraging/ISForageAction"

MBTIRoles = MBTIRoles or {}
MBTIRoles.Mood = MBTIRoles.Mood or {}

local D = MBTIRoles.Data

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function getRoleId(character)
    if not character or not character.getModData then return nil end
    local md = character:getModData().MBTIRoles
    if not md or not md.roleId then
        if MBTIRoles.Player and MBTIRoles.Player.syncFromTraits then
            MBTIRoles.Player.syncFromTraits(character, { announce = false })
            md = character:getModData().MBTIRoles
        end
    end
    return md and md.roleId or nil
end

local function clampStat(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function applyDelta(character, stat, delta)
    if not delta or delta == 0 then return end
    local stats = character:getStats()
    if not stats then return end
    local cur = stats:get(stat)
    if cur == nil then return end
    local hi = (cur > 1.5) and 100 or 1
    local nextVal
    if hi <= 1 and math.abs(delta) > 1 then
        nextVal = clampStat(cur + (delta / 100.0), 0, 1)
    else
        nextVal = clampStat(cur + delta, 0, hi)
    end
    stats:set(stat, nextVal)
end

local function applyMoodCfg(character, cfg)
    if not cfg then return end
    if CharacterStat then
        if cfg.unhappiness then
            applyDelta(character, CharacterStat.UNHAPPINESS, cfg.unhappiness)
        end
        if cfg.boredom then
            applyDelta(character, CharacterStat.BOREDOM, cfg.boredom)
        end
        if cfg.stress then
            applyDelta(character, CharacterStat.STRESS, cfg.stress)
        end
    end
    if cfg.unhappiness then
        pcall(function()
            local bd = character:getBodyDamage()
            if bd and bd.getUnhappynessLevel and bd.setUnhappynessLevel then
                local u = bd:getUnhappynessLevel()
                local nu = u + cfg.unhappiness
                if nu < 0 then nu = 0 end
                if nu > 100 then nu = 100 end
                bd:setUnhappynessLevel(nu)
            end
        end)
    end
end

local function worldHours()
    local now = 0
    pcall(function()
        now = getGameTime():getWorldAgeHours()
    end)
    return now
end

--- Generic role mood boost with cooldown
-- @param character IsoPlayer
-- @param expectedRole string e.g. "Diplomat"
-- @param cfgKey string field on RoleEffects[role] e.g. "pictureMood"
-- @param cooldownField string modData key for last boost time
-- @param haloTextKey string translation key
-- @return boolean applied
--- Apply a design mood cfg with cooldown (no role check). Used by Role + Type hooks.
-- alreadyScaled=true skips MoodStrengthPercent scaling (Type hooks use TypeHooksStrength).
function MBTIRoles.Mood.applyPersonal(character, designCfg, cooldownField, haloTextKey, alreadyScaled)
    if not character or not designCfg then return false end
    if MBTIRoles.Config and not MBTIRoles.Config.isEnabled() then return false end

    local cfg = designCfg
    if not alreadyScaled then
        if MBTIRoles.Config and MBTIRoles.Config.scaleMoodCfg then
            cfg = MBTIRoles.Config.scaleMoodCfg(designCfg)
            if not cfg then return false end
        end
    end

    local pmd = character:getModData()
    pmd.MBTIRoles = pmd.MBTIRoles or {}
    local now = worldHours()
    local cooldown = (cfg and cfg.cooldownHours) or designCfg.cooldownHours or 0.5
    local last = pmd.MBTIRoles[cooldownField]
    if last and now > 0 and (now - last) < cooldown then
        return false
    end
    pmd.MBTIRoles[cooldownField] = now

    applyMoodCfg(character, cfg)

    if haloTextKey then
        pcall(function()
            if HaloTextHelper and HaloTextHelper.addGoodText then
                local msg = haloTextKey
                pcall(function() msg = getText(haloTextKey) end)
                HaloTextHelper.addGoodText(character, msg)
            end
        end)
    end
    return true
end

function MBTIRoles.Mood.tryBoost(character, expectedRole, cfgKey, cooldownField, haloTextKey)
    if not character then return false end
    if MBTIRoles.Config and not MBTIRoles.Config.isEnabled() then return false end

    local roleId = getRoleId(character)
    if roleId ~= expectedRole then return false end

    local effects = D and D.RoleEffects and D.RoleEffects[expectedRole]
    local cfg = effects and effects[cfgKey]
    if not cfg then return false end

    return MBTIRoles.Mood.applyPersonal(character, cfg, cooldownField, haloTextKey)
end

-- ---------------------------------------------------------------------------
-- Literature helpers (read / look-at)
-- ---------------------------------------------------------------------------
local function getItemType(item)
    local tOk, t = pcall(function() return item:getType() end)
    if tOk then return t end
    return nil
end

--- Brochures & Fliers (Explorer primary mood). Vanilla tags them as picture too.
local function isBrochureOrFlier(item)
    if not item then return false end
    local t = getItemType(item)
    if not t then return false end
    if t == "Brochure" then return true end
    if t == "Flier" or string.find(t, "Flier", 1, true) == 1 then return true end
    return false
end

--- Photos / postcards / picture books for Diplomat — excludes brochures & fliers
local function isPictureItem(item)
    if not item then return false end
    if isBrochureOrFlier(item) then return false end

    local ok, isPic = pcall(function() return item:hasTag(ItemTag.PICTURE) end)
    if ok and isPic then return true end
    local ok2, isBook = pcall(function() return item:hasTag(ItemTag.PICTUREBOOK) end)
    if ok2 and isBook then return true end
    local rtOk, rt = pcall(function() return item:getReadType() end)
    if rtOk and rt == "photo" then
        -- ReadType photo includes brochures; already excluded above
        local t = getItemType(item)
        if t and (string.find(t, "Photo", 1, true) or string.find(t, "Postcard", 1, true)
            or string.find(t, "Picture", 1, true)) then
            return true
        end
        -- Generic picture tag items that aren't brochures
        if ok and isPic then return true end
    end
    local t = getItemType(item)
    if t then
        if string.find(t, "Photo", 1, true)
            or string.find(t, "Picture", 1, true)
            or string.find(t, "Postcard", 1, true)
        then
            return true
        end
    end
    return false
end

--- Mementos: only DisplayCategory + type-name (no hasTag/getTags — crash on many B42 items)
local function isMementoItem(item)
    if item == nil then return false end

    local ok, result = pcall(function()
        -- Brochures/fliers are Explorer, not mementos
        local t = nil
        if item.getType then
            t = item:getType()
        end
        if t == "Brochure" then return false end
        if t and string.find(t, "Flier", 1, true) == 1 then return false end

        if item.getDisplayCategory then
            local cat = item:getDisplayCategory()
            if cat == "Memento" or cat == "memento" then
                return true
            end
        end

        if t then
            if string.find(t, "Photo", 1, true) then return true end
            if string.find(t, "Postcard", 1, true) then return true end
            if string.find(t, "Card_", 1, true) == 1 then return true end
            if string.find(t, "Doodle", 1, true) then return true end
            if t == "Dice" or string.find(t, "Dice_", 1, true) == 1 then return true end
            if t == "Harmonica" then return true end
            if string.find(t, "Spiffo", 1, true) then return true end
            if string.find(t, "Ornament", 1, true) then return true end
        end
        return false
    end)

    return ok and result == true
end

function MBTIRoles.Mood.isMementoItem(item)
    local ok, res = pcall(isMementoItem, item)
    return ok and res == true
end

function MBTIRoles.Mood.isPictureItem(item)
    return isPictureItem(item)
end

function MBTIRoles.Mood.onPictureLooked(character, item)
    if not isPictureItem(item) then return end
    MBTIRoles.Mood.tryBoost(character, "Diplomat", "pictureMood", "lastPictureMoodHours", "UI_MBTI_PictureMood")
end

--- Memento mood: cards, keepsakes, doodles, etc.
-- Photos that are also mementos already get pictureMood; use mementoMood only when
-- not classified as a picture (or picture boost was on cooldown — still try memento).
function MBTIRoles.Mood.onMemento(character, item)
    if not isMementoItem(item) then return end
    -- If this is primarily a picture (photo/postcard/picturebook), picture hook handles it
    if isPictureItem(item) then return end
    MBTIRoles.Mood.tryBoost(character, "Diplomat", "mementoMood", "lastMementoMoodHours", "UI_MBTI_MementoMood")
end

function MBTIRoles.Mood.onBrochureOrFlier(character, item)
    if not isBrochureOrFlier(item) then return end
    MBTIRoles.Mood.tryBoost(character, "Explorer", "brochureMood", "lastBrochureMoodHours", "UI_MBTI_BrochureMood")
end

local _readComplete = ISReadABook.complete
function ISReadABook:complete()
    local result = _readComplete(self)
    if self.character and self.item then
        pcall(function()
            MBTIRoles.Mood.onBrochureOrFlier(self.character, self.item)
            MBTIRoles.Mood.onPictureLooked(self.character, self.item)
            MBTIRoles.Mood.onMemento(self.character, self.item)
        end)
    end
    return result
end

-- Holding a physical memento in either hand (Diplomat only)
local function checkHeldMemento(player)
    if not player then return end
    if getRoleId(player) ~= "Diplomat" then return end

    local item = nil
    pcall(function() item = player:getPrimaryHandItem() end)
    if not isMementoItem(item) then
        item = nil
        pcall(function() item = player:getSecondaryHandItem() end)
    end
    if not isMementoItem(item) then return end

    -- Photos use picture mood path on look-at, not hold spam
    if isPictureItem(item) then return end

    local pmd = player:getModData()
    if not pmd then return end
    pmd.MBTIRoles = pmd.MBTIRoles or {}
    local id = nil
    pcall(function() id = item:getID() end)
    if id and pmd.MBTIRoles.lastHeldMementoId == id then
        return
    end
    if id then pmd.MBTIRoles.lastHeldMementoId = id end

    MBTIRoles.Mood.tryBoost(player, "Diplomat", "mementoMood", "lastMementoMoodHours", "UI_MBTI_MementoMood")
end

Events.EveryOneMinute.Add(function()
    local ok, p = pcall(function() return getPlayer() end)
    if ok and p then
        pcall(checkHeldMemento, p)
    end
end)

-- ---------------------------------------------------------------------------
-- Analyst — research new recipes
-- ---------------------------------------------------------------------------
function MBTIRoles.Mood.onResearchComplete(character, hadResearchable)
    if not hadResearchable then return end
    MBTIRoles.Mood.tryBoost(character, "Analyst", "researchMood", "lastResearchMoodHours", "UI_MBTI_ResearchMood")
end

local _researchComplete = ISResearchRecipe.complete
function ISResearchRecipe:complete()
    local hadResearchable = false
    pcall(function()
        if self.scriptItem and self.character then
            local list = self.scriptItem:getResearchableRecipes(self.character, true)
            if list and list:size() > 0 then
                hadResearchable = true
            end
        end
    end)
    local result = _researchComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.Mood.onResearchComplete(self.character, hadResearchable)
        end)
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Sentinel — harvest crops (duty / sustain payoff)
-- ---------------------------------------------------------------------------
function MBTIRoles.Mood.onHarvest(character)
    MBTIRoles.Mood.tryBoost(character, "Sentinel", "harvestMood", "lastHarvestMoodHours", "UI_MBTI_HarvestMood")
end

local _harvestComplete = ISHarvestPlantAction.complete
function ISHarvestPlantAction:complete()
    local result = _harvestComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.Mood.onHarvest(self.character)
        end)
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Explorer — forage finds (field / present-moment)
-- ---------------------------------------------------------------------------
function MBTIRoles.Mood.onForage(character)
    MBTIRoles.Mood.tryBoost(character, "Explorer", "forageMood", "lastForageMoodHours", "UI_MBTI_ForageMood")
end

local _forageComplete = ISForageAction.complete
function ISForageAction:complete()
    local result = _forageComplete(self)
    if self.character then
        pcall(function()
            MBTIRoles.Mood.onForage(self.character)
        end)
    end
    return result
end

-- Client-side forage often finishes in perform() on non-server SP
local _foragePerform = ISForageAction.perform
function ISForageAction:perform()
    _foragePerform(self)
    if self.character and not isServer() then
        pcall(function()
            MBTIRoles.Mood.onForage(self.character)
        end)
    end
end

print("[MBTIRoles] Role mood hooks loaded (pictures / research / harvest / forage).")
