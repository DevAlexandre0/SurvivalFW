-- Database wrappers with metrics logging
FW = FW or {}; FW.DB = FW.DB or {}

local buckets = {5,10,20,50,100,200,500,1000}
local function bucket(ms) for _,b in ipairs(buckets) do if ms<=b then return b end end return 2000 end
local function now() return GetGameTimer() end
local function inc(k) if FW.Metrics and FW.Metrics.Inc then FW.Metrics.Inc(k,1) end end
local function logLatency(ms, tag) inc(("db_latency_%sms{%s}"):format(bucket(ms), tag or "gen")) end

function FW.DB.single(q,a,t) local s=now(); local r=MySQL.single.await(q,a); logLatency(now()-s,t or 'single'); return r end
function FW.DB.query(q,a,t) local s=now(); local r=MySQL.query.await(q,a) or {}; logLatency(now()-s,t or 'query'); return r end
function FW.DB.update(q,a,t) local s=now(); local r=exports.oxmysql:update(q,a); logLatency(now()-s,t or 'update'); return r end
function FW.DB.insert(q,a,t) local s=now(); local r=exports.oxmysql:insert(q,a); logLatency(now()-s,t or 'insert'); return r end
function FW.DB.txn(ops,t) local s=now(); local r=exports.oxmysql:transaction(ops); logLatency(now()-s,t or 'txn'); return r end
