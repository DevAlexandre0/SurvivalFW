FW = FW or {}; FW.DB = FW.DB or {}

local function getIdentifier(src)
  if FW.GetIdentifier then return FW.GetIdentifier(src) end
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:sub(1,8) == "license:" then return id end
  end
  return nil
end

local DEFAULT_MODEL = 'mp_m_freemode_01'

local function getAppearance(ident)
  return MySQL.single.await("SELECT model, components, props, outfit_tag FROM player_appearance WHERE identifier=?", { ident })
end

local function setAppearance(ident, model, comps, props, tag)
  local row = getAppearance(ident)
  if row then
    MySQL.update.await("UPDATE player_appearance SET model=?, components=?, props=?, outfit_tag=? WHERE identifier=?",
      { model, comps, props, tag, ident })
  else
    MySQL.insert.await("INSERT INTO player_appearance(identifier,model,components,props,outfit_tag) VALUES (?,?,?,?,?)",
      { ident, model, comps, props, tag })
  end
end

RegisterNetEvent('fw:wardrobe:save', function(payload)
  local src = source
  local ident = getIdentifier(src); if not ident then return end
  if type(payload) ~= 'table' then return end
  local model = payload.model or DEFAULT_MODEL
  local comps = payload.components or {}
  local props = payload.props or {}
  local tag   = payload.outfit_tag or nil
  setAppearance(ident, model, json.encode(comps), (next(props) and json.encode(props) or nil), tag)
  TriggerClientEvent('fw:wardrobe:saved', src, true)
end)

RegisterNetEvent('fw:wardrobe:pull', function()
  local src = source
  local ident = getIdentifier(src); if not ident then return end
  local ap = getAppearance(ident)
  if ap then
    TriggerClientEvent('fw:wardrobe:applySaved', src, ap)
  end
end)
