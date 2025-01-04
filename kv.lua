local json = require("json")
require 'js'

local kv = {
  retryDelay = nil,
  retryTimer = 0,
  retryCount = nil
}
local https
local scoresEndpoint = "https://kv.mpw.sh/api/scores/"

if love.system.getOS() ~= "Web" then 
  package.cpath = package.cpath .. ";./libs/?.so"
  https = require 'https'
end

function kv.handleResponse(game, code, payload, errorBody)
  -- print("handleResponse called with code:", code)
  code = tonumber(code)
  game.isSubmitting = false
  
  if code == nil then
    local currentRetryDelay = (kv.retryCount or 0) * 2 + 1
    if kv.retryCount == nil then kv.retryCount = 0 end
    if kv.retryCount < 4 then
        -- print("Retrying score submission in " .. currentRetryDelay .. " seconds...")
        kv.retryDelay = currentRetryDelay -- Set the delay
        kv.retryTimer = 0 -- Reset the timer
        kv.retryCount = kv.retryCount + 1
    else
        print("Max retry attempts reached. Submission failed.")
        kv.retryDelay = nil
        kv.retryCount = nil
    end
    return
  end
  
  kv.retryDelay = nil
  kv.retryCount = nil
  
  if code == 201 then
    game.submitSuccess = true
    game.canSubmit = false
  else
    game.submitError = true
    if errorBody then print("Error submitting score:", errorBody) end
  end
end

function kv.submitScore(game)
  local payload = {
    username = game.playerName,
    score = math.floor(game.score),
    strafes = {
      perfect = game.stats.perfectStrafes,
      early = game.stats.earlyStrafes,
      late = game.stats.lateStrafes
    },
    distance = math.floor(game.distance),
    timestamp = game.timestamp
  }
  
  local hash = love.data.encode('string', 'hex', love.data.hash('sha256', 
    payload.timestamp ..  ":" ..
    payload.score
  ))
  payload.hash = hash
  local jsonString = json.encode(payload)
  
  if love.system.getOS() == "Web" then
    JS.newPromiseRequest(
      JS.stringFunc([[
        async function submitScore(endpoint, username, timestamp, scoreData) {
          try {
            const response = await fetch(endpoint + username + "-" + timestamp, {
              method: 'POST',
              headers: {'Content-Type': 'application/json'},
              body: scoreData
            });
            FS.writeFile('/home/web_user/love/strafox/__tempscore-submit', response.status.toString());
            console.log('Response status written:', response.status);
          } catch (err) {
            FS.writeFile('/home/web_user/love/strafox/__tempscore-submit', 'ERROR');
            console.log('Error status written');
          }
        }
        submitScore('%s', '%s', '%s', '%s');
        ]],
        scoresEndpoint,
        payload.username,
        payload.timestamp,
        jsonString:gsub("'", "\\'")
      ),
      function(result) kv.handleResponse(game, result, payload) end,
      function(err)
        print("Debug: Got error:", err)
        kv.handleResponse(game, 0, payload, err)
      end,
      5,
      "score-submit"
    )
  else
    if not https then
      kv.handleResponse(game, 0, payload, "HTTPS module not available")
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
    kv.handleResponse(game, code, payload, body)
    print("Response:", code, body)
    print("req:", jsonString)
  end
end

return kv

