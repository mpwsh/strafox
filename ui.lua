local ui = {}

local obstacles = require("obstacles")

function ui.updateStrafeText(game, dt)
  for i = #game.strafeText, 1, -1 do
    local text = game.strafeText[i]
    text.lifetime = text.lifetime - dt
    text.opacity = math.max(0, text.lifetime / 0.5)
    text.y = text.y - (30 * dt)
    if text.lifetime <= 0 then
      table.remove(game.strafeText, i)
    end
  end
end

function ui.draw(game, player)
  -- Draw obstacles using obstacle.drawSquare
  for _, obstacle in ipairs(game.obstacles) do
    if not obstacle.isGapMarker then
      obstacles.drawSquare(obstacle.x, obstacle.y, game.baseSize)
    end
  end

  -- Draw player or death animation
  if not game.gameOver then
    ui.drawPlayer(player)
    ui.drawStrafeText(game) -- Only draw strafe text when game is not over
  else
    ui.drawDeathAnimation(player)
    game.strafeText = {} -- Clear strafe text when game is over
  end

  ui.drawHUD(game, player)

  -- Draw intro text if it's still visible
  if game.introText.lifetime > 0 and game.introText.opacity > 0 then
    love.graphics.setColor(1, 1, 1, game.introText.opacity)
    love.graphics.printf(game.introText.message,
      0, love.graphics.getHeight() / 2 - 60,
      love.graphics.getWidth(), "center")
  end

  -- Draw pause text if game is paused
  if game.isPaused then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("PAUSED",
      0, love.graphics.getHeight() / 2 - 30,
      love.graphics.getWidth(), "center")
  end
end

function ui.drawPlayer(player)
  love.graphics.push()
  love.graphics.translate(player.x, player.y)

  if player.lastStrafeResult then
    if player.lastStrafeResult == "Perfect" then
      love.graphics.setColor(0, 1, 0)
    elseif player.lastStrafeResult == "Early" then
      love.graphics.setColor(1, 1, 0)
    elseif player.lastStrafeResult == "Late" then
      love.graphics.setColor(1, 0, 0)
    end
  else
    love.graphics.setColor(1, 1, 1)
  end

  love.graphics.polygon('line', player.vertices)

  local velLength = (player.velocity / player.maxSpeed) * 40
  love.graphics.line(0, 0, velLength, 0)
  love.graphics.pop()
end

function ui.drawDeathAnimation(player)
  for _, line in ipairs(player.deathAnimation.lines) do
    love.graphics.push()

    local centerX = (line.x1 + line.x2) / 2
    local centerY = (line.y1 + line.y2) / 2

    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(line.rotation)
    love.graphics.translate(-centerX, -centerY)

    love.graphics.setColor(1, 1, 1, line.opacity)
    love.graphics.line(line.x1, line.y1, line.x2, line.y2)

    love.graphics.pop()
  end
end

function ui.addStrafeText(game, player, result, duration)
  local text = {
    result = result,
    duration = duration,
    x = player.x,
    y = player.y - 40,
    opacity = 1.0,
    lifetime = 1.5,
    score = 0,
    initialY = player.y - 40
  }

  game.strafeText = {}

  if result == "Perfect" then
    -- Increment combo first
    game.perfectCombo = game.perfectCombo + 1
    game.stats.perfectStrafes = game.stats.perfectStrafes + 1
    game.stats.maxCombo = math.max(game.stats.maxCombo, game.perfectCombo)

    -- Calculate score with combo multiplier
    text.score = game.perfectScore * game.perfectCombo
    text.combo = game.perfectCombo

    -- Add to total score
    game.score = game.score + text.score
  else
    -- Track stats for non-perfect strafes
    if result == "Late" then
      game.stats.lateStrafes = game.stats.lateStrafes + 1
    elseif result == "Early" then
      game.stats.earlyStrafes = game.stats.earlyStrafes + 1
    end

    -- Reset combo on mistake
    game.perfectCombo = 0

    -- Penalty for mistake
    text.score = -(state.lastStrafeDuration / 1000 * game.badScoreMultiplier)
    game.score = game.score + text.score
  end

  table.insert(game.strafeText, text)
end

function ui.drawStrafeText(game)
  for _, text in ipairs(game.strafeText) do
    -- Set color based on result
    if text.result == "Perfect" then
      love.graphics.setColor(0, 1, 0, text.opacity)
    elseif text.result == "Early" then
      love.graphics.setColor(1, 1, 0, text.opacity)
    elseif text.result == "Late" then
      love.graphics.setColor(1, 0, 0, text.opacity)
    end

    local displayText = text.result
    if text.duration > 0 then
      displayText = string.format("%s (%.1fms)", text.result, text.duration / 1000)
    end

    -- Show score with combo if applicable
    if text.score > 0 then
      if text.combo > 1 then
        displayText = string.format("%s\n%dx combo!\n+%d", displayText, text.combo, text.score)
      else
        displayText = displayText .. string.format("\n+%d", text.score)
      end
    else
      displayText = displayText .. string.format("\n%d", text.score)
    end

    love.graphics.printf(displayText,
      text.x - 100, text.y,
      200, "center")
  end
end

function ui.drawHUD(game, player)
  love.graphics.setColor(1, 1, 1, 1)
  -- Main stats
  love.graphics.print(string.format("Score: %d", math.floor(game.score)), 10, 10)
  love.graphics.print(string.format("Velocity: %d", math.floor(player.velocity)), 10, 30)
  love.graphics.print(string.format("Distance: %d", math.floor(game.distance)), 10, 50)

  -- Detailed strafe counts
  love.graphics.print("Strafes:", 10, 50)
  love.graphics.setColor(0, 1, 0, 1)
  love.graphics.print(string.format("  Perfect: %d", game.stats.perfectStrafes), 10, 70)
  love.graphics.setColor(1, 1, 0, 1)
  love.graphics.print(string.format("  Early: %d", game.stats.earlyStrafes), 10, 90)
  love.graphics.setColor(1, 0, 0, 1)
  love.graphics.print(string.format("  Late: %d", game.stats.lateStrafes), 10, 110)

  if game.gameOver then
    local centerX = love.graphics.getWidth() / 2
    local baseY = love.graphics.getHeight() / 2 - 100

    -- Game Over title (bigger and white)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Game Over!", 0, baseY, love.graphics.getWidth(), "center")

    -- Stats with different colors
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("Final Score: %d", math.floor(game.score)),
      0, baseY + 40, love.graphics.getWidth(), "center")

    love.graphics.setColor(0.8, 0.3, 1, 1) -- Purple for combo
    love.graphics.printf(string.format("Best Combo: %d", game.stats.maxCombo),
      0, baseY + 60, love.graphics.getWidth(), "center")

    love.graphics.setColor(0, 1, 0, 1) -- Green for perfect
    love.graphics.printf(string.format("Perfect Strafes: %d", game.stats.perfectStrafes),
      0, baseY + 80, love.graphics.getWidth(), "center")

    love.graphics.setColor(1, 1, 0, 1) -- Yellow for early
    love.graphics.printf(string.format("Early Strafes: %d", game.stats.earlyStrafes),
      0, baseY + 100, love.graphics.getWidth(), "center")

    love.graphics.setColor(1, 0, 0, 1) -- Red for late
    love.graphics.printf(string.format("Late Strafes: %d", game.stats.lateStrafes),
      0, baseY + 120, love.graphics.getWidth(), "center")

    -- Restart prompt in white
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Press R to restart",
      0, baseY + 160, love.graphics.getWidth(), "center")
  end
end

return ui
