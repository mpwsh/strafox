io.stdout:setvbuf("no")
print("Starting main.lua")

local obstacles = require 'obstacles'
local ui = require 'ui'
local playerModule = require 'player'
local physics = require 'physics'
local strafe = require 'strafe'
local Shader = require 'shader'

function initializeGameState()
  return {
    score = 0,
    speed = 200,
    spawnTimer = 0,
    distance = 0,
    spawnInterval = 2,
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

  colors = {
    { 1, 0.4, 0 },
    { 1, 0.6, 0 },
    { 1, 0.8, 0 }
  }
  math.randomseed(os.time())
end

function love.update(dt)
  if game.introText.lifetime > 0 then
    game.introText.lifetime = game.introText.lifetime - dt
    if game.introText.lifetime <= game.introText.fadeOutDuration then
      game.introText.opacity = math.max(0, game.introText.lifetime / game.introText.fadeOutDuration)
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


  local leftKey = love.keyboard.isDown('a')
  local rightKey = love.keyboard.isDown('d')
  local currentTime = love.timer.getTime()

  state = strafe.update(state, leftKey, rightKey, currentTime, player.velocity)
  physics.updatePlayerMovement(player, leftKey, rightKey, dt)

  if state.lastStrafeResult and not state.resultDisplayed then
    ui.addStrafeText(game, player, state.lastStrafeResult, state.lastStrafeDuration)
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

    if physics.checkCollision(player, obstacle, game.baseSize) then
      game.gameOver = true
      playerModule.startDeathAnimation(player)
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
  Shader.drawBackground(game)

  ui.draw(game, player)
end

function love.keypressed(key)
  if key == 'p' then
    game.isPaused = not game.isPaused
  elseif key == 'r' then
    game = initializeGameState()
    player = playerModule.create()
    state = strafe.createState()
  end
end
