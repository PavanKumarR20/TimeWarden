## 📱 App Icon Setup Guide for TimeWarden

### How App Icons Work in Flutter:

**You need to manually replace icon files in your project folders:**

#### For Android:
1. Navigate to: `android/app/src/main/res/`
2. Replace icons in these folders:
   - `mipmap-hdpi/ic_launcher.png` (72x72)
   - `mipmap-mdpi/ic_launcher.png` (48x48) 
   - `mipmap-xhdpi/ic_launcher.png` (96x96)
   - `mipmap-xxhdpi/ic_launcher.png` (144x144)
   - `mipmap-xxxhdpi/ic_launcher.png` (192x192)

#### For iOS:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Navigate to `Runner > Assets.xcassets > AppIcon.appiconset`
3. Drag and drop your icon files for each size

### 🛠️ Easy Way - Use flutter_launcher_icons Package:

1. Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/app_icon.png"
  min_sdk_android: 21
```

2. Create a 1024x1024 PNG icon file at `assets/icons/app_icon.png`

3. Run: `flutter pub get && dart run flutter_launcher_icons`

### 📸 Getting Icons from the Preview App:

1. Run: `flutter run lib/preview_main.dart`
2. Tap "Preview App Icons"
3. Take screenshots of different sized icons
4. Use image editing software to crop and save as PNG files
5. Follow the steps above to replace them

### 🎨 Current Icon Design:
- Clean indigo/blue gradient background
- Simple timer icon with rotating border
- Minimal shadows and effects
- Perfect for both light and dark themes

The preview app shows you exactly what the icons will look like at different sizes!
