# Strafox

A counterstrafe training game built with LÖVE. Dodge obstacles by strafing left and right — the game evaluates your counterstrafe timing on every direction change.

Movement physics are ported from the Source engine (`Friction` + `Accelerate` from `gamemovement.cpp`) to match the feel of CS2.

## Scoring

**Perfect** (0-60ms) · **Slow** (61-150ms) · **Overlap** (both keys held)

Perfect strafes build combos and multiply your score. Faster counterstrafes within the Perfect window earn up to 2x bonus. Strafes only count when moving above a minimum velocity threshold.

## Controls

- **A / D** — move left / right
- **P** — pause
- **R** — restart
- **ESC** — settings menu
- **S** — submit score (on game over)

## Requirements

- [LÖVE](https://love2d.org/) 11.x+
- Node.js 18+ (web builds only)

## Run

```
love .
```

## Build

### .love file (all platforms)

```
zip -9 -r strafox.love . -x "*.git*" "build/*" "web/*" "scripts/*" "site/*" ".vscode/*"
```

### Linux

```
cat /usr/bin/love strafox.love > build/strafox
chmod +x build/strafox
```

Requires LÖVE installed. Distribute `build/strafox` alongside the LÖVE shared libraries.

### macOS

```
cp -r /Applications/love.app build/Strafox.app
cp strafox.love build/Strafox.app/Contents/Resources/
```

Edit `build/Strafox.app/Contents/Info.plist` and change `CFBundleName` to `Strafox`.

### Windows

Edit `scripts/winbuild.ps1` and set `$LovePath` to your LÖVE install directory, then:

```
powershell -File scripts/winbuild.ps1
```

Output goes to `build/`.

### Web

```
npm install -g love.js
./scripts/buildweb.sh
```

Serve locally:

```
cd web && python3 -m http.server 8000
```

Open `http://localhost:8000`.

The GitHub Actions workflow in `.github/workflows/deploy.yaml` does this automatically on push to `main` and deploys to GitHub Pages.

## HTTPS module (optional)

Score submission on desktop requires the [lua-https](https://github.com/love2d/lua-https) native module. The `libs/` directory contains a prebuilt Linux `.so`. To build for macOS:

```
git clone https://github.com/love2d/lua-https.git
cd lua-https
cmake -Bbuild -S. -DCMAKE_BUILD_TYPE=Release
cmake --build build
cp build/src/https.so /path/to/strafox/libs/
```

The game runs fine without it — score submission is just disabled on desktop.

## License

MIT
