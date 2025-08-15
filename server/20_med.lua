-- SFW 20_med — self-contained bleeding tick with caching
FW = FW or {}

local STATE = {}

local function getIdent(src)
  if FW.GetIdentifier then return FW.GetIdentifier(src) end
  local ids = GetPlayerIdentifiers(src) or {}
  for _,id in ipairs(ids) do if id:find("^license:") then return id end end
  return ids[1]
end

local function db_bleed_sum(identifier)
  local val = MySQL.scalar.await([[ 
    SELECT COALESCE(SUM(severity),0) FROM effects_active
    WHERE identifier=? AND effect_type='BLEEDING' AND (expires_at IS NULL OR expires_at > NOW())
  ]], { identifier })
  return tonumber(val) or 0
end

local function db_fetch_hp(identifier)
  local row = MySQL.single.await("SELECT health FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
  return row and tonumber(row.health) or 100
end

local function flush_player(src)
  local st = STATE[src]
  if not st or not st.dirty then return end
  MySQL.prepare.await("UPDATE players SET health=?, updated_at=NOW() WHERE BINARY identifier=BINARY ?", {
    { st.hp, st.ident }
  })
  st.dirty = false
end

local function flush_all()
  local params = {}
  for _, st in pairs(STATE) do
    if st.dirty then
      params[#params+1] = { st.hp, st.ident }
      st.dirty = false
    end
  end
  if #params > 0 then
    MySQL.prepare.await("UPDATE players SET health=?, updated_at=NOW() WHERE BINARY identifier=BINARY ?", params)
  end
end

RegisterCommand('medflush', function(src)
  if src == 0 then flush_all() end
end, true)

AddEventHandler('playerJoining', function()
  local src = source
  local ident = getIdent(src); if not ident then return end
  STATE[src] = {
    ident = ident,
    hp = db_fetch_hp(ident),
    sev = db_bleed_sum(ident),
    dirty = false
  }
end)

AddEventHandler('playerDropped', function()
  local src = source
  flush_player(src)
  STATE[src] = nil
end)

local function fetch_bleeds(sources)
  local idents = {}
  local idx = {}
  for i, src in ipairs(sources) do
    local st = STATE[src]
    if st then
      idents[#idents+1] = st.ident
      idx[st.ident] = src
    end
  end
  if #idents == 0 then return {} end
  local marks = {}
  for i=1,#idents do marks[i] = '?' end
  local sql = [[
    SELECT identifier, COALESCE(SUM(severity),0) AS sev FROM effects_active
    WHERE effect_type='BLEEDING' AND identifier IN (]]..table.concat(marks,',')..[[)
      AND (expires_at IS NULL OR expires_at > NOW())
    GROUP BY identifier
  ]]
  local rows = MySQL.query.await(sql, idents) or {}
  local map = {}
  for _, r in ipairs(rows) do map[idx[r.identifier]] = tonumber(r.sev) or 0 end
  return map
end

local function tick_all()
  local players = {}
  for _, sid in ipairs(GetPlayers()) do
    players[#players+1] = tonumber(sid) or sid
  end
  tick_players(players)
end

CreateThread(function()
  while true do
    tick_all()
    Wait(2000)
  end
end)

CreateThread(function()
  while true do
    Wait(10000)
    flush_all()
  end
end)

RegisterNetEvent('fw:med:flush', flush_all)

local function tick_players(list)
  if not list or #list == 0 then return end
  local bleed = fetch_bleeds(list)
  for _, src in ipairs(list) do
    local st = STATE[src]
    if st then
      local sev = bleed[src] or 0
      st.sev = sev
      if sev > 0 then
        local dmg = math.max(1, math.floor(sev * 0.05))
        local newHp = math.max(0, st.hp - dmg)
        if newHp ~= st.hp then st.hp = newHp; st.dirty = true end
        TriggerClientEvent('fw:hud:effects', src, { { type='BLEEDING', severity=sev } })
      end
    end
  end
end

RegisterNetEvent('fw:med:bleed:tickOne', function(target)
  tick_players({ tonumber(target) or target or source })
end)
