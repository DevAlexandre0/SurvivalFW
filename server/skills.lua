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
