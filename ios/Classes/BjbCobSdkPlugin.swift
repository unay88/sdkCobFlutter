import Flutter
import UIKit

public class BjbCobSdkPlugin: NSObject, FlutterPlugin {
  private var pendingResult: FlutterResult?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "bjb_cob_sdk", binaryMessenger: registrar.messenger())
    let instance = BjbCobSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startEmailVerification":
      handleStartEmailVerification(call, result: result)
    case "launchKYC":
      handleLaunchKYC(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func handleStartEmailVerification(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let phoneNumber = args["phoneNumber"] as? String,
          let email = args["email"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing phoneNumber or email", details: nil))
      return
    }
    
    let clientPlatform = args["clientPlatform"] as? String
    
    pendingResult = result
    
    DispatchQueue.main.async {
      guard let rootViewController = self.getRootViewController() else {
        result(FlutterError(code: "NO_ACTIVITY", message: "Cannot find root view controller", details: nil))
        return
      }
      
      // Use CobSDK.shared.startEmailVerification for proper navigation handling
      CobSDK.shared.startEmailVerification(
        phoneNumber: phoneNumber,
        email: email,
        clientPlatform: clientPlatform,
        from: rootViewController
      ) { sdkResult in
        DispatchQueue.main.async {
          switch sdkResult {
          case .success(let data):
            // Ensure data is properly typed as [String: Any]
            let responseData: [String: Any]
            if let dataDict = data as? [String: Any] {
              responseData = dataDict
            } else {
              responseData = ["message": "COB completed successfully"]
            }
            
            // Return success format that Flutter SdkCobResult.fromMap expects
            result([
              "status": "success",
              "data": responseData,
              "errorMessage": nil
            ] as [String: Any])
          case .cancelled:
            result([
              "status": "cancelled",
              "data": ["message": "User cancelled"],
              "errorMessage": nil
            ] as [String: Any])
          case .error(let message):
            result([
              "status": "error",
              "data": ["message": message],
              "errorMessage": message
            ] as [String: Any])
          }
          self.pendingResult = nil
        }
      }
    }
  }
  
  private func handleLaunchKYC(result: @escaping FlutterResult) {
    pendingResult = result
    
    DispatchQueue.main.async {
      guard let rootViewController = self.getRootViewController() else {
        result(FlutterError(code: "NO_ACTIVITY", message: "Cannot find root view controller", details: nil))
        return
      }
      
      let webVC = WebViewController()
      webVC.modalPresentationStyle = .fullScreen
      rootViewController.present(webVC, animated: true)
      
      result([
        "status": "success",
        "data": ["message": "KYC launched"]
      ] as [String: Any])
      self.pendingResult = nil
    }
  }
  

  
  private func getRootViewController() -> UIViewController? {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first(where: { $0.isKeyWindow }),
       let rootViewController = window.rootViewController {
      return rootViewController
    }
    return nil
  }
}