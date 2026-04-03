local ui = {}

local obstacles = require("obstacles")
local items = require("items")
local sound = require("sound")

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
	local baseY = screenHeight - 30

	for i = 1, player.maxHealth do
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.circle("line", 20 + (i - 1) * 25, baseY, 8)

		if i <= player.health then
			love.graphics.setColor(0, 0.8, 0, 0.8)
			love.graphics.circle("fill", 20 + (i - 1) * 25, baseY, 7)
			love.graphics.setColor(0.3, 1, 0.3, 0.5)
			love.graphics.circle("fill", 20 + (i - 1) * 25, baseY, 4)
		else
			love.graphics.setColor(0.3, 0.3, 0.3, 0.4)
			love.graphics.circle("fill", 20 + (i - 1) * 25, baseY, 7)
		end
	end
end

function ui.drawPlayerHealEffect(player)
	if player.healEffect.active then
		love.graphics.setColor(0, 1, 0, player.healEffect.glowIntensity * 0.3)
		love.graphics.push()
		love.graphics.translate(player.x, player.y)
		love.graphics.polygon("fill", player.vertices)
		love.graphics.pop()

		love.graphics.setColor(0, 1, 0, 0.5)
		for _, particle in ipairs(player.healEffect.particles) do
			love.graphics.circle("fill", particle.x, particle.y, 3 * particle.opacity)
		end
	end
end

function ui.drawHitEffect(player)
	if player.hitEffect.active then
		love.graphics.setColor(1, 0.5, 0, 1)
		for _, particle in ipairs(player.hitEffect.particles) do
			love.graphics.push()
			love.graphics.translate(particle.x, particle.y)
			love.graphics.rotate(particle.rotation)
			love.graphics.setColor(1, 0.5, 0, particle.opacity)
			love.graphics.rectangle("fill", -particle.size / 2, -particle.size / 2, particle.size, particle.size)
			love.graphics.pop()
		end
	end
end

function ui.drawPlayer(player)
	if player.hitEffect.active then
		love.graphics.setColor(1, 0.3, 0.3, 1)
	elseif player.invulnerable and math.floor(love.timer.getTime() * 10) % 2 == 0 then
		love.graphics.setColor(1, 1, 1, 0.5)
	else
		love.graphics.setColor(1, 1, 1, 1)
	end

	ui.drawPlayerHealEffect(player)
	if player.invulnerable and math.floor(love.timer.getTime() * 10) % 2 == 0 then
		love.graphics.setColor(1, 1, 1, 0.5)
	else
		love.graphics.setColor(1, 1, 1, 1)
	end

	love.graphics.push()
	love.graphics.translate(player.x, player.y)

	if player.lastStrafeResult then
		if player.lastStrafeResult == "Perfect" then
			love.graphics.setColor(0, 1, 0)
		elseif player.lastStrafeResult == "Slow" then
			love.graphics.setColor(1, 1, 0)
		elseif player.lastStrafeResult == "Overlap" then
			love.graphics.setColor(1, 0, 0)
		end
	else
		love.graphics.setColor(1, 1, 1)
	end

	love.graphics.polygon("line", player.vertices)

	local velLength = (player.velocity / player.maxSpeed) * 40
	love.graphics.line(0, 0, velLength, 0)
	love.graphics.pop()
end

function ui.draw(game, player)
	ui.drawMenu(game)
	if player.hitEffect.active and player.hitEffect.shake.timer < player.hitEffect.shake.duration then
		local intensity = player.hitEffect.shake.intensity
			* (1 - player.hitEffect.shake.timer / player.hitEffect.shake.duration)
		love.graphics.translate(math.random(-intensity, intensity), math.random(-intensity, intensity))
	end

	for _, obstacle in ipairs(game.obstacles) do
		if not obstacle.isGapMarker then
			obstacles.drawSquare(obstacle.x, obstacle.y, game.baseSize)
		end
	end

	if not game.gameOver then
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

	ui.drawHealth(player)
	ui.drawHUD(game, player)

	if game.introText.lifetime > 0 and game.introText.opacity > 0 then
		love.graphics.setColor(1, 1, 1, game.introText.opacity)
		love.graphics.printf(
			game.introText.message,
			0,
			love.graphics.getHeight() / 2 - 60,
			love.graphics.getWidth(),
			"center"
		)
	end

	if game.isPaused then
		if not game.showMenu then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.printf("PAUSED", 0, love.graphics.getHeight() / 2 - 30, love.graphics.getWidth(), "center")
		end
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
		initialY = player.y - 40,
	}

	game.strafeText = {}

	if result == "Perfect" then
		game.perfectCombo = game.perfectCombo + 1
		game.stats.perfectStrafes = game.stats.perfectStrafes + 1
		game.stats.maxCombo = math.max(game.stats.maxCombo, game.perfectCombo)

		sound.playPerfectSound(game.perfectCombo)

		-- Score scales with how fast the counterstrafe was
		-- 0ms = 2x bonus, 60ms = 1x (no bonus), linear scale
		local speedBonus = 1 + (1 - math.min(duration, 60) / 60)
		text.score = math.floor(game.perfectScore * game.perfectCombo * speedBonus)
		text.combo = game.perfectCombo

		game.score = game.score + text.score
	else
		if result == "Overlap" then
			game.stats.overlapStrafes = game.stats.overlapStrafes + 1
			sound.playMistakeSound("Overlap", state.lastStrafeDuration)
		elseif result == "Slow" then
			game.stats.slowStrafes = game.stats.slowStrafes + 1
			sound.playMistakeSound("Slow", state.lastStrafeDuration)
		end

		game.perfectCombo = 0

		text.score = -(state.lastStrafeDuration * game.badScoreMultiplier)
		game.score = game.score + text.score
	end

	table.insert(game.strafeText, text)
end

function ui.drawStrafeText(game)
	for _, text in ipairs(game.strafeText) do
		if text.result == "Perfect" then
			love.graphics.setColor(0, 1, 0, text.opacity)
		elseif text.result == "Slow" then
			love.graphics.setColor(1, 1, 0, text.opacity)
		elseif text.result == "Overlap" then
			love.graphics.setColor(1, 0, 0, text.opacity)
		end

		-- Always show timing in ms
		local displayText = string.format("%s (%.0fms)", text.result, text.duration)

		-- Show score with combo if applicable
		if text.score > 0 then
			if text.combo and text.combo > 1 then
				displayText = string.format("%s\n%dx combo!\n+%d", displayText, text.combo, text.score)
			else
				displayText = displayText .. string.format("\n+%d", text.score)
			end
		else
			displayText = displayText .. string.format("\n%d", math.floor(text.score))
		end

		love.graphics.printf(displayText, text.x - 100, text.y, 200, "center")
	end
end

function ui.drawHUD(game, player)
	love.graphics.setColor(1, 1, 1, 1)

	if not game.gameOver then
		love.graphics.print(string.format("Score: %d", math.floor(game.score)), 10, 10)
		love.graphics.print(string.format("Velocity: %d", math.floor(player.velocity)), 10, 30)
		love.graphics.print(string.format("Distance: %d", math.floor(game.distance)), 10, 50)

		love.graphics.print("Strafes:", 10, 70)
		love.graphics.setColor(0, 1, 0, 1)
		love.graphics.print(string.format("  Perfect: %d", game.stats.perfectStrafes), 10, 90)
		love.graphics.setColor(1, 1, 0, 1)
		love.graphics.print(string.format("  Slow: %d", game.stats.slowStrafes), 10, 110)
		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.print(string.format("  Overlap: %d", game.stats.overlapStrafes), 10, 130)
	else
		local baseY = love.graphics.getHeight() / 2 - 100

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("Game Over!", 0, baseY, love.graphics.getWidth(), "center")

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(
			string.format("Final Score: %d", math.floor(game.score)),
			0,
			baseY + 40,
			love.graphics.getWidth(),
			"center"
		)

		love.graphics.setColor(0.8, 0.3, 1, 1)
		love.graphics.printf(
			string.format("Highest Combo: %d", game.stats.maxCombo),
			0,
			baseY + 60,
			love.graphics.getWidth(),
			"center"
		)

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("Strafes:", 0, baseY + 80, love.graphics.getWidth(), "center")

		love.graphics.setColor(0, 1, 0, 1)
		love.graphics.printf(
			string.format("Perfect: %d", game.stats.perfectStrafes),
			0,
			baseY + 100,
			love.graphics.getWidth(),
			"center"
		)

		love.graphics.setColor(1, 1, 0, 1)
		love.graphics.printf(
			string.format("Slow: %d", game.stats.slowStrafes),
			0,
			baseY + 120,
			love.graphics.getWidth(),
			"center"
		)

		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.printf(
			string.format("Overlap: %d", game.stats.overlapStrafes),
			0,
			baseY + 140,
			love.graphics.getWidth(),
			"center"
		)

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf("Press R to restart", 0, baseY + 180, love.graphics.getWidth(), "center")

		if not game.submitSuccess and game.canSubmit then
			love.graphics.printf("Press S to submit score", 0, baseY + 200, love.graphics.getWidth(), "center")
		end

		if game.showingSubmitScore then
			local inputY = baseY + 240
			love.graphics.setColor(1, 1, 1, 1)

			if game.isEnteringName then
				love.graphics.printf(
					"Your name: " .. game.playerName .. (game.showCursor and "_" or ""),
					0,
					inputY,
					love.graphics.getWidth(),
					"center"
				)
				love.graphics.printf("Press Enter to submit", 0, inputY + 30, love.graphics.getWidth(), "center")
			elseif game.isSubmitting then
				love.graphics.printf("Submitting...", 0, inputY, love.graphics.getWidth(), "center")
			elseif game.submitSuccess then
				love.graphics.printf("Score submitted successfully!", 0, inputY, love.graphics.getWidth(), "center")
			elseif game.submitError then
				love.graphics.setColor(1, 0, 0, 1)
				love.graphics.printf(
					"Error submitting score. Please try again.",
					0,
					inputY,
					love.graphics.getWidth(),
					"center"
				)
				game.canSubmit = true
				game.showingSubmitScore = false
				game.submitError = false
			end
		end
	end
end

function ui.drawMenu(game)
	if not game.showMenu then
		return
	end

	local screenWidth = love.graphics.getWidth()
	local screenHeight = love.graphics.getHeight()

	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf("Sound Settings", 0, screenHeight * 0.3, screenWidth, "center")

	for i, option in ipairs(game.menuOptions) do
		local y = screenHeight * (0.4 + (i - 1) * 0.1)
		local cursor = (i == game.menuSelection and game.showMenuCursor) and ">" or " "

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(cursor .. " " .. option.name, -50, y, screenWidth, "center")

		local barWidth = 200
		local barX = (screenWidth - barWidth) / 2
		local barY = y + 30

		love.graphics.setColor(0.3, 0.3, 0.3, 1)
		love.graphics.rectangle("fill", barX, barY, barWidth, 10)

		love.graphics.setColor(0.2, 0.6, 1, 1)
		love.graphics.rectangle("fill", barX, barY, barWidth * option.value, 10)

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.printf(string.format("%.1f", option.value), barX + barWidth + 10, barY - 5, 50, "left")
	end

	love.graphics.setColor(0.7, 0.7, 0.7, 1)
	love.graphics.printf(
		"UP/DOWN: Select   LEFT/RIGHT: Adjust   ESC: Close",
		0,
		screenHeight * 0.8,
		screenWidth,
		"center"
	)
end

return ui
