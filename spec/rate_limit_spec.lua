local now = 0
_G.GetGameTimer = function()
	return now
end
_G.FW = {}
dofile("resources/sfw/shared/20_utils.lua")

describe("rate limiter", function()
	it("blocks rapid calls", function()
		now = 0
		assert.is_true(FW.RL.Check(1, "k", 500))
		now = 100
		assert.is_false(FW.RL.Check(1, "k", 500))
		now = 600
		assert.is_true(FW.RL.Check(1, "k", 500))
	end)
end)
