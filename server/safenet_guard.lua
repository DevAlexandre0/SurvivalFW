FW = FW or {}
FW.SafeGate = {}
local keys = {
  ["evt:weap_shot"] = { rate=10, burst=15 },
  ["evt:veh_impact"] = { rate=2, burst=5 },
  ["stash:open"] = { rate=1, burst=2 },
  ["stash:move"] = { rate=2, burst=5 },
  ["craft:do"] = { rate=1, burst=2 },
  ["forage:do"] = { rate=0.5, burst=1 },
  ["wildlife:harvest"] = { rate=1, burst=2 },
  ["env:weather"] = { rate=1, burst=5 },
  ["med:splint"] = { rate=0.5, burst=1 },
  ["med:morphine"] = { rate=0.5, burst=1 },
  ["med:painkiller"] = { rate=0.5, burst=1 },
  ["med:bandage"] = { rate=0.5, burst=1 },
  ["med:tourniquet"] = { rate=0.5, burst=1 },
  ["veh:*"] = { rate=1, burst=3 },
}
local buckets = {}
function FW.SafeGate.Allowed(src, key)
  local now = GetGameTimer()
  local k = keys[key] or keys[key:match("^[^:]+:%*")] or {rate=1, burst=2}
  local b = buckets[src..':'..key] or {ts=now, tokens=k.burst}
  local elapsed = (now - b.ts)/1000.0
  b.tokens = math.min(k.burst, b.tokens + elapsed * k.rate)
  b.ts = now
  local ok = b.tokens >= 1.0
  if ok then b.tokens = b.tokens - 1.0 end
  buckets[src..':'..key] = b
  return ok
end
