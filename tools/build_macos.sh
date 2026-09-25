#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
build_root="$project_root/build"
bundle="$build_root/1944 Town Mission.app"
godot_app="${GODOT_APP:-/Users/quan/Downloads/Godot.app}"
godot_binary="$godot_app/Contents/MacOS/Godot"
mode="${1:-build}"

fail() {
	printf 'Packaging failed: %s\n' "$1" >&2
	exit 1
}

[[ $# -le 1 && ( "$mode" == "build" || "$mode" == "--list-assets" ) ]] || fail "Usage: build_macos.sh [--list-assets]"
[[ "$(uname -s)" == "Darwin" ]] || fail "This builder requires macOS."
[[ -f "$project_root/project.godot" ]] || fail "Missing project.godot."
[[ -f "$project_root/export_presets.cfg" ]] || fail "Missing export_presets.cfg."
command -v rsync >/dev/null || fail "rsync is required."
if [[ "$mode" == "build" ]]; then
	[[ -x "$godot_binary" ]] || fail "Set GODOT_APP to a local Godot 4.7.2 .app."
	godot_version="$("$godot_binary" --version)"
	[[ "$godot_version" == 4.7.2* ]] || fail "Godot 4.7.2 is required."
	command -v ditto >/dev/null || fail "ditto is required."
	command -v xcrun >/dev/null || fail "Xcode command-line tools are required."
	command -v codesign >/dev/null || fail "codesign is required."
	command -v shasum >/dev/null || fail "shasum is required."
fi

[[ ! -L "$build_root" ]] || fail "Refusing to use a symlinked build directory."
mkdir -p "$build_root"
touch "$build_root/.gdignore"
if [[ "$mode" == "build" ]]; then
	log_dir="$build_root/packaging-logs/$(date -u '+%Y%m%dT%H%M%SZ')-$$"
	mkdir -p "$log_dir"
	if [[ -e "$bundle" && ! -f "$bundle/Contents/Resources/.town-mission-build" ]]; then
		fail "An existing app lacks this builder's marker; move it aside first."
	fi
fi

working="$(mktemp -d "$build_root/.package.XXXXXX")"
cleanup() {
	if [[ -d "$working" && "$working" == "$build_root"/.package.* ]]; then
		rm -rf "$working"
	fi
}
trap cleanup EXIT

stage="$working/project"
candidate="$working/1944 Town Mission.app"
resources="$candidate/Contents/Resources"
mkdir -p "$stage" "$candidate/Contents/MacOS" "$resources/ThirdPartyLicenses"

# Export from a strict game-only mirror. The three runtime trees are recursive,
# so newly integrated environment/player assets are included without editing
# a list of individual texture files. Only importable runtime types are copied;
# source archives, Blender work files, raw FBX and unrelated project data stay out.
cp "$project_root/project.godot" "$project_root/icon.svg" "$project_root/export_presets.cfg" "$stage/"
runtime_filters=(
	--exclude='source/' --exclude='previews/' --exclude='.git/' --exclude='.godot/'
	--include='*/'
	--include='*.gd' --include='*.gdshader' --include='*.shader'
	--include='*.tscn' --include='*.tres' --include='*.res' --include='*.material' --include='*.mesh'
	--include='*.glb' --include='*.gltf' --include='*.bin'
	--include='*.png' --include='*.jpg' --include='*.jpeg' --include='*.webp'
	--include='*.tga' --include='*.bmp' --include='*.exr' --include='*.hdr' --include='*.svg'
	--include='*.ogg' --include='*.wav' --include='*.mp3' --include='*.flac'
	--include='*.ttf' --include='*.otf'
	--include='*.import' --include='*.uid'
	--exclude='*'
)
for tree in scenes scripts assets; do
	[[ -d "$project_root/$tree" ]] || fail "Missing runtime tree: $tree"
	mkdir -p "$stage/$tree"
	# Godot skips any subtree marked .gdignore. Match that editor behavior in
	# staging, including future authoring-only directories outside source/.
	tree_filters=()
	while IFS= read -r -d '' marker; do
		ignored_dir="${marker%/.gdignore}"
		[[ "$ignored_dir" != "$project_root/$tree" ]] || fail "Cannot ignore the whole $tree runtime tree."
		ignored_relative="${ignored_dir#"$project_root/$tree/"}"
		[[ "$ignored_relative" != "$ignored_dir" ]] || fail "Invalid .gdignore path: $marker"
		tree_filters+=("--exclude=/$ignored_relative/***")
	done < <(find "$project_root/$tree" -name .gdignore -type f -print0)
	tree_filters+=("${runtime_filters[@]}")
	rsync -a --prune-empty-dirs "${tree_filters[@]}" "$project_root/$tree/" "$stage/$tree/"
done

[[ -z "$(find "$stage" -type l -print -quit)" ]] || fail "Runtime staging must not contain symlinks."

# Keep authored import settings for copied sources, but drop stale sidecars for
# FBX/work files that are intentionally absent from the staging project.
while IFS= read -r -d '' sidecar; do
	[[ -f "${sidecar%.*}" ]] || rm "$sidecar"
done < <(find "$stage/scenes" "$stage/scripts" "$stage/assets" -type f \( -name '*.import' -o -name '*.uid' \) -print0)

asset_manifest="$working/asset-manifest.txt"
(cd "$stage" && find assets -type f | LC_ALL=C sort) > "$asset_manifest"
if [[ "$mode" == "--list-assets" ]]; then
	cat "$asset_manifest"
	exit 0
fi
cp "$asset_manifest" "$log_dir/asset-manifest.txt"

# New visual production uses Godot-importable GLB. A source-only Sten directory
# must not silently produce another placeholder-only package.
sten_runtime="$stage/assets/vendor/weapon_visual/sten_mk2/runtime/sten_mk2.glb"
if [[ -d "$project_root/assets/vendor/weapon_visual/sten_mk2" ]]; then
	[[ -s "$sten_runtime" ]] || fail "Sten runtime GLB is missing; source FBX is not packaged."
	sten_attribution="$project_root/assets/vendor/weapon_visual/sten_mk2/ATTRIBUTION.txt"
	[[ -s "$sten_attribution" ]] || fail "Sten CC BY 3.0 attribution file is missing."
	for required in 'Lotnik' 'Sten mk2' 'https://opengameart.org/content/sten-mk2' \
		'https://creativecommons.org/licenses/by/3.0/' 'Changes:'; do
		grep -Fq "$required" "$sten_attribution" || fail "Sten attribution lacks: $required"
	done
fi
character_root="$project_root/assets/vendor/character_visual/makehuman"
if [[ -d "$character_root" ]]; then
	for model in contact_idle guard_field_morph scout_idle; do
		[[ -s "$stage/assets/vendor/character_visual/makehuman/runtime/$model.glb" ]] || \
			fail "Character runtime GLB is missing: $model"
	done
	character_provenance="$character_root/PROVENANCE.txt"
	[[ -s "$character_provenance" ]] || fail "Character source and CC0 provenance are missing."
fi

printf 'Importing game-only staging project...\n'
"$godot_binary" --headless --path "$stage" --log-file "$log_dir/import.log" --import >/dev/null
printf 'Exporting game pack...\n'
"$godot_binary" --headless --path "$stage" --log-file "$log_dir/export.log" \
	--export-pack macOS "$resources/Game.pck" >/dev/null
[[ -s "$resources/Game.pck" ]] || fail "Godot did not produce a game pack."

source_sha="unversioned"
source_dirty="unknown"
if git -C "$project_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	source_sha="$(git -C "$project_root" rev-parse HEAD)"
	source_dirty="false"
	if [[ -n "$(git -C "$project_root" status --porcelain --untracked-files=normal)" ]]; then
		source_dirty="true"
	fi
fi
pack_sha="$(shasum -a 256 "$resources/Game.pck" | awk '{print $1}')"
cat > "$resources/BUILD_INFO.txt" <<INFO
Built (UTC): $(date -u '+%Y-%m-%dT%H:%M:%SZ')
Source Git SHA: $source_sha
Source dirty: $source_dirty
Game.pck SHA-256: $pack_sha
Godot: $godot_version
INFO

printf 'Embedding installed Godot runtime...\n'
ditto "$godot_app" "$resources/Godot.app"
cmp -s "$godot_binary" "$resources/Godot.app/Contents/MacOS/Godot" || fail "Runtime copy differs from source."
cp "$project_root/assets/vendor/polyhaven/LICENSE.txt" "$resources/ThirdPartyLicenses/POLYHAVEN_LICENSE.txt"
if [[ -f "$sten_runtime" ]]; then
	cp "$sten_attribution" "$resources/ThirdPartyLicenses/STEN_MK2_ATTRIBUTION.txt"
fi
if [[ -d "$character_root" ]]; then
	cp "$character_provenance" "$resources/ThirdPartyLicenses/MAKEHUMAN_CHARACTER_PROVENANCE.txt"
fi
cat > "$resources/ThirdPartyLicenses/GODOT_LICENSE.txt" <<'LICENSE'
Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE

cat > "$candidate/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>en</string>
	<key>CFBundleDisplayName</key><string>1944 Town Mission</string>
	<key>CFBundleExecutable</key><string>TownMissionLauncher</string>
	<key>CFBundleIdentifier</key><string>local.personalproject.townmission</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleName</key><string>1944 Town Mission</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>0.1.0</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>LSMinimumSystemVersion</key><string>13.0</string>
	<key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

cat > "$working/launcher.c" <<'C_SOURCE'
#include <errno.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv) {
	char executable[PATH_MAX];
	uint32_t capacity = (uint32_t) sizeof(executable);
	if (_NSGetExecutablePath(executable, &capacity) != 0) {
		fputs("Cannot locate the game launcher.\n", stderr);
		return 1;
	}
	char resolved[PATH_MAX];
	if (realpath(executable, resolved) == NULL) {
		perror("Cannot resolve game launcher");
		return 1;
	}
	char *last_slash = strrchr(resolved, '/');
	if (last_slash == NULL) return 1;
	*last_slash = '\0';
	char runtime[PATH_MAX];
	char pack[PATH_MAX];
	int n1 = snprintf(runtime, sizeof(runtime), "%s/../Resources/Godot.app/Contents/MacOS/Godot", resolved);
	int n2 = snprintf(pack, sizeof(pack), "%s/../Resources/Game.pck", resolved);
	if (n1 < 0 || n2 < 0 || n1 >= (int) sizeof(runtime) || n2 >= (int) sizeof(pack)) {
		fputs("Game bundle path is too long.\n", stderr);
		return 1;
	}
	if (access(runtime, X_OK) != 0 || access(pack, R_OK) != 0) {
		fputs("Game bundle is incomplete.\n", stderr);
		return 1;
	}
	char **arguments = calloc((size_t) argc + 3, sizeof(char *));
	if (arguments == NULL) return 1;
	arguments[0] = runtime;
	arguments[1] = "--main-pack";
	arguments[2] = pack;
	for (int i = 1; i < argc; ++i) arguments[i + 2] = argv[i];
	execv(runtime, arguments);
	perror("Could not launch the bundled Godot runtime");
	return 1;
}
C_SOURCE

xcrun clang -O2 -Wall -Wextra -o "$candidate/Contents/MacOS/TownMissionLauncher" "$working/launcher.c"
chmod +x "$candidate/Contents/MacOS/TownMissionLauncher"
touch "$resources/.town-mission-build"
plutil -lint "$candidate/Contents/Info.plist" >/dev/null
codesign --force --sign - "$candidate"
codesign --verify "$candidate"
diff -rq "$godot_app" "$resources/Godot.app" >/dev/null || fail "Wrapper signing altered the nested Godot.app."

if [[ -e "$bundle" ]]; then
	rm -rf "$bundle"
fi
mv "$candidate" "$bundle"
printf 'Built: %s\n' "$bundle"
printf 'Packaging logs: %s\n' "$log_dir"
du -sh "$bundle"
