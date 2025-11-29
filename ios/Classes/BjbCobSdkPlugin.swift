import Flutter
import UIKit
import sdkCob

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
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let rootViewController = self.getRootViewController() else {
        result(FlutterError(code: "NO_ACTIVITY", message: "Cannot find root view controller", details: nil))
        return
      }
      
      // Use CobSDK.shared.startEmailVerification for proper navigation handling
      CobSDK.shared.startEmailVerification(
        phoneNumber: phoneNumber,
        email: email,
        from: rootViewController
      ) { sdkResult in
        DispatchQueue.main.async {
          switch sdkResult {
          case .success:
            result([
              "status": "success"
            ])
          case .cancelled:
            result([
              "status": "cancelled"
            ])
          case .error(let message):
            result([
              "status": "error",
              "errorMessage": message
            ])
          }
          self.pendingResult = nil
        }
      }
    }
  }
  
  private func handleLaunchKYC(result: @escaping FlutterResult) {
    pendingResult = result
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let rootViewController = self.getRootViewController() else {
        result(FlutterError(code: "NO_ACTIVITY", message: "Cannot find root view controller", details: nil))
        return
      }
      
      let webVC = WebViewController()
      webVC.modalPresentationStyle = .fullScreen
      rootViewController.present(webVC, animated: true)
      
      result([
        "status": "success",
        "data": ["message": "KYC launched"]
      ])
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