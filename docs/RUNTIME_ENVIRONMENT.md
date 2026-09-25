# Runtime and Local Delivery Environment

Checked on 25 September 2026. This is installation evidence, not a gameplay or export result.

| Item | Observed state |
| --- | --- |
| Host | macOS 26.6.2, arm64 (target MacBook Pro M4 Pro, 24 GB per game vision) |
| Godot | `/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot`, `4.7.2.stable.official.ed1daf0bf` |
| Shell command | `godot` is not on `PATH`; use the absolute binary path above |
| Godot app | Universal x86_64/arm64 bundle, vendor signed and notarization ticket stapled |
| Export templates | `~/Library/Application Support/Godot/export_templates/` exists but is empty |
| Repository | Godot 4.7 project; before production, no main scene existed |

Launch the current checkout after a main scene is set:

```sh
"/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot" --path "/Users/quan/Documents/ISK/Grade 10/personal project"
```

Use `--headless --editor --quit` for an import/parser check. It cannot prove mission playability. In a scratch project, the acquired wooden crate glTF imported with Godot 4.7.2 and produced a cached scene. Godot emitted a sandbox-only editor-settings write error outside the writable workspace after import; the import process exited zero, and imported resource files were present. In-game placement and visible rendering remain to be checked.

## Packaging decision pending a playable project

[Godot's macOS export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html) says the matching export templates are needed for the standard Universal 2 `.app` export. They are absent locally. Preferred delivery after gameplay validation: obtain official 4.7.2 templates, export a local `.app`, test its actual window and mission loop on this Mac, and keep the build in ignored `build/` or `dist/`. The official all-platform template package is much larger than this sample project, so a minimal macOS-only route should be assessed before downloading it. As a fallback for this same Mac, a launch script can invoke the already installed Godot app against the checkout; this would be a local runnable project, but it is not yet a self-contained game export. No packaging claim is made until the final artifact has been launched and played.

The 1K Poly Haven glTF import experiment did not require Blender. `reference/.gdignore` is present locally inside the ignored reference directory so research imagery is skipped by Godot's file scanner.
