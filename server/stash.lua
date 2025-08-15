FW = FW or {}

local function ensureStash(ref, slots)
  local row = MySQL.single.await("SELECT container_id FROM containers WHERE type='STASH' AND ref=? LIMIT 1", { ref })
  if not row then
    MySQL.query.await("INSERT INTO containers(type, ref, slots, weight_limit) VALUES ('STASH', ?, ?, 200.0)", { ref, slots or 30 })
    row = MySQL.single.await("SELECT LAST_INSERT_ID() AS id", {})
    local cid = row.id
    for i=1,(slots or 30) do
      MySQL.insert.await("INSERT INTO container_slots(container_id,slot_index,locked,tag) VALUES (?,?,0,NULL)", { cid, i })
    end
    return cid
  end
  return row.container_id
end

exports('SFW_StashPayload', function(ref, ident)
  local cid = ensureStash(ref, 42)
  local pcid = exports['survivalfw']:SFW_PlayerContainerId(ident)
  local payload = {
    player = exports['survivalfw']:SFW_FetchStacks(pcid),
    stash = exports['survivalfw']:SFW_FetchStacks(cid),
    stash_id = cid,
    player_id = pcid
  }
  return payload
end)
