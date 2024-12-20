local strafe = {}

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
    recentStrokes = {},    -- Stores recent key press timestamps
    maxStrokeHistory = 10, -- How many recent strokes to track
    spamThreshold = 0.3,   -- Time threshold between strokes (80ms)
    spamPatternCount = 4,  -- How many quick alternations to consider spam
    isSpamming = false     -- Current spam state
  }
end

-- New function to check for spam patterns
function strafe.checkSpamPattern(state, currentTime)
  local strokes = state.recentStrokes

  -- Remove old strokes (older than 1 second)
  while #strokes > 0 and currentTime - strokes[1].time > 1 do
    table.remove(strokes, 1)
  end

  -- If we don't have enough strokes to detect a pattern, it's not spam
  if #strokes < state.spamPatternCount then
    state.isSpamming = false
    return false
  end

  -- Check for alternating pattern with very short intervals
  local spamCount = 0
  for i = 2, #strokes do
    local timeDiff = strokes[i].time - strokes[i - 1].time
    local isAlternating = strokes[i].key ~= strokes[i - 1].key

    if timeDiff < state.spamThreshold and isAlternating then
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

-- Helper function to add a new keystroke to history
function strafe.recordStroke(state, key, currentTime)
  table.insert(state.recentStrokes, {
    key = key,
    time = currentTime
  })

  -- Keep only recent history
  while #state.recentStrokes > state.maxStrokeHistory do
    table.remove(state.recentStrokes, 1)
  end
end

function strafe.evaluateUnderstrafe(elapsed)
  local microSeconds = elapsed * 1000000
  if microSeconds < (200 * 1000) and microSeconds > 1600 then
    return "Early", microSeconds
  elseif microSeconds < 1600 then
    return "Perfect", 0
  end
  return nil, 0
end

function strafe.evaluateOverstrafe(elapsed)
  local microSeconds = elapsed * 1000000
  if microSeconds < (200 * 1000) then
    return "Late", microSeconds
  end
  return nil, 0
end

function strafe.update(state, leftKey, rightKey, currentTime)
  -- Record key changes
  if leftKey ~= state.leftPressed then
    strafe.recordStroke(state, "left", currentTime)
  end
  if rightKey ~= state.rightPressed then
    strafe.recordStroke(state, "right", currentTime)
  end

  -- Check for spam patterns
  local isSpamming = strafe.checkSpamPattern(state, currentTime)

  -- Original strafe logic
  if state.leftReleasedTime and currentTime - state.leftReleasedTime > state.strafeTimeout then
    state.leftReleasedTime = nil
    state.activeStrafe = nil
  end
  if state.rightReleasedTime and currentTime - state.rightReleasedTime > state.strafeTimeout then
    state.rightReleasedTime = nil
    state.activeStrafe = nil
  end

  if state.rightPressed and not rightKey then
    state.rightPressed = false
    state.rightReleasedTime = currentTime
    state.activeStrafe = 'right'
  end
  if state.leftPressed and not leftKey then
    state.leftPressed = false
    state.leftReleasedTime = currentTime
    state.activeStrafe = 'left'
  end

  if leftKey and not state.leftPressed then
    state.leftPressed = true
    if state.activeStrafe == 'right' and state.rightReleasedTime then
      local elapsed = currentTime - state.rightReleasedTime
      -- Only evaluate if not spamming
      if not isSpamming then
        state.lastStrafeResult, state.lastStrafeDuration = strafe.evaluateUnderstrafe(elapsed)
      else
        state.lastStrafeResult = "Spam"
        state.lastStrafeDuration = 0
      end
      state.rightReleasedTime = nil
      state.activeStrafe = nil
    end
  end

  if rightKey and not state.rightPressed then
    state.rightPressed = true
    if state.activeStrafe == 'left' and state.leftReleasedTime then
      local elapsed = currentTime - state.leftReleasedTime
      -- Only evaluate if not spamming
      if not isSpamming then
        state.lastStrafeResult, state.lastStrafeDuration = strafe.evaluateUnderstrafe(elapsed)
      else
        state.lastStrafeResult = "Spam"
        state.lastStrafeDuration = 0
      end
      state.leftReleasedTime = nil
      state.activeStrafe = nil
    end
  end

  if leftKey and rightKey and not state.bothPressedTime then
    state.bothPressedTime = currentTime
  end

  if (not leftKey or not rightKey) and state.bothPressedTime then
    local elapsed = currentTime - state.bothPressedTime
    -- Only evaluate if not spamming
    if not isSpamming then
      state.lastStrafeResult, state.lastStrafeDuration = strafe.evaluateOverstrafe(elapsed)
    else
      state.lastStrafeResult = "Spam"
      state.lastStrafeDuration = 0
    end
    state.bothPressedTime = nil
  end

  return state
end

return strafe
