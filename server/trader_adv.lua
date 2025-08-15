FW = FW or {}
local function cfg() local r=MySQL.single.await("SELECT ema_alpha,weekly_decay FROM market_config WHERE id=1"); return {alpha=(r and tonumber(r.ema_alpha)) or 0.25, decay=(r and tonumber(r.weekly_decay)) or 1} end
local function ema(prev, price, a) return (prev==nil) and price or (a*price + (1-a)*prev) end
local function reprice(trader_id, item_key)
  local a=cfg().alpha
  local rows = MySQL.query.await("SELECT price FROM trader_price_history WHERE trader_id=? AND item_key=? ORDER BY ts DESC LIMIT 12", { trader_id, item_key }) or {}
  if #rows==0 then return end
  local e=nil; for i=#rows,1,-1 do e=ema(e, tonumber(rows[i].price), a) end
  if e then local buy=math.max(1, math.floor(e*1.05)); local sell=math.max(1, math.floor(e*0.80)); exports.oxmysql:update("UPDATE trader_prices SET price_buy=?, price_sell=? WHERE trader_id=? AND item_key=?", { buy, sell, trader_id, item_key }) end
end
AddEventHandler('fw:trader:buy', function(trader_id, item_key, qty) reprice(trader_id, item_key) end)
AddEventHandler('fw:trader:sell', function(trader_id, item_key, qty) reprice(trader_id, item_key) end)
