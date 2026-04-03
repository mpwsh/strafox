# Strafox

A counterstrafe training game built with LÖVE. Dodge obstacles by strafing left and right — the game evaluates your counterstrafe timing on every direction change.

**Perfect** (0-40ms) · **Slow** (41-100ms) · **Overlap** (both keys held)

Perfect strafes build combos and multiply your score. Mistakes break your combo.

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

```bash
love .
```

## Build

### .love file (all platforms)

```bash
zip -9 -r strafox.love . -x "*.git*" "build/*" "web/*" "scripts/*" "site/*" ".vscode/*"
```

### Linux

```bash
cat /usr/bin/love strafox.love > build/strafox
chmod +x build/strafox
```

Requires LÖVE installed. Distribute `build/strafox` alongside the LÖVE shared libraries.

### macOS

```bash
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

```bash
npm install -g love.js
./scripts/buildweb.sh
```

Serve locally:

```bash
cd web && python3 -m http.server 8000
```

Open `http://localhost:8000`.

The GitHub Actions workflow in `.github/workflows/deploy.yaml` does this automatically on push to `main` and deploys to GitHub Pages.

## License

MIT
