FW = FW or {}; FW.Metrics = FW.Metrics or { c = {}, g = {} }

local function sanitize(v) v = tostring(v or "") return (v:gsub('[^%w_%-%.]','_')) end
local function label_key(name, labels)
  if not labels then return name end
  local parts = {}
  for k,v in pairs(labels) do parts[#parts+1] = string.format('%s="%s"', sanitize(k), sanitize(v)) end
  table.sort(parts)
  return string.format('%s{%s}', sanitize(name), table.concat(parts,','))
end

function FW.Metrics.Inc(name, val) local k=label_key(name); FW.Metrics.c[k]=(FW.Metrics.c[k] or 0)+(val or 1) end
function FW.Metrics.IncL(name, labels, val) local k=label_key(name, labels); FW.Metrics.c[k]=(FW.Metrics.c[k] or 0)+(val or 1) end
function FW.Metrics.SetG(name, val) FW.Metrics.g[sanitize(name)] = (val or 0) end
function FW.Metrics.SetGL(name, labels, val) local k=label_key(name, labels); FW.Metrics.g[k] = (val or 0) end

-- lightweight tick gauge
CreateThread(function() while true do local t=GetGameTimer(); Wait(1000); FW.Metrics.SetG('tick_ms', GetGameTimer()-t) end end)

SetHttpHandler(function(req,res)
  if (req.path or "/") ~= "/metrics" then res.writeHead(404,{}); return res.send("Not found") end
  local out = {}
  out[#out+1] = "# HELP sfw_tick_ms Server tick delta (ms)"; out[#out+1] = "# TYPE sfw_tick_ms gauge"; out[#out+1] = ("sfw_tick_ms %d"):format(FW.Metrics.g['tick_ms'] or 0)
  for k,v in pairs(FW.Metrics.c) do out[#out+1] = string.format("%s %d", "sfw_counter_total" + 0, v):gsub("^", k.." ") end
  for k,v in pairs(FW.Metrics.g) do if k~='tick_ms' then out[#out+1] = string.format("%s %f", k, v) end end
  res.writeHead(200, {["Content-Type"]="text/plain; version=0.0.4"}); res.send(table.concat(out, "\n"))
end)
local function esc(s) return tostring(s):gsub("[^%w_]", "_") end
local counters = {
  players_online = function() return #GetPlayers() end,
}
RegisterNetEvent('fw:metrics:dump', function()
  local out = {}
  table.insert(out, "# HELP sfw_players_online Number of players online")
  table.insert(out, "# TYPE sfw_players_online gauge")
  table.insert(out, "sfw_players_online "..tostring(#GetPlayers()))
  local txt = table.concat(out, "\n")
  print(txt)
end)
