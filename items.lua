local items = {}

function items.create(x, y)
    return {
        x = x,
        y = y,
        size = 15,
        type = "heal",
        pickupEffect = {
            active = false,
            particles = {},
            timer = 0,
            duration = 1
        }
    }
end

function items.spawn(obstacles)
    local possiblePositions = {}
    local screenWidth = love.graphics.getWidth()
    
    -- Find gaps between obstacles
    for i = 1, #obstacles - 1 do
        if not obstacles[i].isGapMarker and not obstacles[i + 1].isGapMarker then
            local gap = {
                x = (obstacles[i].x + obstacles[i + 1].x) / 2,
                width = obstacles[i + 1].x - obstacles[i].x
            }
            if gap.width > 50 then  -- Ensure gap is wide enough
                table.insert(possiblePositions, gap)
            end
        end
    end
    
    if #possiblePositions > 0 then
        local chosen = possiblePositions[math.random(#possiblePositions)]
        return items.create(chosen.x, obstacles[1].y)
    end
    return nil
end

function items.startPickupEffect(item)
    item.pickupEffect.active = true
    item.pickupEffect.timer = 0
    
    -- Create particles that spread outward
    for i = 1, 8 do
        local angle = (i - 1) * (math.pi * 2 / 8)
        table.insert(item.pickupEffect.particles, {
            x = item.x,
            y = item.y,
            dx = math.cos(angle) * 100,
            dy = math.sin(angle) * 100,
            opacity = 1
        })
    end
end

function items.updatePickupEffect(item, dt)
    if not item.pickupEffect.active then return end
    
    item.pickupEffect.timer = item.pickupEffect.timer + dt
    
    for _, particle in ipairs(item.pickupEffect.particles) do
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt
        particle.opacity = math.max(0, particle.opacity - dt * 2)
    end
end

function items.draw(item)
    if item.pickupEffect.active then
        love.graphics.setColor(0, 1, 0, 0.5)
        for _, particle in ipairs(item.pickupEffect.particles) do
            love.graphics.circle('fill', particle.x, particle.y, 5 * particle.opacity)
        end
    else
        -- Draw the heal item
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.circle('fill', item.x, item.y, item.size)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle('line', item.x, item.y, item.size)
    end
end

return items