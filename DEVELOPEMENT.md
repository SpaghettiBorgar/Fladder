# 🚀 Fladder Dev Setup

## 🔧 Requirements

Ensure the following tools are installed:

- [FVM](https://fvm.app/) — installs the Flutter version pinned in `.fvmrc` via `fvm install`.
  The `make` targets call `fvm flutter`; pass `FVM=` to use a system-wide Flutter instead.
- `make`
- [Android Studio](https://developer.android.com/studio) (for Android development and emulators)
- [VS Code](https://code.visualstudio.com/) with:
  - Flutter extension
  - Dart extension

Verify your Flutter setup with:

```bash
fvm flutter doctor
```

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/DonutWare/Fladder.git
cd Fladder

# Install dependencies and generate code
make bootstrap
```

All generated code is gitignored, so `make bootstrap` (or the manual steps under
[Code Generation](#️-code-generation)) is required before the project will analyze or build.

Run `make help` to list every target. Common ones:

```bash
make run                # debug run, prompts if several devices are connected
make run-linux          # debug run on a named device (run-android, run-macos, ...)
make run-web            # debug run in Chrome on WEB_PORT=9090
make check              # format check + analysis + tests
make all                # bootstrap, check, and build a release for the current host
```

Variables can be overridden on any target:

| Variable | Default | Notes |
| --- | --- | --- |
| `FLAVOR` | `development` | `development` or `production`; Android/iOS/macOS only |
| `MODE` | `release` | `debug`, `profile` or `release`, for `build-*` targets |
| `BUILD_NUMBER` | `1` | |
| `DEVICE` / `ARGS` | – | passed through to `flutter run`/`build` |
| `FVM` | `fvm` | set `FVM=` to use the `flutter` already on your `PATH` |

```bash
make build-apk MODE=debug           # debug APKs of the development flavor
make build-macos FLAVOR=production  # production macOS app
make release-web                    # codegen + production release build
```

## 🐧 Linux Dependencies

If you're on **Linux**, install the `mpv` dependency:

```bash
sudo apt install libmpv-dev
```

## 🛠️ Running the App

1. **Connect a device** or launch an emulator.
2. In VS Code:
   - Select the target device (bottom right corner).
   - Press `F5` or go to **Run > Start Debugging**.
   - If prompted, select **"Run Anyway"**.

Or from the terminal with `make run` / `make run-<device>` (see Quick Start).

## 📦 Android Signing

Release Android builds are signed with the debug key unless `android/app/key.properties`
exists. To sign with your own keystore, place `keystore.jks` next to it and add:

```properties
storePassword=...
keyPassword=...
keyAlias=...
```

Both files are gitignored.

## ⚙️ Code Generation

`make codegen` runs every generator and formats the result. The individual steps:

```bash
make pigeon        # platform-channel bindings from pigeons/*.dart
make build-runner  # json_serializable, freezed, dart_mappable, chopper, auto_route, drift, ...
make l10n          # localizations from lib/l10n/*.arb
make format        # build_runner emits 80-column code; the project uses 120
```

> Tip: Use `make watch` for continuous builds during development. Its output is not
> formatted as it goes, so run `make format` before committing.

Use `make regen` to delete all generated sources and rebuild them from scratch.

## 🌐 Using a demo Server
You can use a fake server from Jellyfin.
https://demo.jellyfin.org/stable/web/