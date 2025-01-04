local ui = {}

local obstacles = require("obstacles")
local items = require("items")
local sound = require 'sound'

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

function ui.drawHealth(player)
  local screenHeight = love.graphics.getHeight()
  local baseY = screenHeight - 30   -- Position 30 pixels from bottom

  for i = 1, player.maxHealth do
    -- Draw outline
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle('line', 20 + (i - 1) * 25, baseY, 8)

    -- Draw filled circle if health exists
    if i <= player.health then
      love.graphics.setColor(0, 0.8, 0, 0.8)       -- Slightly transparent green
      love.graphics.circle('fill', 20 + (i - 1) * 25, baseY, 7)
      -- Add a lighter green glow in the center for effect
      love.graphics.setColor(0.3, 1, 0.3, 0.5)
      love.graphics.circle('fill', 20 + (i - 1) * 25, baseY, 4)
    else
      -- Draw empty circles with slight opacity
      love.graphics.setColor(0.3, 0.3, 0.3, 0.4)
      love.graphics.circle('fill', 20 + (i - 1) * 25, baseY, 7)
    end
  end
end

function ui.drawPlayerHealEffect(player)
  if player.healEffect.active then
    -- Draw glow effect
    love.graphics.setColor(0, 1, 0, player.healEffect.glowIntensity * 0.3)
    love.graphics.push()
    love.graphics.translate(player.x, player.y)
    love.graphics.polygon('fill', player.vertices)
    love.graphics.pop()

    -- Draw heal effect particles
    love.graphics.setColor(0, 1, 0, 0.5)
    for _, particle in ipairs(player.healEffect.particles) do
      love.graphics.circle('fill', particle.x, particle.y, 3 * particle.opacity)
    end
  end
end

function ui.drawHitEffect(player)
  if player.hitEffect.active then
    love.graphics.setColor(1, 0.5, 0, 1) -- Orange color for explosion
    for _, particle in ipairs(player.hitEffect.particles) do
      love.graphics.push()
      love.graphics.translate(particle.x, particle.y)
      love.graphics.rotate(particle.rotation)
      love.graphics.setColor(1, 0.5, 0, particle.opacity)
      love.graphics.rectangle('fill', -particle.size / 2, -particle.size / 2, particle.size, particle.size)
      love.graphics.pop()
    end
  end
end

function ui.drawPlayer(player)
  if player.hitEffect.active then
    love.graphics.setColor(1, 0.3, 0.3, 1) -- Reddish tint when hit
  elseif player.invulnerable and math.floor(love.timer.getTime() * 10) % 2 == 0 then
    love.graphics.setColor(1, 1, 1, 0.5)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end

  ui.drawPlayerHealEffect(player)
  if player.invulnerable and math.floor(love.timer.getTime() * 10) % 2 == 0 then
    love.graphics.setColor(1, 1, 1, 0.5)     -- Make semi-transparent during invulnerability
  else
    love.graphics.setColor(1, 1, 1, 1)
  end

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

function ui.draw(game, player)
  -- Apply screen shake
  if player.hitEffect.active and player.hitEffect.shake.timer < player.hitEffect.shake.duration then
    local intensity = player.hitEffect.shake.intensity *
        (1 - player.hitEffect.shake.timer / player.hitEffect.shake.duration)
    love.graphics.translate(
      math.random(-intensity, intensity),
      math.random(-intensity, intensity)
    )
  end

  -- Draw obstacles using obstacle.drawSquare
  for _, obstacle in ipairs(game.obstacles) do
    if not obstacle.isGapMarker then
      obstacles.drawSquare(obstacle.x, obstacle.y, game.baseSize)
    end
  end



  -- Draw player or death animation
  if not game.gameOver then
    -- Draw healing items if they exist
    for _, item in ipairs(game.activeItems) do
      items.draw(item)
    end
    ui.drawHitEffect(player)
    ui.drawPlayer(player)
    ui.drawStrafeText(game)
  else
    ui.drawDeathAnimation(player)
    game.strafeText = {}
  end

  -- Draw health indicators
  ui.drawHealth(player)

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

function ui.addStrafeText(game, player, result, duration, state)
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

    -- Play the perfect sound with current combo
    sound.playPerfectSound(game.perfectCombo)

    -- Calculate score with combo multiplier
    text.score = game.perfectScore * game.perfectCombo
    text.combo = game.perfectCombo

    -- Add to total score
    game.score = game.score + text.score
  else
    -- Track stats for non-perfect strafes
    if result == "Late" then
      game.stats.lateStrafes = game.stats.lateStrafes + 1
      sound.playMistakeSound("Late", state.lastStrafeDuration)
    elseif result == "Early" then
      game.stats.earlyStrafes = game.stats.earlyStrafes + 1
      sound.playMistakeSound("Early", state.lastStrafeDuration)
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

  if not game.gameOver then
    -- Main stats
    love.graphics.print(string.format("Score: %d", math.floor(game.score)), 10, 10)
    love.graphics.print(string.format("Velocity: %d", math.floor(player.velocity)), 10, 30)
    love.graphics.print(string.format("Distance: %d", math.floor(game.distance)), 10, 50)

    -- Detailed strafe counts
    love.graphics.print("Strafes:", 10, 70)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print(string.format("  Perfect: %d", game.stats.perfectStrafes), 10, 90)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print(string.format("  Early: %d", game.stats.earlyStrafes), 10, 110)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.print(string.format("  Late: %d", game.stats.lateStrafes), 10, 130)
  else
    local baseY = love.graphics.getHeight() / 2 - 100

    -- Game Over title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Game Over!", 0, baseY, love.graphics.getWidth(), "center")

    -- Stats with different colors
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("Final Score: %d", math.floor(game.score)),
      0, baseY + 40, love.graphics.getWidth(), "center")

    love.graphics.setColor(0.8, 0.3, 1, 1)
    love.graphics.printf(string.format("Highest Combo: %d", game.stats.maxCombo),
      0, baseY + 60, love.graphics.getWidth(), "center")

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Strafes:",
      0, baseY + 80, love.graphics.getWidth(), "center")

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.printf(string.format("Perfect: %d", game.stats.perfectStrafes),
      0, baseY + 100, love.graphics.getWidth(), "center")

    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.printf(string.format("Early: %d", game.stats.earlyStrafes),
      0, baseY + 120, love.graphics.getWidth(), "center")

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.printf(string.format("Late: %d", game.stats.lateStrafes),
      0, baseY + 140, love.graphics.getWidth(), "center")

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Press R to restart",
      0, baseY + 180, love.graphics.getWidth(), "center")

    -- Score submission UI
    if not game.submitSuccess and game.canSubmit then
      love.graphics.printf("Press S to submit score",
        0, baseY + 200, love.graphics.getWidth(), "center")
    end

    -- Draw name input interface
    if game.showingSubmitScore then
      local inputY = baseY + 240
      love.graphics.setColor(1, 1, 1, 1)

      if game.isEnteringName then
        love.graphics.printf("Your name: " .. game.playerName .. (game.showCursor and "_" or ""),
          0, inputY, love.graphics.getWidth(), "center")
        love.graphics.printf("Press Enter to submit",
          0, inputY + 30, love.graphics.getWidth(), "center")
      elseif game.isSubmitting then
        love.graphics.printf("Submitting...",
          0, inputY, love.graphics.getWidth(), "center")
      elseif game.submitSuccess then
        love.graphics.printf("Score submitted successfully!",
          0, inputY, love.graphics.getWidth(), "center")
      elseif game.submitError then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.printf("Error submitting score. Please try again.",
          0, inputY, love.graphics.getWidth(), "center")
        -- Reset submission state to allow retry
        game.canSubmit = true
        game.showingSubmitScore = false
        game.submitError = false
      end
    end
  end
end

return ui
