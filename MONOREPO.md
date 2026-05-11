# Pneumage Monorepo Structure

This repository uses a monorepo structure to manage both the main Flutter application and its custom plugins.

## Repository Layout

```
pneumage-app/                         (repository root)
├── lib/                              Main application code
├── android/                          Main app Android platform code
├── ios/                              Main app iOS platform code
├── pubspec.yaml                      Main app dependencies
├── plugins/                          Custom Flutter plugins
│   └── pneumage_offline_maps/        Offline maps plugin
│       ├── lib/                      Plugin Dart API
│       ├── android/                  Plugin Android implementation
│       │   └── src/main/kotlin/...   Native Kotlin code
│       ├── IMPLEMENTATION_NOTES.md   Technical documentation
│       └── pubspec.yaml              Plugin dependencies
└── MONOREPO.md                       This file

```

## Why Monorepo?

**Benefits**:
- **Atomic commits**: Changes to both app and plugin can be committed together
- **Simpler workflow**: Single repository to clone, pull, and manage
- **Easier testing**: Test plugin changes immediately in main app context
- **Version sync**: No need to manage separate plugin versions or tags

**When to use separate repos**:
- Plugin shared across multiple projects (not our case)
- Need independent release cycles (not our case)
- Large team with separate ownership (not our case)

## Custom Plugins

### pneumage_offline_maps

**Purpose**: Native Mapbox offline tile downloading and management

**Why a separate plugin?**
- Main app uses `mapbox_maps_flutter` which internally bundles Mapbox SDK
- Direct Mapbox SDK dependency in app causes Gradle "duplicate class" conflicts
- Plugin provides isolated Gradle dependency scope, eliminating conflicts

**Integration**:
```yaml
# pubspec.yaml
dependencies:
  pneumage_offline_maps:
    path: plugins/pneumage_offline_maps  # Local path reference
```

**Documentation**:
- [Implementation Notes](plugins/pneumage_offline_maps/IMPLEMENTATION_NOTES.md) - Complete technical journey
- [Integration Guide](plugins/pneumage_offline_maps/INTEGRATION_GUIDE.md) - API usage examples
- [Plugin README](plugins/pneumage_offline_maps/README.md) - Quick start guide

## Development Workflow

### Building the App

```bash
# From repository root
cd pneumage-app
flutter pub get
flutter run
```

### Working on the Plugin

```bash
# Make changes in plugins/pneumage_offline_maps/
# Changes are immediately reflected in main app (local path dependency)
flutter pub get  # Re-resolve if needed
flutter run      # Test changes
```

### Testing the Plugin Independently

```bash
cd plugins/pneumage_offline_maps/example
flutter run
```

## Git Workflow

**Commit strategy**: Include both app and plugin changes in atomic commits

```bash
# Example: Feature that requires both app and plugin changes
git add lib/services/offline_map_service.dart
git add plugins/pneumage_offline_maps/android/src/main/kotlin/.../Plugin.kt
git commit -m "feat: Add real-time progress tracking for offline downloads"
```

**Branch strategy**: Standard git-flow or GitHub flow applies to entire repo

## Deployment

### Building Release APK/IPA

```bash
# Android
flutter build apk --release

# iOS  
flutter build ipa --release
```

The plugin is automatically compiled and bundled into the app binary.

### CI/CD Considerations

- Single repository means single CI/CD pipeline
- Plugin builds automatically as part of app build
- No need for separate plugin versioning or publishing

## Future Plugins

To add additional custom plugins:

1. Create under `plugins/new_plugin_name/`
2. Use `flutter create --template=plugin` to scaffold
3. Add to main app's `pubspec.yaml`:
   ```yaml
   new_plugin_name:
     path: plugins/new_plugin_name
   ```
4. Document in this file

## Questions?

See detailed documentation:
- [Main App Requirements](REQUIREMENTS.md)
- [Offline Maps Implementation](OFFLINE_MAPS_IMPLEMENTATION_SUMMARY.md)
- [Plugin Technical Notes](plugins/pneumage_offline_maps/IMPLEMENTATION_NOTES.md)

---

**Last Updated**: May 10, 2026  
**Repository**: pneumage-app (monorepo)
