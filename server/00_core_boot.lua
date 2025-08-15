-- SFW 00_core_boot (generated minimal)
FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}
if type(FW.GetIdentifier) ~= 'function' then
  function FW.GetIdentifier(src)
    local ids = GetPlayerIdentifiers(src) or {}
    for _,id in ipairs(ids) do if id:find("^license:") then return id end end
    return ids[1]
  end
end
if type(FW.DB.players.fetchPlayer) ~= 'function' then
  function FW.DB.players.fetchPlayer(identifier)
    if not identifier then return nil end
    return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
  end
end
if type(FW.DB.players.updatePlayer) ~= 'function' then
  function FW.DB.players.updatePlayer(identifier, patch)
    if not identifier or type(patch) ~= 'table' then return 0 end
    local allow = {
      display_name=true, role=true,
      health=true, stamina=true, hunger=true, thirst=true, temperature_c=true,
      citizen_id=true, first_name=true, last_name=true, dob=true, sex=true,
      height_cm=true, blood_type=true, nationality=true,
      pos_x=true, pos_y=true, pos_z=true, pos_h=true,
      appearance_set=true
    }
    local cols, vals = {}, {}
    for k,v in pairs(patch) do
      if allow[k] then cols[#cols+1] = ("`%s`=?"):format(k); vals[#vals+1] = v end
    end
    if #cols == 0 then return 0 end
    vals[#vals+1] = identifier
    local sql = ("UPDATE players SET %s, updated_at=NOW() WHERE BINARY identifier=BINARY ?")
      :format(table.concat(cols, ","))
    return MySQL.update.await(sql, vals) or 0
  end
end
print("^2[SFW] 00_core_boot (generated) loaded^7")
