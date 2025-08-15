FW = FW or {}
FW.RL = FW.RL or {}
local buckets = {}
function FW.RL.Check(src, key, interval)
	local now = GetGameTimer()
	local b = buckets[src] or {}
	buckets[src] = b
	local last = b[key]
	if last and now - last < interval then
		return false
	end
	b[key] = now
	return true
end
