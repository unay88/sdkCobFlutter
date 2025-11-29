# Push Notification Integration Guide

## iOS Integration

### Kenapa Perlu Integrasi di AppDelegate?

Berbeda dengan Android yang bisa handle push notification secara otomatis di SDK, iOS memiliki keterbatasan arsitektur:
- Push notification **harus** diterima oleh AppDelegate host terlebih dahulu
- SDK tidak bisa "intercept" push notification secara otomatis
- Ini adalah limitasi platform iOS, bukan limitasi SDK

### Integrasi Minimal (Hanya 1 Baris)

Tambahkan **1 baris kode** di AppDelegate host app:

```swift
import UIKit
import Flutter
import bjb_cob_sdk  // Import SDK

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        willPresent notification: UNNotification,
                                        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // ✅ Tambahkan 1 baris ini untuk COB SDK:
        CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
        
        // Handle notifikasi lain untuk app Anda
        completionHandler([[.alert, .sound, .badge]])
    }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        didReceive response: UNNotificationResponse,
                                        withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // ✅ Tambahkan 1 baris ini untuk COB SDK:
        CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
        
        // Handle notifikasi lain untuk app Anda
        completionHandler()
    }
}
```

### Cara Kerja

1. **Otomatis Deteksi**: Handler akan otomatis mendeteksi apakah notifikasi untuk COB SDK
2. **Tidak Mengganggu**: Jika bukan notifikasi COB SDK, handler akan ignore secara silent
3. **Zero Configuration**: Tidak perlu konfigurasi tambahan, cukup panggil 1 method

### Format Push Notification

SDK akan mendeteksi push notification dengan format:

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

Jika kedua kondisi terpenuhi, SDK akan otomatis memproses notifikasi.

---

## Android Integration

### Tidak Perlu Integrasi

Android SDK sudah handle push notification secara otomatis. **Tidak perlu** modifikasi di host app.

---

## Perbandingan

| Platform | Perlu Modifikasi Host? | Jumlah Kode |
|----------|------------------------|-------------|
| Android  | ❌ Tidak               | 0 baris     |
| iOS      | ✅ Ya                  | 1 baris     |

---

## Troubleshooting

### Push notification tidak terdeteksi di iOS

1. **Pastikan sudah import SDK:**
   ```swift
   import bjb_cob_sdk
   ```

2. **Pastikan sudah panggil handler:**
   ```swift
   CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
   ```

3. **Cek log di Xcode Console:**
   - Harus ada log: `✅ CobSDK: Valid KYC notification detected`
   - Jika tidak ada, cek format push notification

### Push notification format tidak sesuai

Pastikan backend mengirim push notification dengan format:
```json
{
  "status": "success",
  "type": "KYC"
}
```

**Case insensitive**, jadi `"SUCCESS"`, `"Success"`, atau `"success"` semuanya valid.

---

## FAQ

**Q: Apakah bisa tanpa modifikasi AppDelegate sama sekali?**  
A: Tidak untuk iOS. Ini adalah limitasi platform iOS, bukan SDK.

**Q: Kenapa Android tidak perlu tapi iOS perlu?**  
A: Android memiliki BroadcastReceiver yang bisa di-register oleh SDK. iOS tidak memiliki mekanisme serupa.

**Q: Apakah akan mengganggu push notification lain di app?**  
A: Tidak. Handler hanya memproses notifikasi dengan `status="success"` dan `type="kyc"`. Notifikasi lain akan diabaikan.

**Q: Bagaimana jika app menggunakan multiple SDK yang butuh push notification?**  
A: Tidak masalah. Panggil handler masing-masing SDK:
```swift
CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
OtherSDKHandler.shared.handleNotification(userInfo: userInfo)
```

---

## Support

Jika ada pertanyaan atau masalah, silakan hubungi tim development COB SDK.
