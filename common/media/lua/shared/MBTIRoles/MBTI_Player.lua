--[[
  MBTIRoles — player trait scan, validation, modData sync (P1)
]]

MBTIRoles = MBTIRoles or {}
MBTIRoles.Player = MBTIRoles.Player or {}

local D = MBTIRoles.Data

local function safeHasTrait(player, reg)
    if not player or not reg then return false end
    local ok, result = pcall(function()
        return player:hasTrait(reg)
    end)
    return ok and result == true
end

local function safeAddTrait(player, reg)
    if not player or not reg then return end
    pcall(function()
        if not player:hasTrait(reg) then
            player:getCharacterTraits():add(reg)
        end
    end)
end

local function safeRemoveTrait(player, reg)
    if not player or not reg then return end
    pcall(function()
        if player:hasTrait(reg) then
            player:getCharacterTraits():remove(reg)
        end
    end)
end

--- Scan character traits for MBTI role + type
-- @return roleId, typeCode (either may be nil)
function MBTIRoles.Player.scanTraits(player)
    if not player or not MBTIRolesRegistries then
        return nil, nil
    end

    local roleId = nil
    for _, rid in ipairs(D.RoleOrder) do
        if safeHasTrait(player, MBTIRolesRegistries[rid]) then
            roleId = rid
            break
        end
    end

    local typeCode = nil
    for _, code in ipairs(D.TypeOrder) do
        if safeHasTrait(player, MBTIRolesRegistries[code]) then
            typeCode = code
            break
        end
    end

    return roleId, typeCode
end

--- Ensure role matches type; grant missing role from type; store modData
-- @param player IsoPlayer
-- @param opts table|nil  { announce = bool }
-- @return table modData snapshot
function MBTIRoles.Player.syncFromTraits(player, opts)
    opts = opts or {}
    if not player or not player.getModData then
        return nil
    end

    local roleId, typeCode = MBTIRoles.Player.scanTraits(player)
    local fixed = false

    -- Type wins: ensure matching role is present
    if typeCode then
        local expectedRole = D.getRoleForType(typeCode)
        if expectedRole then
            if roleId and roleId ~= expectedRole then
                -- Remove wrong role traits
                for _, rid in ipairs(D.RoleOrder) do
                    if rid ~= expectedRole then
                        safeRemoveTrait(player, MBTIRolesRegistries[rid])
                    end
                end
                fixed = true
            end
            safeAddTrait(player, MBTIRolesRegistries[expectedRole])
            roleId = expectedRole
        end
    end

    -- Re-scan after fixes
    roleId, typeCode = MBTIRoles.Player.scanTraits(player)

    local typeInfo = typeCode and D.Types[typeCode] or nil
    local roleInfo = roleId and D.Roles[roleId] or nil

    local md = player:getModData()
    md.MBTIRoles = md.MBTIRoles or {}
    md.MBTIRoles.roleId = roleId
    md.MBTIRoles.typeCode = typeCode
    md.MBTIRoles.typeName = typeInfo and typeInfo.name or nil
    md.MBTIRoles.roleName = roleInfo and roleInfo.name or nil
    md.MBTIRoles.pattern = roleInfo and roleInfo.pattern or nil
    md.MBTIRoles.complete = (roleId ~= nil and typeCode ~= nil)
    md.MBTIRoles.syncedAt = getTimestamp and getTimestamp() or nil

    if opts.announce then
        if md.MBTIRoles.complete then
            print("[MBTIRoles] " .. tostring(MBTIRoles.Player.formatLabel(player)))
        elseif roleId and not typeCode then
            print("[MBTIRoles] Role only: " .. tostring(roleId) .. " (pick a Type trait for full MBTI)")
        elseif not roleId and not typeCode then
            print("[MBTIRoles] No MBTI Role/Type selected.")
        end
    end

    if fixed then
        print("[MBTIRoles] Fixed role/type mismatch -> " .. tostring(roleId) .. " / " .. tostring(typeCode))
    end

    return md.MBTIRoles
end

function MBTIRoles.Player.getModData(player)
    if not player or not player.getModData then return nil end
    local md = player:getModData().MBTIRoles
    if not md then
        return MBTIRoles.Player.syncFromTraits(player)
    end
    return md
end

--- Human-readable label: "Analyst - INTJ (Architect)" or partial
function MBTIRoles.Player.formatLabel(player)
    local md = MBTIRoles.Player.getModData(player)
    if not md or (not md.roleId and not md.typeCode) then
        return getText("UI_MBTI_None")
    end
    if md.complete then
        local name = md.typeName or ""
        return string.format("%s - %s (%s)", md.roleName or md.roleId, md.typeCode, name)
    end
    if md.roleId and not md.typeCode then
        return string.format("%s - %s", md.roleName or md.roleId, getText("UI_MBTI_PickTypeHint"))
    end
    if md.typeCode then
        return tostring(md.typeCode)
    end
    return getText("UI_MBTI_None")
end

function MBTIRoles.Player.hasComplete(player)
    local md = MBTIRoles.Player.getModData(player)
    return md and md.complete == true
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local function onCreatePlayer(playerIndex, player)
    -- B42: OnCreatePlayer(playerIndex, player) in some builds; also (id) only
    local p = player
    if not p and type(playerIndex) == "number" then
        p = getSpecificPlayer(playerIndex)
    end
    if not p and instanceof(playerIndex, "IsoPlayer") then
        p = playerIndex
    end
    if p then
        MBTIRoles.Player.syncFromTraits(p, { announce = false })
    end
end

local function onNewGame(player, square)
    if player then
        MBTIRoles.Player.syncFromTraits(player, { announce = true })
    end
end

local function onGameStart()
    local p = getPlayer and getPlayer() or nil
    if p then
        MBTIRoles.Player.syncFromTraits(p, { announce = false })
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnNewGame.Add(onNewGame)
Events.OnGameStart.Add(onGameStart)

print("[MBTIRoles] Player sync (P1) loaded.")
