import UIKit
import SwiftUI

public class CobSDK {
    public static let shared = CobSDK()
    
    private init() {}
    
    public func startEmailVerification(
        phoneNumber: String,
        email: String,
        clientPlatform: String? = nil,
        from presentingViewController: UIViewController,
        completion: @escaping (CobSDKResult) -> Void
    ) {
        // Reset SDK state
        CobSDKManager.shared.isSDKCompleted = false
        CobSDKManager.shared.completion = completion
        
        // Store clientPlatform in manager for API calls
        CobSDKManager.shared.clientPlatform = clientPlatform
        
        // Create first screen
        let emailVC = EmailVerificationViewController()
        emailVC.email = email
        emailVC.phoneNumber = phoneNumber
        
        // Wrap in navigation controller (SDK container)
        let navController = UINavigationController(rootViewController: emailVC)
        navController.isNavigationBarHidden = true
        navController.modalPresentationStyle = .fullScreen
        
        // Store navigation controller reference
        CobSDKManager.shared.sdkNavigationController = navController
        
        // Present SDK container once
        presentingViewController.present(navController, animated: true)
    }
}

public enum CobSDKResult {
    case success(data: [String: Any]?)
    case cancelled
    case error(message: String)
}

public class CobSDKManager {
    public static let shared = CobSDKManager()
    public var completion: ((CobSDKResult) -> Void)?
    public var sdkNavigationController: UINavigationController?  // Changed from weak to strong
    public var isSDKCompleted: Bool = false
    public var clientPlatform: String?
    
    private init() {}
    
    public func notifySuccess(data: [String: Any]? = nil) {
        guard !isSDKCompleted else {
            print("⚠️ SDK already completed, ignoring duplicate call")
            return
        }
        isSDKCompleted = true
        
        print("✅ CobSDKManager: notifySuccess called")
        print("✅ CobSDKManager: Data: \(data ?? [:])")
        
        // Ensure data is properly typed for Flutter
        let responseData: [String: Any]?
        if let data = data {
            responseData = data
        } else {
            responseData = ["status": "success"]
        }
        
        print("✅ CobSDKManager: Calling completion with success")
        completion?(.success(data: responseData))
        completion = nil
        
        dismissSDK()
    }
    
    public func notifyCancel() {
        dismissSDK()
        completion?(.cancelled)
        completion = nil
    }
    
    public func notifyError(message: String) {
        dismissSDK()
        completion?(.error(message: message))
        completion = nil
    }
    
    private func dismissSDK() {
        DispatchQueue.main.async { [weak self] in
            guard let navController = self?.sdkNavigationController else {
                print("⚠️ Navigation controller is nil")
                return
            }
            print("✅ Dismissing SDK container")
            navController.dismiss(animated: true)
            self?.sdkNavigationController = nil
        }
    }
}