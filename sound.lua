local sound = {}

-- Keep track of all active sources
local active_sources = {}
local music = nil
local perfectSound = nil

-- C major scale frequency ratios (starting from C)
local PITCH_RATIOS = {
    1.000,  -- C
    1.125,  -- D
    1.250,  -- E
    1.333,  -- F
    1.500,  -- G
    1.667,  -- A
    1.875,  -- B
    2.000   -- C (octave)
}

-- Settings that we can adjust globally
local settings = {
    volume_music = 0.7,
    volume_sfx = 0.2,
    master_volume = 1.0
}

function sound.load()
    -- Load the music file
    music = love.audio.newSource("assets/music.ogg", "stream") -- Changed to stream for longer files
    music:setLooping(true)
    music:seek(1.2)
    music:setVolume(settings.volume_music * settings.master_volume)
    music:play()
    
    -- Load the perfect strafe sound
    perfectSound = love.audio.newSource("assets/perfect.ogg", "static")
    perfectSound:setVolume(settings.volume_sfx * settings.master_volume)
end

function sound.playMistakeSound(result, duration)
    if perfectSound then
        local clone = perfectSound:clone()
        table.insert(active_sources, clone) -- Track the source
        
        local detuneAmount = duration / 1000
        local pitch = 1
        
        if result == "Early" then
            pitch = math.min(2.0, 1 + (detuneAmount * 0.5))
        else
            pitch = math.max(0.5, 1 - (detuneAmount * 0.3))
        end
        
        pitch = math.max(0.1, math.min(4.0, pitch))
        
        clone:setPitch(pitch)
        clone:setVolume(settings.volume_sfx * settings.master_volume)
        clone:play()
    end
end

function sound.playPerfectSound(combo)
    if perfectSound then
        local clone = perfectSound:clone()
        table.insert(active_sources, clone) -- Track the source
        
        local scalePosition = ((combo - 1) % #PITCH_RATIOS) + 1
        local octave = math.floor((combo - 1) / #PITCH_RATIOS)
        
        local pitch = PITCH_RATIOS[scalePosition] * (2 ^ octave)
        clone:setPitch(pitch)
        clone:setVolume(settings.volume_sfx * settings.master_volume)
        clone:play()
    end
end

function sound.update(dt)
    -- Clean up finished sounds
    for i = #active_sources, 1, -1 do
        local source = active_sources[i]
        if not source:isPlaying() then
            table.remove(active_sources, i)
        end
    end
    
    -- Update volumes for all active sources
    for _, source in ipairs(active_sources) do
        source:setVolume(settings.volume_sfx * settings.master_volume)
    end
    
    -- Update music volume
    if music then
        music:setVolume(settings.volume_music * settings.master_volume)
    end
end

function sound.stop()
    if music then music:stop() end
    -- Stop all active sound effects
    for _, source in ipairs(active_sources) do
        source:stop()
    end
    active_sources = {}
end

function sound.pause()
    if music then music:pause() end
end

function sound.resume()
    if music then music:play() end
end

function sound.setMasterVolume(volume)
    settings.master_volume = volume
end

function sound.setMusicVolume(volume)
    settings.volume_music = volume
end

function sound.setSFXVolume(volume)
    settings.volume_sfx = volume
end

return sound
