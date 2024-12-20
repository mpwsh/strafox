local Shader = {}
function Shader.load()
  Shader.starfield = love.graphics.newShader [[
        extern vec2 iResolution;
        extern float iTime;
        extern float gameProgress;
        extern float dynamicZoom;
        extern float dynamicDistfading;
        extern float volstepsMultiplier;
        
        const int iterations = 17;
        const int volsteps = 7;
        const float formuparam = 0.53;
        const float stepsize = 0.15;
        const float tile = 0.150;
        const float speed = 0.0005;
        const float brightness = 0.0005;
        const float darkmatter = 0.750;
        const float saturation = 0.150;

        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 screen_coords) {
            vec2 uv = screen_coords.xy/iResolution.xy-.5;
            uv.y *= iResolution.y/iResolution.x;
            vec3 dir = vec3(uv*dynamicZoom,1.);
            float time = iTime*speed+.25;
            float progressScale = gameProgress * 0.001;
            
            // Modified rotation angles for vertical movement
            float a1 = cos(time * 0.7) * 0.1 + progressScale;  // Reduced horizontal rotation
            float a2 = sin(time * 0.4) * 0.05 + progressScale; // Reduced side-to-side movement
            
            mat2 rot1 = mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
            mat2 rot2 = mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
            dir.xz *= rot1;
            dir.xy *= rot2;
            
            vec3 from = vec3(1.,.5,0.5);
            // Modified time vector to emphasize vertical movement
            from += vec3(0., time*-2., time);  // Changed to emphasize Y axis movement
            from.xz *= rot1;
            from.xy *= rot2;
            
            float s = 0.1;
            float fade = 1.;
            vec3 v = vec3(0.);
            for (int r=0; r<volsteps; r++) {
                if (float(r) >= volstepsMultiplier) break;
                
                vec3 p = from+s*dir*.5;
                p = abs(vec3(tile)-mod(p,vec3(tile*2.)));
                float pa = 0.;
                float a = 0.;
                for (int i=0; i<iterations; i++) {
                    p = abs(p)/dot(p,p)-formuparam;
                    a += abs(length(p)-pa);
                    pa = length(p);
                }
                float dm = max(0.,darkmatter-a*a*.001);
                a *= a*a;
                if (r>6) fade *= 1.-dm;
                v += fade;
                v += vec3(s,s*s,s*s*s*s)*a*brightness*fade;
                fade *= dynamicDistfading;
                s += stepsize;
            }
            v = mix(vec3(length(v)),v,gameProgress);
            return vec4(v*.01,1.);
        }
    ]]
end

function Shader.drawBackground(gameState)
  local w, h = love.graphics.getDimensions()
  -- local progress = math.min(0.9, 0.150 + (gameState.distance/10000) * 0.75)

  
  local factor = math.min(1.0, gameState.distance / 20000)
  local progress = 0.130 + (0.300 * factor)
  local dynamicZoom = 0.300 - (0.200 * factor)
  local volstepsMultiplier = 2 + (5 * factor)
  local dynamicDistfading = 0.130 + (0.600 * factor)
  
  Shader.starfield:send('iResolution', { w, h })
  Shader.starfield:send('iTime', love.timer.getTime())
  Shader.starfield:send('gameProgress', progress)
  Shader.starfield:send('dynamicZoom', dynamicZoom)
  Shader.starfield:send('volstepsMultiplier', volstepsMultiplier)
  Shader.starfield:send('dynamicDistfading', dynamicDistfading)
  
  local previousShader = love.graphics.getShader()
  love.graphics.setShader(Shader.starfield)
  love.graphics.rectangle('fill', 0, 0, w, h)
  love.graphics.setShader(previousShader)
end

return Shader