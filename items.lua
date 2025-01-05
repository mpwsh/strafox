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
    local gapMarkers = {}
    
    for _, obs in ipairs(obstacles) do
        if obs.isGapMarker then
            table.insert(gapMarkers, obs.x)
        end
    end
    
    if #gapMarkers >= 2 then
        local x = (gapMarkers[1] + gapMarkers[2]) / 2
        return items.create(x, -320)
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
