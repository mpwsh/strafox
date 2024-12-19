local obstacles = {}

function obstacles.createObstacle(existingObstacles)
  local baseSize = 40
  local obstacleList = {}
  local screenWidth = love.graphics.getWidth()
  local gapWidth = 100
  local lastGapPosition

  if existingObstacles and #existingObstacles > 0 then
    for i = #existingObstacles, 1, -1 do
      if existingObstacles[i].isGapMarker then
        lastGapPosition = existingObstacles[i].x
        break
      end
    end
  end

  local gapPosition
  if lastGapPosition then
    local maxMove = 200
    local minPos = math.max(baseSize + gapWidth / 2, lastGapPosition - maxMove)
    local maxPos = math.min(screenWidth - (baseSize + gapWidth / 2), lastGapPosition + maxMove)
    gapPosition = math.random(minPos, maxPos)
  else
    gapPosition = math.random(baseSize + gapWidth / 2, screenWidth - (baseSize + gapWidth / 2))
  end

  local x = 0
  while x < screenWidth do
    if x < gapPosition - gapWidth / 2 or x > gapPosition + gapWidth / 2 then
      table.insert(obstacleList, {
        x = x + baseSize / 2,
        y = -100,
        size = baseSize
      })
    end
    x = x + baseSize
  end

  table.insert(obstacleList, {
    x = gapPosition,
    y = -100,
    isGapMarker = true
  })

  return obstacleList
end

function obstacles.drawSquare(x, y, size)
  love.graphics.push()
  love.graphics.translate(x, y)

  -- Set line width for the border
  love.graphics.setLineWidth(2)

  -- Draw white border with no fill
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle('line', -size / 2, -size / 2, size, size)

  love.graphics.pop()

  -- Reset line width to default
  love.graphics.setLineWidth(1)
end

return obstacles
