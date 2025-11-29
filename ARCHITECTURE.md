# bjb_cob_sdk Architecture

## Overview

`bjb_cob_sdk` adalah **Flutter Plugin** yang membungkus native SDK untuk iOS dan Android.

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (Dart)                      │
│                  example/lib/main.dart                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Method Channel
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              bjb_cob_sdk (Flutter Plugin)                   │
│                                                             │
│  ┌─────────────────────┐      ┌─────────────────────┐     │
│  │   Dart Interface    │      │   Dart Interface    │     │
│  │   lib/bjb_cob_sdk   │      │   lib/bjb_cob_sdk   │     │
│  └─────────────────────┘      └─────────────────────┘     │
│            │                            │                   │
│            ▼                            ▼                   │
│  ┌─────────────────────┐      ┌─────────────────────┐     │
│  │  Android Native     │      │   iOS Native        │     │
│  │  BjbCobSdkPlugin    │      │  BjbCobSdkPlugin    │     │
│  │  (Kotlin/Java)      │      │  (Swift)            │     │
│  └─────────────────────┘      └─────────────────────┘     │
│            │                            │                   │
└────────────┼────────────────────────────┼───────────────────┘
             │                            │
             ▼                            ▼
┌─────────────────────┐      ┌─────────────────────┐
│  Android Native SDK │      │  iOS Native SDK     │
│  com.bjb.cob:       │      │  sdkCob             │
│  cob-lib:0.4.3      │      │  1.0.0              │
│  (Maven)            │      │  (CocoaPods)        │
└─────────────────────┘      └─────────────────────┘
```

## Struktur Direktori

```
bjb_cob_sdk_test/
├── lib/
│   └── bjb_cob_sdk.dart          # Dart interface (Flutter)
├── android/
│   ├── build.gradle               # Android dependency
│   │   └── implementation 'com.bjb.cob:cob-lib:0.4.3-SNAPSHOT'
│   └── src/
│       └── BjbCobSdkPlugin.kt    # Android wrapper
├── ios/
│   ├── bjb_cob_sdk.podspec       # iOS dependency
│   │   └── s.dependency 'sdkCob', '1.0.0'
│   └── Classes/
│       └── BjbCobSdkPlugin.swift # iOS wrapper
└── pubspec.yaml                   # Flutter plugin config
```

## Dependency Chain

### Android
```
Flutter App
  └── bjb_cob_sdk (Flutter Plugin)
      └── com.bjb.cob:cob-lib:0.4.3-SNAPSHOT (Maven)
```

### iOS
```
Flutter App
  └── bjb_cob_sdk (Flutter Plugin)
      └── sdkCob 1.0.0 (CocoaPods Specs)
          └── https://github.com/unay88/sdkCob.git
```

## Native SDK Repositories

### Android (Maven)
- **Type**: Maven Repository
- **Dependency**: `implementation 'com.bjb.cob:cob-lib:0.4.3-SNAPSHOT'`
- **Location**: Private Maven repository

### iOS (CocoaPods)
- **Type**: CocoaPods Specs Repository
- **Dependency**: `pod 'sdkCob', '1.0.0'`
- **Source Code**: https://github.com/unay88/sdkCob.git
- **Specs Repo**: https://github.com/unay88/SpecsRepoCob.git

## Konsistensi Platform

Kedua platform sekarang menggunakan **repository dependency** (bukan local path):

| Platform | Repository Type | Dependency Format |
|----------|----------------|-------------------|
| Android  | Maven          | `implementation 'com.bjb.cob:cob-lib:0.4.3-SNAPSHOT'` |
| iOS      | CocoaPods Specs | `pod 'sdkCob', '1.0.0'` |

## Cara Penggunaan

### 1. Tambahkan dependency di pubspec.yaml
```yaml
dependencies:
  bjb_cob_sdk:
    path: /path/to/bjb_cob_sdk_test
```

### 2. iOS: Tambahkan specs source di Podfile
```ruby
source 'https://github.com/unay88/SpecsRepoCob.git'
source 'https://github.com/CocoaPods/Specs.git'

target 'Runner' do
  pod 'DigitalIdentity', :git => 'https://github.com/unay88/sdkGtf.git'
  pod 'Ojo', :git => 'https://github.com/unay88/sdkGtf.git'
  pod 'sdkCob', '1.0.0'
end
```

### 3. Install
```bash
# Flutter
flutter pub get

# iOS
cd ios && pod install
```

## Summary

✅ **bjb_cob_sdk** = Flutter Plugin (wrapper)
✅ **Native Android SDK** = Maven dependency (`com.bjb.cob:cob-lib:0.4.3-SNAPSHOT`)
✅ **Native iOS SDK** = CocoaPods dependency (`sdkCob 1.0.0`)
✅ **Konsisten** = Kedua platform menggunakan repository dependency
