## Quick Setup for App Icons

### Step 1: Add to pubspec.yaml
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#1976D2"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
```

### Step 2: Create the assets folder
```bash
mkdir -p assets/icons
```

### Step 3: Get a 1024x1024 icon
- Take a screenshot of the 192x192 icon from the preview app
- Use any image editor to resize it to 1024x1024
- Save as `assets/icons/app_icon.png`

### Step 4: Run the generator
```bash
flutter pub get
dart run flutter_launcher_icons
```

This will automatically create all the different sizes for Android and iOS!
