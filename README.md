# TwintailFlake

Nix flake for [Twintail Launcher](https://github.com/TwintailTeam/TwintailLauncher), a multi-platform launcher for anime games. It builds the launcher from source at the latest release tag, so it can be installed natively on NixOS (or any system with Nix flakes).

Tested on NixOS (unstable, `x86_64-linux`) with Genshin Impact and Honkai: Star Rail.

## Try it

```sh
nix run github:Yuna404/TwintailFlake
```

The first run compiles the launcher from source, which takes a few minutes.

## Install it

Add the flake as an input of your flake:

```nix
inputs.twintail = {
  url = "github:Yuna404/TwintailFlake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add the package, for example in `home.packages` or `environment.systemPackages`:

```nix
inputs.twintail.packages.x86_64-linux.default
```

An overlay is also available (`overlays.default`) and adds `pkgs.twintaillauncher`.
If you use the overlay, your `pkgs` needs `allowUnfree = true` because `steam-run` is unfree.

## Requirements

- Nix with flakes enabled
- A recent nixpkgs (the package uses `fetchPnpmDeps` with `fetcherVersion = 4`)
- `x86_64-linux`

## How it works

- Built with `rustPlatform.buildRustPackage` and `cargo-tauri.hook`, with the frontend dependencies fetched through pnpm.
- The launcher is wrapped in `steam-run`, because pressure-vessel and the game runners expect a regular FHS environment, which NixOS does not provide.
- `mangohud` is added to the `PATH` of the wrapper, since the launcher can use it.
- The wrapper sets `GDK_BACKEND=x11` and `WEBKIT_DISABLE_DMABUF_RENDERER=1` (Wayland and DMABUF rendering caused problems with WebKit on NVIDIA), and adds `libayatana-appindicator` to `LD_LIBRARY_PATH` for the tray icon.

### Why there is a `postPatch`

The Sparkle patch (`apply_patch` in `src-tauri/src/utils/mod.rs`) copies `hkrpg_patch.dll` to `jsproxy.dll` with `fs::copy`, which also copies the permissions of the source file. On Nix the source lives in the read-only store, so the copy ends up read-only too. The next launch then fails to overwrite it and the launcher panics with `PermissionDenied`.

The `postPatch` removes the old `jsproxy.dll` before copying. This is fixed upstream on `master` ([#341](https://github.com/TwintailTeam/TwintailLauncher/pull/341)), so it can be dropped once a release includes the fix.

## Updating

To move to a new release, change `version` in `package.nix` and replace the three hashes (`src`, `cargoHash` and `pnpmDeps`). Set each one to `lib.fakeHash`, build, and copy the hash printed after `got:` from the error.

## Troubleshooting

- **`bwrap: Can't chdir to ...`**: `steam-run` has its own private `/tmp`. Run the launcher from your home directory, not from a directory under `/tmp`.
- **Build fails on `fetcherVersion`**: your nixpkgs is too old, update it.
