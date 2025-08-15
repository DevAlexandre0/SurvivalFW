FW = FW or {}
FW.DB = FW.DB or {}
local C = FW.DB.Contract
local function tx(ident, action, item_key, qty, fromc, froms, toc, tos, stack_id, ctx)
  local q = "INSERT INTO %s(identifier,action,item_key,qty,from_cont,from_slot,to_cont,to_slot," .. "stack_id,context) VALUES (?,?,?,?,?,?,?,?,?,?)"
	return MySQL.insert.await(q:format(C.inv_tx.table), {ident, action, item_key, qty, fromc, froms, toc, tos, stack_id, ctx and json.encode(ctx) or nil, })
end
RegisterNetEvent("fw:inv:moveStrict", function(payload)
	local src = source
	if not (FW.RL and FW.RL.Check(src, "inv_move", 500)) then
		return
	end
	if type(payload) ~= "table" then
		return
	end
	local ident = FW.GetIdentifier and FW.GetIdentifier(src)
	if not ident then
		return
	end
	local fromc, froms = tonumber(payload.from_container), tonumber(payload.from_slot)
	local toc, tos = tonumber(payload.to_container), tonumber(payload.to_slot)
	local amount = tonumber(payload.amount or 0)
	if not fromc or not froms or not toc or not tos then
		return
	end
	local from = MySQL.single.await(
		("SELECT * FROM %s WHERE container_id=? AND slot_index=?"):format(C.stacks.table),
		{ fromc, froms }
	)
	if not from then
		TriggerClientEvent("fw:inv:error", src, "no_source_stack")
		return
	end
	local to = MySQL.single.await(
		("SELECT * FROM %s WHERE container_id=? AND slot_index=?"):format(C.stacks.table),
		{ toc, tos }
	)
	local toTag = MySQL.single.await(
		("SELECT tag FROM %s WHERE container_id=? AND slot_index=?"):format(C.container_slots.table),
		{ toc, tos }
	)
	if toTag and toTag.tag then
		local ok = true
		local t = json.decode(toTag.tag)
		if t and t.only then
			ok = false
			local tagsRow =
				MySQL.single.await(("SELECT tags FROM %s WHERE item_key=?"):format(C.items.table), { from.item_key })
			local ittags = (tagsRow and tagsRow.tags) and json.decode(tagsRow.tags) or {}
			for _, g in ipairs(ittags) do
				for _, need in ipairs(t.only) do
					if g == need then
						ok = true
					end
				end
			end
		end
		if not ok then
			TriggerClientEvent("fw:inv:error", src, "slot_forbidden")
			return
		end
	end
	if to and to.item_key == from.item_key then
		local newQty = (tonumber(to.quantity) or 0) + (amount > 0 and amount or from.quantity)
		MySQL.update.await(
			("UPDATE %s SET quantity=? WHERE stack_id=?"):format(C.stacks.table),
			{ newQty, to.stack_id }
		)
		if amount > 0 and amount < from.quantity then
			MySQL.update.await(
				("UPDATE %s SET quantity=quantity-? WHERE stack_id=?"):format(C.stacks.table),
				{ amount, from.stack_id }
			)
		else
			MySQL.query.await(("DELETE FROM %s WHERE stack_id=?"):format(C.stacks.table), { from.stack_id })
		end
		tx(
			ident,
			"MERGE",
			from.item_key,
			amount > 0 and amount or from.quantity,
			fromc,
			froms,
			toc,
			tos,
			to.stack_id,
			{}
		)
	else
		MySQL.update.await(
			("UPDATE %s SET container_id=?, slot_index=? WHERE stack_id=?"):format(C.stacks.table),
			{ toc, tos, from.stack_id }
		)
		tx(
			ident,
			"MOVE",
			from.item_key,
			amount > 0 and amount or from.quantity,
			fromc,
			froms,
			toc,
			tos,
			from.stack_id,
			{}
		)
	end
	TriggerClientEvent("fw:inv:refresh", src)
end)
