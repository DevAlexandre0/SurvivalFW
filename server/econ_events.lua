FW = FW or {}
FW.Econ = { mult = 1.0, scarcity = {} }

local function weeklySeed()
  local year, week = tonumber(os.date("!%Y")), tonumber(os.date("!%W"))
  return (year*100 + week)
end

local function rollScarcity()
  math.randomseed(weeklySeed())
  local scarce = {}
  local pool = {'ammo_556','ammo_762','ammo_9','ammo_45','med_bandage','med_charcoal','fuel_can','car_battery'}
  for i=1,3 do
    local idx = math.random(1, #pool)
    scarce[pool[idx]] = (math.random() < 0.5) and 1.25 or 0.75
    table.remove(pool, idx)
  end
  return scarce
end

CreateThread(function()
  while true do
    Wait(30000)
    FW.Econ.scarcity = rollScarcity()
  end
end)

function FW.Econ.PriceMult(item) return FW.Econ.scarcity[item] or 1.0 end


function FW.Econ.PreviewWeek(basePrices, stock)
  local out = {}
  local seedBase = (tonumber(os.date("!%Y")) or 2025) * 100 + (tonumber(os.date("!%W")) or 1)
  for item, basePrice in pairs(basePrices or {}) do
    local arr = {}
    local p = (stock[item] and stock[item].price) or basePrice
    local scarceMul = FW.Econ.PriceMult(item) or 1.0
    for d=1,7 do
      local seed = seedBase*1000 + d*37 + string.byte(item, 1) -- deterministic-ish
      math.randomseed(seed)
      local vol = (FW.Trader and FW.Trader.priceVolatility) or 0.25
      local jitter = 1.0 + (math.random()*2*vol - vol)
      p = math.max(1, math.floor(p * jitter))
      table.insert(arr, { day=d, price=math.floor(p * scarceMul) })
    end
    out[item] = arr
  end
  return out
end
