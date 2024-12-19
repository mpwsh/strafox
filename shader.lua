local Shader = {}

function Shader.load()
  Shader.starfield = love.graphics.newShader [[
        extern vec2 iResolution;
        extern float iTime;
        extern float gameProgress;

        const int iterations = 17;
        const float formuparam = 0.53;
        const int volsteps = 20;
        const float stepsize = 0.1;
        const float zoom = 0.800;
        const float tile = 0.850;
        const float speed = 0.005;
        const float brightness = 0.0015;
        const float darkmatter = 0.300;
        const float distfading = 0.730;
        const float saturation = 0.850;

        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 screen_coords) {
            vec2 uv = screen_coords.xy/iResolution.xy-.5;
            uv.y *= iResolution.y/iResolution.x;
            vec3 dir = vec3(uv*zoom,1.);
            float time = iTime*speed+.25;

            // Use gameProgress for rotation instead of mouse
            float progressScale = gameProgress * 0.001;
            float a1 = sin(time * 0.5) * 0.2 + progressScale;
            float a2 = cos(time * 0.3) * 0.1 + progressScale;

            mat2 rot1 = mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
            mat2 rot2 = mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
            dir.xz *= rot1;
            dir.xy *= rot2;
            vec3 from = vec3(1.,.5,0.5);
            from += vec3(time*2.,time,-2.);
            from.xz *= rot1;
            from.xy *= rot2;

            float s = 0.1;
            float fade = 1.;
            vec3 v = vec3(0.);
            for (int r=0; r<volsteps; r++) {
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
                fade *= distfading;
                s += stepsize;
            }
            v = mix(vec3(length(v)),v,saturation);
            return vec4(v*.01,1.);
        }
    ]]
end

function Shader.drawBackground(gameState)
  local w, h = love.graphics.getDimensions()
  -- Use distance for smoother progress
  local progress = gameState.distance / 1000 -- Adjust divisor to control rotation speed

  Shader.starfield:send('iResolution', { w, h })
  Shader.starfield:send('iTime', love.timer.getTime())
  Shader.starfield:send('gameProgress', progress)

  local previousShader = love.graphics.getShader()
  love.graphics.setShader(Shader.starfield)
  love.graphics.rectangle('fill', 0, 0, w, h)
  love.graphics.setShader(previousShader)
end

return Shader
