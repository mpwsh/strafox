local player = {}

function player.create()
  local p = {
    x = love.graphics.getWidth() / 2,
    y = love.graphics.getHeight() - 50,
    velocity = 0,
    acceleration = 1000,
    maxSpeed = 250,
    friction = 8,
    size = 20,
    vertices = {
      -20, 20,
      20, 20,
      0, -20
    },
    deathAnimation = {
      active = false,
      lines = {},
      duration = 2,
      timer = 0,
      rotationSpeed = 2,
      driftSpeed = 100,
      fadeSpeed = 1.5
    }
  }
  return p
end

function player.updateDeathAnimation(p, dt)
  if not p.deathAnimation.active then return end

  p.deathAnimation.timer = p.deathAnimation.timer + dt

  for _, line in ipairs(p.deathAnimation.lines) do
    line.x1 = line.x1 + line.dx * dt
    line.x2 = line.x2 + line.dx * dt
    line.y1 = line.y1 + line.dy * dt
    line.y2 = line.y2 + line.dy * dt
    line.rotation = line.rotation + line.spin * dt
    line.opacity = math.max(0, line.opacity - p.deathAnimation.fadeSpeed * dt)
  end
end

function player.startDeathAnimation(p)
  p.deathAnimation.active = true
  p.deathAnimation.timer = 0

  local lines = {
    {
      x1 = p.x - 20,
      y1 = p.y + 20,
      x2 = p.x,
      y2 = p.y - 20,
      rotation = 0,
      opacity = 1,
      dx = math.random(-100, -50),
      dy = math.random(-100, -50),
      spin = math.random(-3, 3)
    },
    {
      x1 = p.x + 20,
      y1 = p.y + 20,
      x2 = p.x,
      y2 = p.y - 20,
      rotation = 0,
      opacity = 1,
      dx = math.random(50, 100),
      dy = math.random(-100, -50),
      spin = math.random(-3, 3)
    },
    {
      x1 = p.x - 20,
      y1 = p.y + 20,
      x2 = p.x + 20,
      y2 = p.y + 20,
      rotation = 0,
      opacity = 1,
      dx = math.random(-50, 50),
      dy = math.random(50, 100),
      spin = math.random(-3, 3)
    }
  }
  p.deathAnimation.lines = lines
end

return player
