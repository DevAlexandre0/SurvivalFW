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
