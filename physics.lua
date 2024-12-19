local physics = {}

function physics.updatePlayerMovement(player, leftKey, rightKey, dt)
  local wishDirection = 0
  if leftKey then wishDirection = wishDirection - 1 end
  if rightKey then wishDirection = wishDirection + 1 end

  if wishDirection ~= 0 then
    if (wishDirection < 0 and player.velocity > 0) or
        (wishDirection > 0 and player.velocity < 0) then
      player.velocity = player.velocity + (wishDirection * player.acceleration * 2 * dt)
      if math.abs(player.velocity) < 30 then
        player.velocity = 0
      end
    else
      player.velocity = player.velocity + (wishDirection * player.acceleration * dt)
    end
  else
    local speed = math.abs(player.velocity)
    if speed < 1 then
      player.velocity = 0
    else
      local drop = speed * player.friction * dt
      player.velocity = player.velocity * math.max(0, (speed - drop) / speed)
    end
  end

  player.velocity = math.min(player.maxSpeed, math.max(-player.maxSpeed, player.velocity))
  player.x = player.x + player.velocity * dt

  player.x = math.max(player.size, math.min(love.graphics.getWidth() - player.size, player.x))
end

function physics.checkCollision(player, obstacle, baseSize)
  if not obstacle.isGapMarker and
      math.abs(obstacle.x - player.x) < (baseSize / 2 + player.size) and
      math.abs(obstacle.y - player.y) < (baseSize / 2 + player.size) then
    return true
  end
  return false
end

return physics
