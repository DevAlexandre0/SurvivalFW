CreateThread(function()
  Wait(1000)
  FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}
  if type(FW.DB.players.updatePlayer) ~= 'function' then
    print("^3[SFW] Late-guard: restoring FW.DB.players.updatePlayer^7")
    FW.DB.players.updatePlayer = function(identifier, patch)
      if not identifier then return 0 end
      local cols, vals = {}, {}
      local allow = {
        display_name=true, role=true,
        health=true, stamina=true, hunger=true, thirst=true, temperature_c=true,
        citizen_id=true, first_name=true, last_name=true, dob=true, sex=true,
        height_cm=true, blood_type=true, nationality=true
      }
      if type(patch) == 'table' then
        for k,v in pairs(patch) do
          if allow[k] then
            cols[#cols+1] = ("`%s`=?"):format(k)
            vals[#vals+1] = v
          end
        end
      end
      if #cols == 0 then return 0 end
      vals[#vals+1] = identifier
      local sql = ("UPDATE players SET %s, updated_at=NOW() WHERE BINARY identifier = BINARY ?")
        :format(table.concat(cols, ","))
      return MySQL.update.await(sql, vals)
    end
  end
  if type(FW.DB.players.update) ~= 'function' then
    FW.DB.players.update = FW.DB.players.updatePlayer
  end
end)
