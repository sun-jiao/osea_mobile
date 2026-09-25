# *OSEA* Mobile

<img src="/assets/icons/fore.png?raw=true" alt="icon" width="200"/>

[![EcoEvoRxiv](https://img.shields.io/badge/EcoEvoRxiv-doi:10.32942/X2FP6T-blue.svg?style=flat&labelColor=whitesmoke)](http://dx.doi.org/10.32942/X2FP6T)

Flutter app for offline bird identification

For the detecting task, we uses pretrained model `ssd mobilenet`.

For the classification task, `ResNet34` model structure was adopted, take [MetaFGNet/L_Bird_pretrain/checkpoints](https://drive.google.com/drive/folders/1gsct7uWHYPfmNmFvLVHlgFqKOcoQRzs9) as a pretrained model, trained on [DongNiao DIB-10K](https://www.researchgate.net/publication/344639013) using [Gorilla-Lab-SCUT/MetaFGNet](https://github.com/Gorilla-Lab-SCUT/MetaFGNet).

Structure of `assets` folder:
- assets
    - icons (all in git)
    - db
      - [avonet.db](https://github.com/sun-jiao/osea_mobile/releases/download/assets/avonet.db)
    - labels
      - [bird_info.json](https://github.com/sun-jiao/osea_mobile/releases/download/assets/bird_info.json)
    - models
      - bird_model.onnx (the [quantized onnx version](https://github.com/sun-jiao/osea_mobile/releases/download/assets/bird_model.onnx) of [model20240824.pth](https://github.com/sun-jiao/MetaFGNet/releases))
      - ssd_mobilenet.onnx (the [quantized version](https://github.com/sun-jiao/osea_mobile/releases/download/assets/ssd_mobilenet.onnx) of pre-trained model from [onnx modelzoo](https://github.com/onnx/models/tree/main/validated/vision/object_detection_segmentation/ssd-mobilenetv1))

Download all files by running `assets_download.sh`.

If you want to run batch classification for multiple photos, please check [osea-cli](https://github.com/sun-jiao/osea).

## Reproducible development setup

The current dependency lockfile is checked in. Use Flutter **3.47.4** (Dart
**3.13.3**), JDK **25** (the local Android Studio bundled runtime), and Android
SDK platform **36** for the verified setup. Java and Kotlin bytecode target **17**.
The Gradle wrapper and Android/Kotlin plugin versions are pinned in `android/`.
The minimum Flutter/Dart versions in `pubspec.yaml` reflect the dependencies.

The ONNX runtime is a companion checkout. Create the following sibling layout:

```text
workspace/
  birdid/
  onnxruntime_flutter/
```

```bash
git clone https://github.com/sun-jiao/onnxruntime_flutter.git ../onnxruntime_flutter
git -C ../onnxruntime_flutter checkout 5fea63bc93b400c3e7aa25a98df0be594763f43f
bash assets_download.sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
python3 -m unittest discover -s test -p 'test_*.py'
flutter build apk --debug
```

For an existing companion checkout, preserve local work before changing its
revision. When updating the ONNX dependency, update this revision together with
`pubspec.lock`. Do not use `pub upgrade` as part of a normal build.

The asset downloader verifies SHA-256 hashes, skips valid local files, rejects
HTTP errors, and replaces each file only after verification. Hashes pin the
existing project assets; update them deliberately when publishing new models or
data. Temporary downloads are removed on failure. Assets and model files remain
outside Git.

## Release signing

Release builds require a real keystore. Supply `KEYSTORE`, `KEYSTORE_PASSWORD`,
`KEY_ALIAS`, and `KEY_PASSWORD` through the build environment, or use the ignored
`android/key.properties` file:

```properties
storeFile=/absolute/path/to/release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

```bash
flutter build appbundle --release
```

When switching from an integration-test build to Release, use the full Flutter
build command above (without `--no-pub`) so Flutter regenerates the native plugin
registrant without development-only plugins.

Missing release credentials stop the build; debug builds use the standard debug
key. Do not commit keystores or passwords.

## Runtime behavior and validation

Identification allows one operation at a time and offers retry after failure.
Detection currently uses a **0.5** confidence threshold and rejects invalid crop
boxes; calibrate the threshold against representative bird photographs before a
release. Location failures fall back to global identification; single location
fixes have a 15-second timeout. Unmapped species are excluded from regional SQL
results. Map tiles use flutter_map's built-in disk cache through its public API;
this cache is best-effort and is not an offline map download feature. Previous
custom cache files are not migrated.

Automated tests cover unmapped species and regional boundaries, invalid crop
boxes, large classification logits, identification concurrency/retry/disposal,
location denial and timeouts, late/duplicate crop callbacks, location-mode changes
during pending requests, and asset download failures. Before publishing,
exercise camera/gallery input, manual cropping, repeated map entry and rotation,
location permissions and offline behavior on Android and iOS devices. iOS builds
require macOS with Xcode.

## Platform validation

Android now uses AGP's built-in Kotlin with Flutter 3.47+. CamerAwesome 2.5.0
requires a small, pinned build-script adapter; see
[android/compat/README.md](android/compat/README.md). The plugin cache is not
modified. Jetifier is disabled. The legacy AGP DSL opt-out remains until the
Flutter integration supports migrating that separately.

Run the native smoke test on a connected Android device:

```bash
ORG_GRADLE_PROJECT_validationBuild=true flutter test integration_test/native_smoke_test.dart -d DEVICE_ID
```

This creates `net.sunjiao.birdid.validation` (launcher name **OSEA Validation**),
so the normal installed app and its data are preserved. The test also drives manual crop, cancellation, and repeated map navigation
using a synthetic image supplied through the picker seam. It loads both
bundled ONNX models, performs real CPU inference, checks model/label alignment,
excludes unlabeled output channels, reuses the inference worker, and queries the bundled regional database. Its
synthetic input verifies execution, not bird recognition accuracy. It does not
calibrate the 0.5 detector threshold; that requires representative photos with
bird bounding-box annotations, including images without birds.

The iOS project targets iOS 15, has CocoaPods configuration, and adopts Flutter's
UIScene lifecycle. On macOS with Xcode and CocoaPods, run:

```bash
flutter pub get --enforce-lockfile
flutter build ios --debug --no-codesign
```

The `ios-build` CI job performs this unsigned build. CI configuration is not
proof of a passing build until the job has actually run. Camera permissions,
photo selection, and model execution must also be exercised on a physical iPhone.

### Verification record (2026-09-25)

- Android Debug and signed Release APK builds passed with built-in Kotlin.
- 22 Flutter unit/widget tests and 2 asset-downloader tests passed; Dart analysis
  reports no issues.
- Android 16 (API 36), device model CPH2581: native integration smoke test passed
  using the separate validation application ID. Manual crop → inference, two map
  visits, and crop cancellation passed on the same device. The system camera and
  photo-library picker themselves were not automated in this test.
- Bundled classifier output: 11,000 channels; label file: 10,964 species.
  Ranking uses only labeled channels, preserving their original class IDs.
  Too few channels or non-finite labeled scores produces an explicit failure.
- iOS Podfile Ruby syntax and property-list parsing checked on Linux. Xcode build
  and physical iPhone checks remain unverified locally.
- Detector accuracy/threshold calibration remains pending a labeled photo set.
