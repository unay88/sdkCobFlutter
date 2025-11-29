# BJB COB SDK

Universal Flutter plugin for BJB Customer Onboarding SDK supporting both iOS and Android platforms.

## Features

- Email verification flow
- KYC verification
- Account and card selection
- Terms and conditions agreement
- Cross-platform support (iOS & Android)

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  bjb_cob_sdk:
    path: /path/to/bjb_cob_sdk
```

## Usage

```dart
import 'package:bjb_cob_sdk/bjb_cob_sdk.dart';

// Start email verification
final result = await BjbCobSdk.startEmailVerification(
  phoneNumber: '62811247135',
  email: 'user@example.com',
);

if (result.isSuccess) {
  print('COB flow completed successfully');
} else if (result.isCancelled) {
  print('COB flow was cancelled');
} else {
  print('COB flow failed: ${result.errorMessage}');
}

// Launch KYC directly
final kycResult = await BjbCobSdk.launchKYC();
```

## Platform Setup

### iOS
Add to your `ios/Podfile`:
```ruby
# COB SDK dependencies will be auto-resolved
```

### Android
Add to your `android/app/build.gradle`:
```gradle
dependencies {
    implementation project(':cob-sdk')
}
```

## API Reference

### BjbCobSdk.startEmailVerification()
Starts the complete COB flow with email verification.

**Parameters:**
- `phoneNumber` (String): User's phone number
- `email` (String): User's email address

**Returns:** `Future<SdkCobResult>`

### BjbCobSdk.launchKYC()
Launches KYC verification directly.

**Returns:** `Future<SdkCobResult>`

### SdkCobResult
Result object containing:
- `status` (SdkCobStatus): success, cancelled, or error
- `data` (Map<String, dynamic>?): Additional result data
- `errorMessage` (String?): Error message if failed