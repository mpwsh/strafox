io.stdout:setvbuf("no")
print("Starting main.lua")

local moonshine = require 'moonshine'
local obstacles = require 'obstacles'
local ui = require 'ui'
local playerModule = require 'player'
local physics = require 'physics'
local strafe = require 'strafe'
local Shader = require 'shader'
local items = require 'items'

-- Global declarations for Love2D game state
local initializeGameState
local player
local state
local game
local effect

function initializeGameState()
  return {
    score = 0,
    speed = 200,
    spawnTimer = 0,
    distance = 0,
    spawnInterval = 2,
    itemSpawnTimer = 0,
    itemSpawnInterval = 4,
    activeItems = {},
    obstacles = {},
    gameOver = false,
    baseSize = 40,
    strafeText = {},
    crossingScore = 100,
    perfectCombo = 0,
    perfectScore = 200,
    badScoreMultiplier = 0.5,
    isPaused = false,
    introText = {
      message = "Ready?\nPress P to pause. R to restart.\nA and D to move",
      opacity = 1,
      lifetime = 3,
      fadeOutDuration = 1
    },
    strafeTimings = {},
    stats = {
      perfectStrafes = 0,
      lateStrafes = 0,
      earlyStrafes = 0,
      maxCombo = 0
    }
  }
end

function love.load()
  player = playerModule.create()
  state = strafe.createState()
  game = initializeGameState()
  Shader.load()
-- Create moonshine effect chain
  effect = moonshine(moonshine.effects.crt)
          .chain(moonshine.effects.filmgrain)
          .chain(moonshine.effects.glow)
          .chain(moonshine.effects.chromasep)
  -- Configure the effects
  effect.crt.distortionFactor = {1.03, 1.035}  -- Subtle curve
  effect.crt.feather = 0.02                    -- Smoothing
  
  effect.filmgrain.opacity = 0.2               -- Subtle grain
  effect.filmgrain.size = 1                    -- Slightly chunky
  
  effect.glow.strength = 2                     -- Moderate glow
  effect.glow.min_luma = 0.2                   -- Only glow brighter elements
  
  effect.chromasep.angle = 0.5                 -- Direction of color separation
  effect.chromasep.radius = 2                  -- Amount of separation
  
  math.randomseed(os.time())
end

function love.update(dt)
  playerModule.updateHitEffect(player, dt)

 if game.introText.lifetime > 0 then
    game.introText.lifetime = game.introText.lifetime - dt
    if game.introText.lifetime <= game.introText.fadeOutDuration then
      game.introText.opacity = math.max(0, game.introText.lifetime / game.introText.fadeOutDuration)
    end
  end
 if player.invulnerable then
    player.invulnerabilityTimer = player.invulnerabilityTimer - dt
    if player.invulnerabilityTimer <= 0 then
        player.invulnerable = false
    end
end 
  if game.gameOver or game.isPaused then
    if game.gameOver then
      playerModule.updateDeathAnimation(player, dt)
    end
    for i = #game.obstacles, 1, -1 do
      local obstacle = game.obstacles[i]
      if game.gameOver then
        obstacle.y = obstacle.y + game.speed * dt
      end
      if obstacle.y > love.graphics.getHeight() + 100 then
        table.remove(game.obstacles, i)
      end
    end
    return
  end

  -- Update heal effect
  playerModule.updateHealEffect(player, dt)

  -- Update and check for item spawning
  game.itemSpawnTimer = game.itemSpawnTimer + dt
  if game.itemSpawnTimer >= game.itemSpawnInterval then
    game.itemSpawnTimer = 0
    if math.random() < 0.3 then  -- 30% chance to spawn
      local newItem = items.spawn(game.obstacles)
      if newItem then
        table.insert(game.activeItems, newItem)
      end
    end
  end

  -- Update items and check collisions
  for i = #game.activeItems, 1, -1 do
    local item = game.activeItems[i]
    item.y = item.y + game.speed * dt  -- Move items down with obstacles
    items.updatePickupEffect(item, dt)

    -- Remove items that are off screen
    if item.y > love.graphics.getHeight() + 100 then
      table.remove(game.activeItems, i)
    else
      -- Check collision with player
      local dx = player.x - item.x
      local dy = player.y - item.y
      local distance = math.sqrt(dx * dx + dy * dy)
      
      if distance < (player.size + item.size) then
        playerModule.heal(player)
        items.startPickupEffect(item)
        table.remove(game.activeItems, i)
      end
    end
  end

  -- Rest of your existing update code...
  local leftKey = love.keyboard.isDown('a')
  local rightKey = love.keyboard.isDown('d') 
  local currentTime = love.timer.getTime()

  state = strafe.update(state, leftKey, rightKey, currentTime)
  physics.updatePlayerMovement(player, leftKey, rightKey, dt)

  if state.lastStrafeResult and not state.resultDisplayed then
    ui.addStrafeText(game, player, state.lastStrafeResult, state.lastStrafeDuration, state)  -- Added state here
    state.resultDisplayed = true
    state.lastStrafeResult = nil
  end

  if leftKey or rightKey then
    state.resultDisplayed = false
  end

  game.spawnTimer = game.spawnTimer + dt
  if game.spawnTimer >= game.spawnInterval then
    local newObstacles = obstacles.createObstacle(game.obstacles)
    for _, obstacle in ipairs(newObstacles) do
      table.insert(game.obstacles, obstacle)
    end
    game.spawnTimer = 0
    game.speed = game.speed + 2
  end

  ui.updateStrafeText(game, dt)
  if not game.gameOver and not game.isPaused then
    game.distance = game.distance + (game.speed * dt)
  end
  for i = #game.obstacles, 1, -1 do
    local obstacle = game.obstacles[i]
    obstacle.y = obstacle.y + game.speed * dt

  if physics.checkCollision(player, obstacle, game.baseSize) and not player.invulnerable then
    player.health = player.health - 1
    player.invulnerable = true
    player.invulnerabilityTimer = 1 -- 1 second of invulnerability
   playerModule.startHitEffect(player) 
    if player.health <= 0 then
        game.gameOver = true
        playerModule.startDeathAnimation(player)
    end
end 

    if obstacle.y > love.graphics.getHeight() + 100 then
      if not game.gameOver and obstacle.isGapMarker then
        game.score = game.score + game.crossingScore -- Small bonus just for crossing
      end
      table.remove(game.obstacles, i)
    end
  end
end

function love.draw()
   effect(function()
  Shader.drawBackground(game)
  ui.draw(game, player)
   end)
end

function love.keypressed(key)
  if key == 'p' then
    game.isPaused = not game.isPaused
    state.leftPressed = false
    state.rightPressed = false
  elseif key == 'r' then
    game = initializeGameState()
    player = playerModule.create()
    state = strafe.createState()
  end
end
