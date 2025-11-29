//
//  sdkCob.swift
//  sdkCob
//
//  Created by Indra Permana on 01/10/25.
//

import UIKit
import SwiftUI
import DigitalIdentity

public class SDKCobViewController: UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        initializeSDK()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient layer frame and apply rounded corners
        if let gradientView = view.subviews.last(where: { $0.backgroundColor == .clear }),
           let gradientLayer = gradientView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = gradientView.bounds
            
            // Apply rounded corners to top only
            let path = UIBezierPath(roundedRect: gradientView.bounds,
                                  byRoundingCorners: [.topLeft, .topRight],
                                  cornerRadii: CGSize(width: 25, height: 25))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            gradientView.layer.mask = mask
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Automatically launch KYC GTF when view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showGTFVerification()
        }
    }
    
    private func initializeSDK() {
        print("🔧 SDK COB: Initializing DigitalIdentity SDK...")
        
        let userProfile = DigitalIdentityUserProfile(userId: UUID().uuidString)
        let analyticsManager = SDKAnalyticsManager()
        
        let config = DigitalIdentityConfiguration(
            environment: .staging,
            analyticsManager: analyticsManager,
            userProfile: userProfile
        )
        
        DigitalIdentitySdk.shared.initialise(configuration: config) {
            print("✅ SDK COB: DigitalIdentity SDK initialized successfully")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Header with image
        let headerImageView = UIImageView()
        let bundle = Bundle(for: type(of: self))
        if let bundlePath = bundle.path(forResource: "bjb_cob_sdk_assets", ofType: "bundle"),
           let resourceBundle = Bundle(path: bundlePath),
           let image = UIImage(named: "header_cob_account_setting", in: resourceBundle, compatibleWith: nil) {
            headerImageView.image = image
        }
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create gradient background view with rounded corners
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.backgroundColor = .clear
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.85, green: 0.90, blue: 1.0, alpha: 1.0).cgColor,  // Very light blue at bottom
            UIColor.white.cgColor                                            // White at top
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)  // bottom
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)    // top
        
        view.addSubview(headerImageView)
        view.addSubview(gradientView)
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Loading spinner
        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.color = .blue
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        
        // Process text
        let processLabel = UILabel()
        processLabel.text = "Sedang Dalam Proses..."
        processLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        processLabel.textColor = .gray
        processLabel.textAlignment = .center
        processLabel.translatesAutoresizingMaskIntoConstraints = false
        
        gradientView.addSubview(activityIndicator)
        gradientView.addSubview(processLabel)
        
        NSLayoutConstraint.activate([
            // Header image constraints - start from safe area top
            headerImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Gradient view constraints - start 66pt from top (overlapping header by 14pt)
            gradientView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Activity indicator constraints
            activityIndicator.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor, constant: -20),
            
            // Process label constraints
            processLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            processLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20)
        ])
        
        // Update gradient frame when view layout changes
        DispatchQueue.main.async {
            gradientLayer.frame = gradientView.bounds
        }
    }
    
    @objc private func showGTFVerification() {
        print("🔥 SDK COB: Starting GTF Verification")
        
        // Log SDK version
        if let sdkVersion = Bundle(for: DigitalIdentitySdk.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            print("📦 DigitalIdentity SDK Version: \(sdkVersion)")
        } else {
            print("⚠️ DigitalIdentity SDK Version: Unknown")
        }
        
        launchKYCVerification()
    }
    
    private func launchKYCVerification() {
        // Get token from session, if not available use hardcoded token
        let token = SessionManager.shared.getToken()
        
        guard let finalToken = token else {
            print("❌ No token available")
            showErrorAndGoBack("Token tidak tersedia. Silakan coba lagi.")
            return
        }
        
        let correlationId = SessionManager.shared.getSessionId() ?? UUID().uuidString
        
        let kycConfig = DigitalIdentityKYCVerificationConfig(
            baseUrl: SDKConfiguration.getKYCBaseUrl(),
            token: finalToken,
            correlationId: correlationId,
            language: .indonesia,
            theme: BJBThemeHelper.createCustomTheme()
        )
        
        print("🚀 SDK COB: Launching KYC verification with token: \(finalToken.prefix(20))...")
        print("🚀 SDK COB: Launching KYC verification with correlationId: \(correlationId)")
        do {
            try DigitalIdentitySdk.shared.launchKYCVerification(
                config: kycConfig,
                viewcontroller: self,
                helpCenter: SDKHelpCenterDelegate()
            ) { result in
                print("✅ SDK COB: KYC Result: \(result)")
                DispatchQueue.main.async {
                    if CobSDKManager.shared.isSDKCompleted {
                        print("⚠️ SDK already completed, ignoring KYC result")
                        return
                    }
                    
                    self.handleKYCResult(result)
                }
            }
        } catch {
            print("❌ Failed to launch KYC: \(error)")
            showErrorAndGoBack("Gagal membuka verifikasi KYC. Silakan coba lagi.")
        }
    }
    
    private func handleKYCResult(_ result: Any) {
        print("🔍 SDK COB: Analyzing KYC Result: \(result)")
        
        let resultString = String(describing: result)
        
        if resultString.lowercased().contains("cancel") || resultString.lowercased().contains("dismiss") {
            print("🚫 User cancelled KYC")
            navigateBackToTerms()
            return
        }
        
        if resultString.contains("notCompleted") {
            print("❌ KYC not completed")
            
            var errorMessage = "Verifikasi KYC gagal. Silakan coba lagi."
            if resultString.contains("errorMessage:") {
                let parts = resultString.components(separatedBy: "errorMessage: Optional(")
                if parts.count > 1 {
                    let msgParts = parts[1].components(separatedBy: ")")
                    if !msgParts.isEmpty {
                        let msg = msgParts[0].replacingOccurrences(of: "\"", with: "")
                        if !msg.isEmpty {
                            errorMessage = msg
                        }
                    }
                }
            }
            
            showErrorAndGoBack(errorMessage)
            return
        }
        
        if resultString.lowercased().contains("success") || resultString.lowercased().contains("completed") {
            print("✅ KYC completed successfully")
            navigateToStatus()
        } else {
            print("❌ KYC failed with unknown status")
            showErrorAndGoBack("Verifikasi KYC gagal. Silakan coba lagi.")
        }
    }
    
    private func navigateToStatus() {
        let statusViewController = StatusViewController()
        navigationController?.pushViewController(statusViewController, animated: true)
    }
    
    private func navigateBackToTerms() {
        navigationController?.popViewController(animated: true)
    }
    
    private func completeSDKFlow() {
        CobSDKManager.shared.notifySuccess(data: [
            "status": "kyc_completed",
            "message": "KYC verification completed successfully"
        ])
    }
    
    private func showErrorAndGoBack(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
}

// MARK: - Supporting Classes
private class SDKAnalyticsManager: IDigitalIdentityAnalyticsManager {
    func trackEvent(name: String, properties: [String : Any]?) {
        print("📊 SDK COB Analytics: \(name), Properties: \(properties ?? [:])")
    }
}

private class SDKHelpCenterDelegate: DigitalIdentityHelpCenterDelegate {
    func isHelpCTAEnabled(for type: DigitalIdentityHelpCenterType) -> Bool {
        print("ℹ️ SDK COB Help center enabled for type: \(type)")
        return true
    }
    
    func onHelpCTAClicked(in viewController: UIViewController, type: DigitalIdentityHelpCenterType) {
        print("ℹ️ SDK COB Help center clicked for type: \(type)")
    }
}

