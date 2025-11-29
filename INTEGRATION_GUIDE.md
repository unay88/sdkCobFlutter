# BJB COB SDK - Integration Guide

## Push Notification Setup

### iOS (Required - 1 Line Integration)

Karena limitasi platform iOS, push notification **harus** diterima oleh AppDelegate host terlebih dahulu. Namun integrasi sangat minimal - **hanya 1 baris kode**.

#### Step 1: Import SDK

```swift
import bjb_cob_sdk
```

#### Step 2: Tambahkan Handler (1 Baris)

Di method `userNotificationCenter`, tambahkan **1 baris** ini:

```swift
override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    
    // ✅ Tambahkan 1 baris ini:
    CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
    
    completionHandler([[.alert, .sound, .badge]])
}

override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    
    // ✅ Tambahkan 1 baris ini:
    CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
    
    completionHandler()
}
```

**Selesai!** Handler akan otomatis:
- ✅ Deteksi apakah notifikasi untuk COB SDK
- ✅ Teruskan ke SDK jika valid
- ✅ Ignore jika bukan untuk SDK (tidak mengganggu notifikasi lain)

### Android (No Integration Required)

Android SDK sudah handle push notification secara otomatis. **Tidak perlu** modifikasi apapun.

---

## Push Notification Format

Backend harus mengirim push notification dengan format:

```json
{
  "status": "success",
  "type": "KYC",
  "sessionId": "...",
  "userId": "...",
  "submissionId": "..."
}
```

**Kriteria Valid:**
- `status` = "success" (case insensitive)
- `type` = "kyc" (case insensitive)

---

## Contoh Lengkap AppDelegate

```swift
import UIKit
import Flutter
import bjb_cob_sdk  // Import SDK
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Setup Firebase, dll
        FirebaseApp.configure()
        
        // Setup push notification
        UNUserNotificationCenter.current().delegate = self
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Push Notification Handlers
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        willPresent notification: UNNotification,
                                        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Forward ke COB SDK (1 baris)
        CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
        
        // Handle notifikasi lain untuk app Anda di sini
        
        completionHandler([[.alert, .sound, .badge]])
    }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        didReceive response: UNNotificationResponse,
                                        withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Forward ke COB SDK (1 baris)
        CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
        
        // Handle notifikasi lain untuk app Anda di sini
        
        completionHandler()
    }
}
```

---

## FAQ

**Q: Kenapa iOS perlu integrasi tapi Android tidak?**  
A: Ini limitasi platform iOS. Push notification harus diterima AppDelegate host terlebih dahulu. Android bisa handle via BroadcastReceiver di SDK.

**Q: Apakah akan mengganggu push notification lain?**  
A: Tidak. Handler hanya memproses notifikasi dengan `status="success"` dan `type="kyc"`. Notifikasi lain diabaikan.

**Q: Bagaimana jika lupa tambahkan handler?**  
A: Push notification KYC tidak akan terdeteksi di iOS. User harus manual refresh atau tunggu timeout.

**Q: Apakah bisa tanpa modifikasi AppDelegate?**  
A: Tidak untuk iOS. Ini adalah limitasi platform, bukan SDK.

---

## Troubleshooting

### Push notification tidak terdeteksi

1. Pastikan sudah import SDK: `import bjb_cob_sdk`
2. Pastikan sudah panggil handler di kedua method
3. Cek log di Xcode Console untuk pesan dari SDK
4. Pastikan format push notification sesuai

### Build error "Cannot find CobPushNotificationHandler"

Pastikan SDK sudah ter-install dengan benar:
```bash
cd ios
pod install
```

---

## Support

Untuk pertanyaan lebih lanjut, hubungi tim development BJB COB SDK.
