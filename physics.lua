local physics = {}

-- Source engine style movement constants
-- CS2 defaults: sv_accelerate 5.5, sv_friction 5.2, maxspeed 250
-- sv_stopspeed 80 (minimum speed for friction calculation)
local SV_ACCELERATE = 5.5
local SV_FRICTION = 5.2
local SV_STOPSPEED = 80

-- Source engine Friction: reduces velocity proportionally each frame
-- Applied BEFORE acceleration
local function applyFriction(player, dt)
	local speed = math.abs(player.velocity)
	if speed < 0.1 then
		player.velocity = 0
		return
	end

	-- sv_stopspeed: use max(speed, stopspeed) as control value
	-- This makes friction stronger at low speeds, preventing endless sliding
	local control = math.max(speed, SV_STOPSPEED)
	local drop = control * SV_FRICTION * dt

	local newspeed = math.max(0, speed - drop)
	local factor = newspeed / speed
	player.velocity = player.velocity * factor
end

-- Source engine Accelerate: adds velocity toward wish direction
-- The key: currentspeed is the dot product of velocity and wish direction
-- When counterstrafing, this is NEGATIVE, so addspeed becomes large
-- allowing strong acceleration against current velocity
local function applyAccelerate(player, wishDirection, dt)
	local wishspeed = player.maxSpeed

	-- currentspeed = projection of velocity onto wish direction
	-- Positive if moving in wish direction, negative if opposite
	local currentspeed = player.velocity * wishDirection

	-- How much speed we need to add to reach wishspeed
	local addspeed = wishspeed - currentspeed
	if addspeed <= 0 then
		return
	end

	-- Calculate acceleration, capped by addspeed
	local accelspeed = SV_ACCELERATE * wishspeed * dt
	if accelspeed > addspeed then
		accelspeed = addspeed
	end

	player.velocity = player.velocity + accelspeed * wishDirection
end

function physics.updatePlayerMovement(player, leftKey, rightKey, dt)
	local wishDirection = 0
	if leftKey then
		wishDirection = wishDirection - 1
	end
	if rightKey then
		wishDirection = wishDirection + 1
	end

	-- Step 1: Always apply friction first (like Source engine)
	applyFriction(player, dt)

	-- Step 2: Apply acceleration if there's input
	if wishDirection ~= 0 then
		applyAccelerate(player, wishDirection, dt)
	end

	-- Clamp to max speed
	player.velocity = math.min(player.maxSpeed, math.max(-player.maxSpeed, player.velocity))

	-- Update position
	player.x = player.x + player.velocity * dt
	player.x = math.max(player.size, math.min(love.graphics.getWidth() - player.size, player.x))
end

function physics.checkCollision(player, obstacle, baseSize)
	if
		not obstacle.isGapMarker
		and math.abs(obstacle.x - player.x) < (baseSize / 2 + player.size)
		and math.abs(obstacle.y - player.y) < (baseSize / 2 + player.size)
	then
		return true
	end
	return false
end

return physics
