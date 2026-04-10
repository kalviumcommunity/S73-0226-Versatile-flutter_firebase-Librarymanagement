# Library One - Release APK Build Guide

## Overview
This guide covers the steps to build a release APK for the "Library One" app with custom icon and branding.

## ✅ Completed Configurations

### 1. App Name Changed to "Library One"
- **File**: `android/app/src/main/AndroidManifest.xml`
- **Change**: Updated `android:label` from "library_management_app" to "Library One"
- **Result**: The app will display as "Library One" on Android devices

### 2. Custom App Icon Generated
- **Package Added**: `flutter_launcher_icons: ^0.13.1`
- **Icon Source**: `assets/icon/app_icon.png`
- **Generated Icons**: All Android density variants (hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)
- **Configuration**: Added to `pubspec.yaml` with proper settings

### 3. Assets Configuration
- **Added**: `assets/images/` and `assets/icon/` directories
- **Icon**: Custom library-themed icon generated for all platforms

### 4. Version Information
- **Version**: 1.0.0+1
- **Build Name**: Library One
- **Package Name**: library_management_app

## 🔧 Build Commands

### Option 1: Standard Release Build
```bash
flutter build apk --release
```

### Option 2: Release Build with Custom Name
```bash
flutter build apk --release --build-name="Library One" --build-number=1
```

### Option 3: Using the Build Script
```bash
powershell -ExecutionPolicy Bypass -File build_release_apk.ps1
```

## 📱 Expected Output

### APK Location
- **Path**: `build/app/outputs/flutter-apk/app-release.apk`
- **Renamed**: `Library_One_v1.0.0.apk` (if using script)

### APK Properties
- **App Name**: Library One
- **Package**: com.example.library_management_app
- **Version**: 1.0.0 (1)
- **Icon**: Custom library-themed icon
- **Size**: ~50-80 MB (estimated)

## 🚀 Features Included

### Core Features
- ✅ Multi-library management system
- ✅ QR code-based book borrowing/returning
- ✅ Reservation system with library validation
- ✅ Google Books API integration
- ✅ Location-based library discovery
- ✅ Dark mode support
- ✅ Role-based access (Admin, Librarian, Reader)

### Recent Fixes Applied
- ✅ Dark mode comprehensive implementation
- ✅ Library validation for all transactions
- ✅ Navigation-based reservation processing
- ✅ Dashboard count fixes
- ✅ Cross-library search functionality
- ✅ Modern UI redesign

## 🔍 Pre-Build Checklist

### 1. Dependencies Check
```bash
flutter doctor
flutter pub get
```

### 2. Code Compilation Check
```bash
flutter analyze
```

### 3. Feature Test (Optional)
```bash
flutter test
```

## 🛠️ Build Troubleshooting

### Common Issues

#### 1. Long Build Times
- **Cause**: Large number of dependencies and assets
- **Solution**: Be patient, builds can take 5-15 minutes
- **Tip**: Use `--verbose` flag to see progress

#### 2. Gradle Issues
- **Solution**: Clean and rebuild
```bash
flutter clean
flutter pub get
flutter build apk --release
```

#### 3. Memory Issues
- **Solution**: Increase Gradle memory in `android/gradle.properties`
```properties
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=512m
```

## 📋 Manual Build Steps

If automated build fails, follow these steps:

### Step 1: Clean Project
```bash
flutter clean
```

### Step 2: Get Dependencies
```bash
flutter pub get
```

### Step 3: Generate Icons (if needed)
```bash
flutter pub run flutter_launcher_icons:main
```

### Step 4: Build APK
```bash
flutter build apk --release --verbose
```

### Step 5: Rename APK
```bash
copy "build/app/outputs/flutter-apk/app-release.apk" "Library_One_v1.0.0.apk"
```

## 🎯 Final APK Details

### App Information
- **Display Name**: Library One
- **Package Name**: com.example.library_management_app
- **Version**: 1.0.0
- **Build Number**: 1
- **Target SDK**: 34
- **Min SDK**: 21

### Permissions
- Internet access
- Camera (QR scanning)
- Location services
- Storage access

### Supported Features
- QR code scanning
- Google Maps integration
- Firebase authentication
- Cloud Firestore database
- Image picking
- Location services

## 📝 Notes

1. **Build Time**: Initial builds may take 10-15 minutes due to dependency compilation
2. **APK Size**: Expected size is 50-80 MB due to comprehensive features
3. **Testing**: Test the APK on different Android versions and devices
4. **Distribution**: APK is ready for distribution via file sharing or app stores

## ✅ Status: Ready for Build

All configurations are complete. The app is ready to be built as a release APK with the name "Library One" and custom branding.