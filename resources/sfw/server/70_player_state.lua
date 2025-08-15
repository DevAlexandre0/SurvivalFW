FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}

local __SFW_ALLOW = {
  display_name=true, role=true,
  health=true, stamina=true, hunger=true, thirst=true, temperature_c=true,
  citizen_id=true, first_name=true, last_name=true, dob=true, sex=true,
  height_cm=true, blood_type=true, nationality=true
}

local function __sfw_build_set(patch)
  local cols, vals = {}, {}
  if type(patch) == 'table' then
    for k,v in pairs(patch) do
      if __SFW_ALLOW[k] then
        cols[#cols+1] = ("`%s`=?"):format(k)
        vals[#vals+1] = v
      end
    end
  end
  return cols, vals
end

if type(FW.DB.players.updatePlayer) ~= 'function' then
  FW.DB.players.updatePlayer = function(identifier, patch)
    if not identifier then return 0 end
    local cols, vals = __sfw_build_set(patch)
    if #cols == 0 then return 0 end
    vals[#vals+1] = identifier
    local sql = ("UPDATE players SET %s, updated_at=NOW() WHERE BINARY identifier = BINARY ?")
      :format(table.concat(cols, ","))
    return MySQL.update.await(sql, vals)
  end
end

-- provide also the new name if some files use it
if type(FW.DB.players.update) ~= 'function' then
  FW.DB.players.update = FW.DB.players.updatePlayer
end


local function pushHUD(src, core, effects)
  if not src or src <= 0 then return end
  TriggerClientEvent('fw:hud:vitals', src, {
    hp   = core.health or 100,
    stam = core.stamina or 100,
    hun  = core.hunger or 0,
    ths  = core.thirst or 0,
    temp = core.temperature_c or 37.0
  })
  TriggerClientEvent('fw:hud:effects', src, effects or {})
end
RegisterNetEvent('fw:state:pull', function()
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src) or nil
  if not ident then return end
  local agg = FW.DB.getAggregatedState(ident)
  pushHUD(src, agg.core or {}, agg.effects or {})
end)
CreateThread(function()
  while true do
    FW.DB.players.updatePlayer('__noop__', {}) -- no-op, just ensure module loaded; safe
    Wait(60000)
  end
end)
-- Push HUD vitals to clients when they change

local lastVitals = {}

CreateThread(function()
  while true do
    for _, src in ipairs(GetPlayers()) do
      local ped = GetPlayerPed(src)
      local hp = GetEntityHealth(ped)
      local armor = GetPedArmour(ped)
      local snapshot = { hp = hp, armor = armor }
      local prev = lastVitals[src]
      if not prev or prev.hp ~= hp or prev.armor ~= armor then
        lastVitals[src] = snapshot
        TriggerClientEvent('fw:hud:push', src, snapshot)
      end
    end
    Wait(1000)
  end
end)

AddEventHandler('playerDropped', function()
  lastVitals[source] = nil
end)

-- Generic server->client UI opening helpers
RegisterNetEvent('fw:open:trader', function(trader_id)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local payload = exports['survivalfw']:SFW_TraderPayload(trader_id, ident) or {}
  TriggerClientEvent('fw:nui:open', src, { type='trader:open', payload=payload })
end)

RegisterNetEvent('fw:open:stash', function(stash_ref)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local payload = exports['survivalfw']:SFW_StashPayload(stash_ref, ident) or {}
  TriggerClientEvent('fw:nui:open', src, { type='stash:open', payload=payload })
end)

RegisterNetEvent('fw:open:craft', function(bench_tier)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local payload = exports['survivalfw']:SFW_CraftPayload(bench_tier or 0, ident) or {}
  TriggerClientEvent('fw:nui:open', src, { type='craft:open', payload=payload })
end)
FW = FW or {}; FW.DB = FW.DB or {}
local C = FW.DB.Contract
function FW.Skill_AddXP(ident, skill, delta, reason, ctx)
  local row = MySQL.single.await(("SELECT level, xp FROM %s WHERE identifier=? AND skill_key=?"):format(C.player_skills.table), { ident, skill })
  if not row then
    MySQL.insert.await(("INSERT INTO %s(identifier,skill_key,level,xp) VALUES (?,?,?,?)"):format(C.player_skills.table), { ident, skill, 0, delta })
  else
    local newxp = (tonumber(row.xp) or 0) + (delta or 0)
    MySQL.update.await(("UPDATE %s SET xp=? WHERE identifier=? AND skill_key=?"):format(C.player_skills.table), { newxp, ident, skill })
  end
  MySQL.insert.await(("INSERT INTO %s(identifier,skill_key,delta,reason,context) VALUES (?,?,?,?,?)"):format(C.skill_events.table), { ident, skill, delta, reason or 'OTHER', ctx and json.encode(ctx) or nil })
end
