local strafe = {}

local MIN_VELOCITY_FOR_STRAFE = 100

function strafe.createState()
	return {
		leftPressed = false,
		rightPressed = false,
		rightReleasedTime = nil,
		leftReleasedTime = nil,
		bothPressedTime = nil,
		lastStrafeResult = nil,
		lastStrafeDuration = 0,
		activeStrafe = nil,
		strafeTimeout = 0.2,
		resultDisplayed = false,
		recentStrokes = {},
		maxStrokeHistory = 10,
		spamThreshold = 0.08, -- 80ms: keys held shorter than this = spam
		spamPatternCount = 4, -- How many short-hold alternations = spam
		isSpamming = false,
		-- Overlap recovery: defer overlap penalty so a follow-up
		-- counterstrafe within the recovery window can cancel it
		pendingOverlap = nil,
		pendingOverlapTime = nil,
		overlapRecoveryWindow = 0.1, -- 100ms to recover from overlap
	}
end

-- Record a keystroke with hold duration of the previous key
function strafe.recordStroke(state, key, currentTime)
	local previousHold = nil
	if #state.recentStrokes > 0 then
		local last = state.recentStrokes[#state.recentStrokes]
		previousHold = currentTime - last.time
	end

	table.insert(state.recentStrokes, {
		key = key,
		time = currentTime,
		previousHold = previousHold,
	})

	while #state.recentStrokes > state.maxStrokeHistory do
		table.remove(state.recentStrokes, 1)
	end
end

-- Detect spam by checking if recent strokes alternate with very short
-- hold times. Two fast counterstrafes won't trigger this because each
-- key is held long enough to actually move.
function strafe.checkSpamPattern(state, currentTime)
	local strokes = state.recentStrokes

	-- Remove strokes older than 1 second
	while #strokes > 0 and currentTime - strokes[1].time > 1 do
		table.remove(strokes, 1)
	end

	if #strokes < state.spamPatternCount then
		state.isSpamming = false
		return false
	end

	local spamCount = 0
	for i = 2, #strokes do
		local isAlternating = strokes[i].key ~= strokes[i - 1].key
		local shortHold = strokes[i].previousHold and strokes[i].previousHold < state.spamThreshold

		if isAlternating and shortHold then
			spamCount = spamCount + 1
		else
			spamCount = 0
		end

		if spamCount >= state.spamPatternCount - 1 then
			state.isSpamming = true
			return true
		end
	end

	state.isSpamming = false
	return false
end

-- Evaluate a counterstrafe (gap between release and opposite press)
-- Timing aligned with Source engine:
-- 0-60ms   = Perfect (returns ms for display and score scaling)
-- 61-150ms = Slow
-- >150ms   = nil (too slow, no result)
function strafe.evaluateUnderstrafe(elapsed)
	local ms = elapsed * 1000
	if ms <= 60 then
		return "Perfect", ms
	elseif ms <= 150 then
		return "Slow", ms
	end
	return nil, 0
end

-- Evaluate an overstrafe (both keys held simultaneously)
-- Any overlap under 200ms = Overlap
function strafe.evaluateOverstrafe(elapsed)
	local ms = elapsed * 1000
	if ms < 200 then
		return "Overlap", ms
	end
	return nil, 0
end

function strafe.update(state, leftKey, rightKey, currentTime, velocity)
	-- Record key changes
	if leftKey ~= state.leftPressed then
		strafe.recordStroke(state, "left", currentTime)
	end
	if rightKey ~= state.rightPressed then
		strafe.recordStroke(state, "right", currentTime)
	end

	local isSpamming = strafe.checkSpamPattern(state, currentTime)

	-- Only evaluate strafes if moving fast enough
	local movingFastEnough = math.abs(velocity or 0) >= MIN_VELOCITY_FOR_STRAFE

	-- Timeout stale releases
	if state.leftReleasedTime and currentTime - state.leftReleasedTime > state.strafeTimeout then
		state.leftReleasedTime = nil
		state.activeStrafe = nil
	end
	if state.rightReleasedTime and currentTime - state.rightReleasedTime > state.strafeTimeout then
		state.rightReleasedTime = nil
		state.activeStrafe = nil
	end

	-- Detect key releases
	if state.rightPressed and not rightKey then
		state.rightPressed = false
		state.rightReleasedTime = currentTime
		state.activeStrafe = "right"
	end
	if state.leftPressed and not leftKey then
		state.leftPressed = false
		state.leftReleasedTime = currentTime
		state.activeStrafe = "left"
	end

	-- Left key pressed: check for counterstrafe from right
	if leftKey and not state.leftPressed then
		state.leftPressed = true
		if state.activeStrafe == "right" and state.rightReleasedTime then
			local elapsed = currentTime - state.rightReleasedTime
			if not isSpamming and movingFastEnough then
				local result, duration = strafe.evaluateUnderstrafe(elapsed)
				if result then
					state.pendingOverlap = nil
					state.pendingOverlapTime = nil
					state.lastStrafeResult = result
					state.lastStrafeDuration = duration
				end
			end
			state.rightReleasedTime = nil
			state.activeStrafe = nil
		end
	end

	-- Right key pressed: check for counterstrafe from left
	if rightKey and not state.rightPressed then
		state.rightPressed = true
		if state.activeStrafe == "left" and state.leftReleasedTime then
			local elapsed = currentTime - state.leftReleasedTime
			if not isSpamming and movingFastEnough then
				local result, duration = strafe.evaluateUnderstrafe(elapsed)
				if result then
					state.pendingOverlap = nil
					state.pendingOverlapTime = nil
					state.lastStrafeResult = result
					state.lastStrafeDuration = duration
				end
			end
			state.leftReleasedTime = nil
			state.activeStrafe = nil
		end
	end

	-- Overlap detection: both keys held at the same time
	if leftKey and rightKey and not state.bothPressedTime then
		state.bothPressedTime = currentTime
	end

	-- Overlap ended: one key released while both were held
	if (not leftKey or not rightKey) and state.bothPressedTime then
		local elapsed = currentTime - state.bothPressedTime
		if not isSpamming and movingFastEnough then
			local result, duration = strafe.evaluateOverstrafe(elapsed)
			if result then
				state.pendingOverlap = { result = result, duration = duration }
				state.pendingOverlapTime = currentTime
			end
		end
		state.bothPressedTime = nil
	end

	-- Commit pending overlap only after recovery window expires.
	if state.pendingOverlap and state.pendingOverlapTime then
		if currentTime - state.pendingOverlapTime > state.overlapRecoveryWindow then
			state.lastStrafeResult = state.pendingOverlap.result
			state.lastStrafeDuration = state.pendingOverlap.duration
			state.pendingOverlap = nil
			state.pendingOverlapTime = nil
		end
	end

	return state
end

return strafe
