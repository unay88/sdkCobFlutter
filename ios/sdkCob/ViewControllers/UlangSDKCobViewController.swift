import UIKit
import SwiftUI
import DigitalIdentity

public class UlangSDKCobViewController: UIViewController {
    
    private var retryButton: UIButton!
    private var activityIndicator: UIActivityIndicatorView!
    private var processLabel: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        initializeSDK()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.retryKYC()
        }
    }
    
    private func initializeSDK() {
        let userProfile = DigitalIdentityUserProfile(userId: UUID().uuidString)
        let analyticsManager = SDKAnalyticsManager()
        
        let config = DigitalIdentityConfiguration(
            environment: .staging,
            analyticsManager: analyticsManager,
            userProfile: userProfile
        )
        
        DigitalIdentitySdk.shared.initialise(configuration: config) {
            print("✅ UlangSDK: DigitalIdentity SDK initialized")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.85, green: 0.90, blue: 1.0, alpha: 1.0).cgColor,
            UIColor.white.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        let headerImageView = UIImageView()
        headerImageView.image = UIImage(named: "header_cob_account_setting")
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Back button
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        backButton.layer.cornerRadius = 12
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        view.addSubview(headerImageView)
        view.addSubview(backButton)
        view.addSubview(gradientView)
        gradientView.layer.addSublayer(gradientLayer)
        
        activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.color = .blue
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        
        processLabel = UILabel()
        processLabel.text = "Sedang Dalam Proses..."
        processLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        processLabel.textColor = .gray
        processLabel.textAlignment = .center
        processLabel.translatesAutoresizingMaskIntoConstraints = false
        
        retryButton = UIButton(type: .system)
        retryButton.setTitle(" Coba Lagi", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        retryButton.setTitleColor(.systemBlue, for: .normal)
        retryButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        retryButton.tintColor = .systemBlue
        retryButton.backgroundColor = .clear
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        
        gradientView.addSubview(activityIndicator)
        gradientView.addSubview(processLabel)
        gradientView.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 80),
            
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            gradientView.topAnchor.constraint(equalTo: view.topAnchor, constant: 124),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor, constant: -20),
            
            processLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            processLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            
            retryButton.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
            retryButton.widthAnchor.constraint(equalToConstant: 200),
            retryButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        DispatchQueue.main.async {
            gradientLayer.frame = gradientView.bounds
            
            // Add rounded corners to top of gradient view
            let cornerRadius: CGFloat = 25
            let path = UIBezierPath(roundedRect: gradientView.bounds,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            gradientView.layer.mask = maskLayer
        }
    }
    
    private func retryKYC() {
        print("🔄 Retry KYC: Calling reinitiateOnboarding...")
        
        OnboardingAPIService.shared.reinitiateOnboarding { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.succeeded == true {
                        print("✅ Retry KYC: Reinitiate success")
                        self.updateCheckpointReStartKyc()
                    } else {
                        self.showErrorAndGoBack(response.message ?? "Gagal memproses. Silakan coba lagi.")
                    }
                case .failure(let error):
                    print("❌ Retry KYC: Reinitiate failed: \(error)")
                    self.showErrorAndGoBack("Terjadi kesalahan. Silakan coba lagi.")
                }
            }
        }
    }
    
    private func updateCheckpointReStartKyc() {
        OnboardingAPIService.shared.updateCheckpoint(checkpoint: "ReStartKyc") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ Update checkpoint ReStartKyc success: \(String(describing: response.data?.checkpoint))")
                    if let newCheckpoint = response.data?.checkpoint {
                        SessionManager.shared.setCheckpoint(newCheckpoint)
                    }
                    self.launchKYCVerification()
                case .failure(let error):
                    print("❌ Update checkpoint ReStartKyc failed: \(error)")
                    // Tetap launch KYC meskipun update checkpoint gagal
                    self.launchKYCVerification()
                }
            }
        }
    }
    
    private func navigateToReStatusViewController() {
        print("✅ UlangSDK: Navigating to ReStatusViewController")
        let reStatusViewController = ReStatusViewController()
        navigationController?.pushViewController(reStatusViewController, animated: true)
    }
    

    
    private func launchKYCVerification() {
        let token = SessionManager.shared.getToken()
        
        guard let finalToken = token else {
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
        
        do {
            try DigitalIdentitySdk.shared.launchKYCVerification(
                config: kycConfig,
                viewcontroller: self,
                helpCenter: SDKHelpCenterDelegate()
            ) { result in
                DispatchQueue.main.async {
                    if CobSDKManager.shared.isSDKCompleted {
                        return
                    }
                    self.handleKYCResult(result)
                }
            }
        } catch {
            showErrorAndGoBack("Gagal membuka verifikasi KYC. Silakan coba lagi.")
        }
    }
    
    private func handleKYCResult(_ result: Any) {
        let resultString = String(describing: result)
        
        if resultString.lowercased().contains("cancel") || resultString.lowercased().contains("dismiss") {
            // Show retry button when GTF is closed
            showRetryButton()
            return
        }
        
        if resultString.contains("notCompleted") {
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
            print("✅ UlangSDK: KYC Success detected - navigating to ReStatusViewController")
            self.navigateToReStatusViewController()
        } else {
            print("❌ UlangSDK: KYC Failed - result: \(resultString)")
            showErrorAndGoBack("Verifikasi KYC gagal. Silakan coba lagi.")
        }
    }
    
    private func showErrorAndGoBack(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Tetap di halaman ini dan tampilkan retry button
            self.showRetryButton()
        })
        present(alert, animated: true)
    }
    
    private func showRetryButton() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        processLabel.isHidden = true
        retryButton.isHidden = false
    }
    
    private func hideRetryButton() {
        retryButton.isHidden = true
        activityIndicator.isHidden = false
        processLabel.isHidden = false
        activityIndicator.startAnimating()
    }
    
    @objc private func retryButtonTapped() {
        hideRetryButton()
        retryKYC()
    }
    
    @objc private func backButtonTapped() {
        print("🔙 UlangSDK: Back button tapped - restarting KYC")
        retryKYC()
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

private class SDKAnalyticsManager: IDigitalIdentityAnalyticsManager {
    func trackEvent(name: String, properties: [String : Any]?) {
        print("📊 UlangSDK Analytics: \(name)")
    }
}

private class SDKHelpCenterDelegate: DigitalIdentityHelpCenterDelegate {
    func isHelpCTAEnabled(for type: DigitalIdentityHelpCenterType) -> Bool {
        return true
    }
    
    func onHelpCTAClicked(in viewController: UIViewController, type: DigitalIdentityHelpCenterType) {
        print("ℹ️ UlangSDK Help center clicked")
    }
}
