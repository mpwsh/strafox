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
    },
    health = 3,
    maxHealth = 3,
    healEffect = {
        active = false,
        timer = 0,
        duration = 0.5,
        particles = {},
        glowIntensity = 1
    },
    invulnerable = false,
    invulnerabilityTimer = 0,
    hitEffect = {
      active = false,
      timer = 0,
      duration = 0.3,
      particles = {},
      shake = {
        intensity = 3,
        duration = 0.3,
        timer = 0
      }
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
function player.heal(p)
    if p.health < p.maxHealth then
        p.health = p.health + 1
        p.healEffect.active = true
        p.healEffect.timer = 0
        p.healEffect.glowIntensity = 1
        
        -- Create healing particles
        for i = 1, 12 do
            local angle = (i - 1) * (math.pi * 2 / 12)
            table.insert(p.healEffect.particles, {
                x = p.x,
                y = p.y,
                dx = math.cos(angle) * 80,
                dy = math.sin(angle) * 80,
                opacity = 1
            })
        end
    end
end

function player.updateHealEffect(p, dt)
    if not p.healEffect.active then return end
    
    p.healEffect.timer = p.healEffect.timer + dt
    p.healEffect.glowIntensity = math.max(0, 1 - (p.healEffect.timer / p.healEffect.duration))
    
    for i = #p.healEffect.particles, 1, -1 do
        local particle = p.healEffect.particles[i]
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt
        particle.opacity = math.max(0, particle.opacity - dt * 2)
        
        if particle.opacity <= 0 then
            table.remove(p.healEffect.particles, i)
        end
    end
    
    if p.healEffect.timer >= p.healEffect.duration then
        p.healEffect.active = false
        p.healEffect.particles = {}
    end
end
function player.startHitEffect(p)
  p.hitEffect.active = true
  p.hitEffect.timer = 0
  p.hitEffect.shake.timer = 0
  
  -- Create explosion particles
  for _ = 1, 15 do
    local angle = math.random() * math.pi * 2
    local speed = math.random(100, 200)
    table.insert(p.hitEffect.particles, {
      x = p.x,
      y = p.y,
      dx = math.cos(angle) * speed,
      dy = math.sin(angle) * speed,
      rotation = math.random() * math.pi * 2,
      rotationSpeed = math.random(-10, 10),
      size = math.random(2, 4),
      opacity = 1
    })
  end
end

function player.updateHitEffect(p, dt)
  if not p.hitEffect.active then return end
  
  p.hitEffect.timer = p.hitEffect.timer + dt
  p.hitEffect.shake.timer = p.hitEffect.shake.timer + dt
  
  -- Update particles
  for i = #p.hitEffect.particles, 1, -1 do
    local particle = p.hitEffect.particles[i]
    particle.x = particle.x + particle.dx * dt
    particle.y = particle.y + particle.dy * dt
    particle.rotation = particle.rotation + particle.rotationSpeed * dt
    particle.opacity = math.max(0, 1 - (p.hitEffect.timer / p.hitEffect.duration))
    particle.dx = particle.dx * 0.95  -- Add some drag
    particle.dy = particle.dy * 0.95
    
    if particle.opacity <= 0 then
      table.remove(p.hitEffect.particles, i)
    end
  end
  
  if p.hitEffect.timer >= p.hitEffect.duration then
    p.hitEffect.active = false
    p.hitEffect.particles = {}
  end
end

return player
