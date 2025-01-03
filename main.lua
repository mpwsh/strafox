io.stdout:setvbuf("no")
print("Starting main.lua")

require 'js'
local moonshine = require 'moonshine'
local obstacles = require 'obstacles'
local ui = require 'ui'
local playerModule = require 'player'
local physics = require 'physics'
local strafe = require 'strafe'
local Shader = require 'shader'
local items = require 'items'
local json = require("json")
local scoresEndpoint = "https://kv.mpw.sh/api/scores/"

local https
if love.system.getOS() ~= "Web" then -- Changed from 'not love.system.getOS() == "Web"'
  package.cpath = package.cpath .. ";./libs/?.so"
  https = require 'https'
end

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
    },
    -- New score submission related states
    showingSubmitScore = false,
    isEnteringName = false,
    playerName = "",
    submitBlinkTimer = 0,
    showCursor = true,
    isSubmitting = false,
    submitSuccess = false,
    canSubmit = true
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
  -- Configure the effects
  effect.crt.distortionFactor = { 1.03, 1.035 } -- Subtle curve
  effect.crt.feather = 0.02                     -- Smoothing

  effect.filmgrain.opacity = 0.2                -- Subtle grain
  effect.filmgrain.size = 1                     -- Slightly chunky

  effect.glow.strength = 2                      -- Moderate glow
  effect.glow.min_luma = 0.2                    -- Only glow brighter elements


  math.randomseed(os.time())
end

function love.update(dt)
  if (JS.retrieveData(dt)) then
    return
  end
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
  -- Update blinking cursor for name input
  if game.isEnteringName then
    game.submitBlinkTimer = game.submitBlinkTimer + dt
    if game.submitBlinkTimer >= 0.5 then
      game.showCursor = not game.showCursor
      game.submitBlinkTimer = 0
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
    if math.random() < 0.3 then -- 30% chance to spawn
      local newItem = items.spawn(game.obstacles)
      if newItem then
        table.insert(game.activeItems, newItem)
      end
    end
  end

  -- Update items and check collisions
  for i = #game.activeItems, 1, -1 do
    local item = game.activeItems[i]
    item.y = item.y + game.speed * dt -- Move items down with obstacles
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
    ui.addStrafeText(game, player, state.lastStrafeResult, state.lastStrafeDuration, state) -- Added state here
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
  if not game.isEnteringName then
  if key == 'p' then
    game.isPaused = not game.isPaused
    state.leftPressed = false
    state.rightPressed = false
  elseif key == 'r' then
    game = initializeGameState()
    player = playerModule.create()
    state = strafe.createState()
  elseif key == 's' and game.gameOver and game.canSubmit then
    game.showingSubmitScore = true
    game.isEnteringName = true
  end
  else
    if key == 'return' or key == 'kpenter' then
      if #game.playerName > 0 then
        game.isEnteringName = false
        game.isSubmitting = true
        submitScore()
      end
    elseif key == 'backspace' then
      game.playerName = string.sub(game.playerName, 1, -2)
    end
  end
end

function love.textinput(text)
  if game.isEnteringName and #game.playerName < 12 then
    game.playerName = game.playerName .. text
  end
end

local function handleResponse(code, data, errorBody)
  game.isSubmitting = false
  if code == 201 then
    game.submitSuccess = true
    game.canSubmit = false
  else
    game.submitError = true
    if errorBody then print("Error submitting score:", errorBody) end
  end
end


function submitScore()
  local payload = {
    username = game.playerName,
    score = math.floor(game.score),
    strafes = {
      perfect = game.stats.perfectStrafes,
      early = game.stats.earlyStrafes,
      late = game.stats.lateStrafes
    },
    distance = math.floor(game.distance),
    timestamp = os.time()
  }

  local hash = love.data.encode('string', 'hex', love.data.hash('sha256', 
    payload.timestamp .. 
    ":" ..
    payload.distance ..
    ":" ..
    payload.score
  ))

  payload.hash = hash
  local jsonString = json.encode(payload)

  if love.system.getOS() == "Web" then
    JS.newPromiseRequest(
      JS.stringFunc([[
        async function submitScore(endpoint, username, timestamp, scoreData) {
          try {
            const response = await fetch(`${endpoint}${username}-${timestamp}`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: scoreData
            });
            FS.writeFile('/home/web_user/love/strafox/__tempscore-submit', String(response.status));
          } catch (err) {
            console.error("Error submitting score:", err);
            FS.writeFile('/home/web_user/love/strafox/__tempscore-submit', "ERROR");
          }
        }
        submitScore('%s', '%s', '%s', '%s');
      ]],
        scoresEndpoint,
        payload.username,
        payload.timestamp,
        jsonString:gsub("'", "\\'")
      ),
      handleResponse,
      function(err)
        print("Debug: Got error:", err)
        handleResponse(0, payload, err)
      end,
      5,
      "score-submit"
    )
  else
    if not https then
      handleResponse(0, payload, "HTTPS module not available")
      return
    end

    print("Attempting request to:", scoresEndpoint .. payload.username .. "-" .. payload.timestamp)
    local code, body = https.request(
      scoresEndpoint .. payload.username .. "-" .. payload.timestamp,
      {
        method = "POST",
        headers = {
          ["Content-Type"] = "application/json",
          ["Content-Length"] = #jsonString
        },
        data = jsonString
      }
    )
    handleResponse(code, payload, body)

    print("Response:", code, body)
    print("req:", jsonString)
  end
end
