# Runtime and Local Delivery Environment

Checked on 25 September 2026 on the target MacBook Pro M4 Pro (24 GB), macOS 26.6.2, arm64.

| Item | Observed state |
| --- | --- |
| Godot executable | `/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot`, `4.7.2.stable.official.ed1daf0bf` |
| Shell command | `godot` is not on `PATH`; use the absolute binary path or open the packaged app |
| Installed export templates | The local `export_templates/` directory is empty |
| Renderer in visible tests | Metal 4.0, Forward+, Apple M4 Pro; game window 1280 × 720 |
| Original Godot bundle signature | `codesign --verify` reports an invalid arm64 signature for the installed bundle; its runtime nevertheless launches locally |
| Local package | `build/1944 Town Mission.app`, produced by `tools/build_macos.sh` with an unmodified copy of the installed Godot.app and a game-only `Game.pck` |

The current project can be opened in the editor or run from the checkout:

```sh
"/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot" --path "/Users/quan/Documents/ISK/Grade 10/personal project"
```

`--headless --path . --editor --quit` checks imports and script parsing. A separate rendered input-driven test and actual macOS window checks are required for playability; see [QA_REPORT.md](QA_REPORT.md) and [PLAYTEST_REPORT.md](PLAYTEST_REPORT.md).

## Self-contained local package

`bash tools/build_macos.sh` exports a PCK from a strict game-only staging directory and places it alongside a copy of the installed Godot runtime in `build/1944 Town Mission.app`. The outer app's launcher resolves both from its own bundle; the original Downloads path and this checkout are not needed after building. Its outer wrapper has an ad-hoc signature. This is a local Mac package, not an Apple-notarized distribution. The copied nested Godot bundle is not modified or re-signed; its pre-existing invalid signature limits any claim about Gatekeeper acceptance on other Macs. A baseline relocated copy opened its briefing/game/pause screens without the checkout. The final expanded package's exact `Game.pck` completed a rendered input-driven full route from outside the checkout. The final `.app` itself also opened the briefing and town in a native window, paused with Esc and restarted to a fresh briefing using CUA controls. It remains open at the briefing for the user.

Godot's [`--export-pack`](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) worked on this machine without export templates, both in a small scratch project and in the game's packaging script. The usual template-based standalone export is therefore unnecessary for this local delivery. See [PACKAGING.md](PACKAGING.md) for the build command, exact contents and verification boundary. No paid asset, registration or Blender export was needed.

The sampled wooden crate glTF imported in Godot 4.7.2. `reference/.gdignore` is present locally inside the Git-ignored research directory, preventing its images from being scanned as game resources. The builder excludes that directory, source ZIPs, tests and documentation from the game pack.
