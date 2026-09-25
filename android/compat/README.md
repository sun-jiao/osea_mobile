# CamerAwesome Android build adapter

CamerAwesome 2.5.0 still applies `kotlin-android` and uses `kotlinOptions`.
`camerawesome.gradle` is its MIT-licensed Android build script with only these
changes:

- Remove its legacy AGP/Kotlin buildscript dependencies and Kotlin plugin apply.
- Configure the existing JVM 1.8 target through `kotlin.compilerOptions`.

`settings.gradle.kts` selects this script using a relative path from the hosted
plugin directory. Source files, resources and manifest remain in the original
Pub package. The shared Pub cache is never modified. The original build script's
SHA-256 is checked before the override, and `pubspec.yaml` pins version 2.5.0.
An upstream build change fails with a review instruction instead of silently
applying a stale adapter.

The app enables `android.builtInKotlin=true` and requires Flutter 3.47 or newer.
The Kotlin plugin version remains declared with `apply false` to raise AGP 9.0.1's
bundled compiler above Flutter's minimum, without applying the legacy plugin.
`android.newDsl=false` is retained as required by the current Flutter integration;
it is a separate migration from built-in Kotlin.

Remove this override, hash check and version pin once a tested upstream release
supports built-in Kotlin. Rebuild both Debug and Release after any such change.

References:
- https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers
- https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
