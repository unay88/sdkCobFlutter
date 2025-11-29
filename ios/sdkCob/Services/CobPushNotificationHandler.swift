import Foundation
import UserNotifications

/// Handler untuk push notification COB SDK
/// Memungkinkan SDK menangani push notification dengan integrasi minimal di AppDelegate host
///
/// CARA PENGGUNAAN DI APPDELEGATE HOST:
/// Cukup tambahkan 1 baris di method push notification:
///
/// ```swift
/// import bjb_cob_sdk
///
/// override func userNotificationCenter(_ center: UNUserNotificationCenter,
///                                     willPresent notification: UNNotification,
///                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
///     let userInfo = notification.request.content.userInfo
///     
///     // Tambahkan 1 baris ini:
///     CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
///     
///     completionHandler([[.alert, .sound, .badge]])
/// }
///
/// override func userNotificationCenter(_ center: UNUserNotificationCenter,
///                                     didReceive response: UNNotificationResponse,
///                                     withCompletionHandler completionHandler: @escaping () -> Void) {
///     let userInfo = response.notification.request.content.userInfo
///     
///     // Tambahkan 1 baris ini:
///     CobPushNotificationHandler.shared.handleNotification(userInfo: userInfo)
///     
///     completionHandler()
/// }
/// ```
public class CobPushNotificationHandler: NSObject {
    
    public static let shared = CobPushNotificationHandler()
    
    private override init() {
        super.init()
    }
    
    /// Handle push notification dari AppDelegate host
    /// Method ini akan otomatis mendeteksi apakah notifikasi untuk COB SDK
    /// dan meneruskannya ke SDK jika valid
    ///
    /// - Parameter userInfo: UserInfo dari push notification
    @objc public func handleNotification(userInfo: [AnyHashable: Any]) {
        print("📱 CobSDK: Checking push notification")
        print("📱 CobSDK: Full userInfo received: \(userInfo)")
        
        // Check type = "kyc" or "cob"
        let status = userInfo["status"] as? String ?? ""
        let type = userInfo["type"] as? String ?? ""
        
        // Also check title for KYC notifications
        let title = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
        let titleText = title?["title"] as? String ?? ""
        
        print("📱 CobSDK: Extracted - status='\(status)', type='\(type)', title='\(titleText)'")
        
        let typeKyc = type.lowercased() == "kyc"
        let typeCob = type.lowercased() == "cob"
        let titleKyc = titleText.lowercased().contains("kyc")
        
        print("📱 CobSDK: Type validation - typeKyc=\(typeKyc), typeCob=\(typeCob), titleKyc=\(titleKyc)")
        
        // Process if type is "kyc" or "cob" OR title contains "kyc"
        guard typeKyc || typeCob || titleKyc else {
            print("⚠️ CobSDK: Not a COB SDK notification (type='\(type)', title='\(titleText)'), ignoring")
            return
        }
        
        print("✅ CobSDK: COB/KYC notification detected")
        print("📱 CobSDK: status='\(status)', type='\(type)', title='\(titleText)'")
        print("📱 CobSDK: Full userInfo: \(userInfo)")
        
        // Forward to SDK via NotificationCenter
        // SDK will handle validation (success/failed) internally
        
        print("📤 CobSDK: Posting StatusCobPushNotification...")
        // Post to StatusCobPushNotification (for COB type)
        NotificationCenter.default.post(
            name: NSNotification.Name("StatusCobPushNotification"),
            object: nil,
            userInfo: ["originalUserInfo": userInfo]
        )
        print("✅ CobSDK: StatusCobPushNotification posted")
        
        print("📤 CobSDK: Posting StatusKycPushNotification...")
        // Also post to StatusKycPushNotification (for KYC type)
        // This ensures both listeners receive the notification
        NotificationCenter.default.post(
            name: NSNotification.Name("StatusKycPushNotification"),
            object: nil,
            userInfo: ["originalUserInfo": userInfo]
        )
        print("✅ CobSDK: StatusKycPushNotification posted")
        
        print("📤 CobSDK: Both notifications forwarded to SDK - StatusView should receive them if active")
        
        // Force immediate processing if KYC success
        if status.lowercased() == "success" && (typeKyc || titleKyc) {
            DispatchQueue.main.async {
                print("🔥 CobSDK: Force triggering ReFinishKyc update")
                self.forceUpdateReFinishKyc()
            }
        }
    }
    
    /// Force update ReFinishKyc checkpoint immediately
    private func forceUpdateReFinishKyc() {
        print("🔥 CobSDK: Force updating ReFinishKyc checkpoint")
        
        OnboardingAPIService.shared.updateCheckpoint(checkpoint: "ReFinishKyc") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ CobSDK: Force update ReFinishKyc SUCCESS")
                    if let newCheckpoint = response.data?.checkpoint {
                        SessionManager.shared.setCheckpoint(newCheckpoint)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToWebView"), object: nil)
                case .failure(let error):
                    print("❌ CobSDK: Force update ReFinishKyc FAILED: \(error)")
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToWebView"), object: nil)
                }
            }
        }
    }
}
