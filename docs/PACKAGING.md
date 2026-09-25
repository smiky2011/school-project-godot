# Local macOS Package

Status: self-contained local build using the installed Godot 4.7.2 editor runtime. This is a practical Mac delivery path while official export templates are not installed. It is larger than a template export because it embeds the full unmodified Godot application.

From the project directory, run `bash tools/build_macos.sh`; from elsewhere, give the script's absolute path. By default the script reads `/Users/quan/Downloads/Godot.app`; set `GODOT_APP=/absolute/path/to/Godot.app` to use another installed Godot 4.7.2 bundle. It needs built-in macOS `ditto`, `codesign`, `rsync`, and Xcode command-line `clang` through `xcrun`. No paid account, export template, network download or registration is required.

The output is the ignored `build/1944 Town Mission.app`. Double-click or `open` that app. The outer application contains a small launcher which locates its own bundled Godot binary and `Game.pck`; neither the original project directory, the original Downloads app nor the current working directory is needed after packaging. The launcher and outer app receive an ad-hoc signature. This is a local build, not Apple notarization for broad distribution. `Contents/Resources/BUILD_INFO.txt` records the build time, source Git commit and dirty state, PCK SHA-256 and Godot version. Import/export logs stay under `build/packaging-logs/` for review even if a build fails.

The PCK is exported from a strict game-only staging project. It contains the project settings, main scene, scripts and required CC0 textures/model. The local `reference/` research directory, source download archives, documentation, tests, build scripts, Git data and editor caches stay out of the pack. The app also carries Godot's MIT license and the Poly Haven asset license under `Contents/Resources/ThirdPartyLicenses/`. The original installed Godot.app is copied without changing its executable or bundle contents.

Build validation should check the PCK import/export log, the outer signature, a startup from a different working directory, and an actual open/play session on the target Mac. A successful headless launch or signed bundle alone does not prove that the game plays through.
