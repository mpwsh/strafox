local obstacles = {}

function obstacles.createObstacle(existingObstacles)
  local baseSize = 40
  local obstacleList = {}
  local screenWidth = love.graphics.getWidth()
  local gapWidth = baseSize * 2  -- Each gap is exactly 2 blocks wide
  local screenMid = screenWidth / 2
  local lastLeftGap, lastRightGap

  -- Find positions of last gaps
  if existingObstacles and #existingObstacles > 0 then
    for i = #existingObstacles, 1, -1 do
      if existingObstacles[i].isGapMarker then
        if existingObstacles[i].x < screenMid then
          lastLeftGap = existingObstacles[i].x
        else
          lastRightGap = existingObstacles[i].x
          break
        end
      end
    end
  end

  -- Calculate new gap positions
  local leftGapPosition, rightGapPosition
  local maxMove = 200
  
  -- Set left gap (between left edge and middle)
  if lastLeftGap then
    local minPos = math.max(baseSize + gapWidth / 2, lastLeftGap - maxMove)
    local maxPos = math.min(screenMid - gapWidth, lastLeftGap + maxMove)
    leftGapPosition = math.random(minPos, maxPos)
  else
    leftGapPosition = math.random(baseSize + gapWidth / 2, screenMid - gapWidth)
  end

  -- Set right gap (between middle and right edge)
  if lastRightGap then
    local minPos = math.max(screenMid + gapWidth, lastRightGap - maxMove)
    local maxPos = math.min(screenWidth - (baseSize + gapWidth / 2), lastRightGap + maxMove)
    rightGapPosition = math.random(minPos, maxPos)
  else
    rightGapPosition = math.random(screenMid + gapWidth, screenWidth - (baseSize + gapWidth / 2))
  end

  -- Create obstacles
  local x = 0
  while x < screenWidth do
    if (x < leftGapPosition - gapWidth / 2 or x > leftGapPosition + gapWidth / 2) and 
       (x < rightGapPosition - gapWidth / 2 or x > rightGapPosition + gapWidth / 2) then
      table.insert(obstacleList, {
        x = x + baseSize / 2,
        y = -100,
        size = baseSize
      })
    end
    x = x + baseSize
  end

  -- Add gap markers
  table.insert(obstacleList, {
    x = leftGapPosition,
    y = -100,
    isGapMarker = true
  })
  table.insert(obstacleList, {
    x = rightGapPosition,
    y = -100,
    isGapMarker = true
  })

  return obstacleList
end

function obstacles.drawSquare(x, y, size)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.setLineWidth(2)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle('line', -size / 2, -size / 2, size, size)
  love.graphics.pop()
  love.graphics.setLineWidth(1)
end

return obstacles