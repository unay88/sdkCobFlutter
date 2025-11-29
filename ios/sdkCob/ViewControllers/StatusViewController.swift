import SwiftUI

@available(iOS 14.0, *)
public struct StatusView: View {
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var retryCount = 0
    @State private var pushNotificationReceived = false
    @State private var hasNavigatedToWebView = false
    @State private var timeoutTimer: Timer?
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 10
    private let pushNotificationTimeout: TimeInterval = 360
    public let onBackPressed: (() -> Void)?
    
    public init(onBackPressed: (() -> Void)? = nil) {
        self.onBackPressed = onBackPressed
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.92, green: 0.95, blue: 1.0),
                    Color.white
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea(.container, edges: .horizontal)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Loading GIF/Animation
                SDKImage("icon_intro2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
                
                // Status Text
                Text("Sedang Dalam Proses...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            

        }
        .onAppear {
            print("📱 StatusView: onAppear - StatusView is now active and listening for notifications")
            print("📱 StatusView: Initial state - hasNavigatedToWebView=\(hasNavigatedToWebView), pushNotificationReceived=\(pushNotificationReceived)")
            startPushNotificationMonitoring()
            callLongPooling()
        }
        .onDisappear {
            print("📱 StatusView disappeared - cleaning up")
            timeoutTimer?.invalidate()
            hasNavigatedToWebView = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StatusCobPushNotification"))) { notification in
            print("🔔 StatusView: onReceive triggered for StatusCobPushNotification")
            print("🔔 StatusView: hasNavigatedToWebView=\(hasNavigatedToWebView), pushNotificationReceived=\(pushNotificationReceived)")
            handlePushNotificationReceived(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StatusKycPushNotification"))) { notification in
            print("🔔 StatusView: onReceive triggered for StatusKycPushNotification")
            print("🔔 StatusView: hasNavigatedToWebView=\(hasNavigatedToWebView), pushNotificationReceived=\(pushNotificationReceived)")
            handlePushNotificationReceived(notification)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Verifikasi Gagal"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    self.handleAlertDismiss()
                }
            )
        }
    }
    
    private func startPushNotificationMonitoring() {
        print("📱 Starting push notification monitoring with 30s timeout")
        
        // Start timeout timer
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: pushNotificationTimeout, repeats: false) { _ in
            if !pushNotificationReceived {
                print("⏰ Push notification timeout - calling checkSubmission API")
                // checkSubmissionStatus()
            }
        }
    }
    
    private func callLongPooling() {
        OnboardingAPIService.shared.longPooling { result in
            DispatchQueue.main.async {
                guard !self.hasNavigatedToWebView else {
                    print("⚠️ Already navigated to WebView, ignoring long polling result")
                    return
                }
                
                switch result {
                case .success(let response):
                    print("✅ Long pooling success: \(response)")
                    self.hasNavigatedToWebView = true
                    self.navigateToWebView()
                case .failure(let error):
                    print("❌ Long pooling failed: \(error)")
                    // Show alert and return to host app when long pooling fails
                    self.isLoading = false
                    self.alertMessage = "Koneksi terputus. Silakan coba lagi."
                    self.showAlert = true
                }
            }
        }
    }
    
    private func handlePushNotificationReceived(_ notification: Notification) {
        print("🔔 StatusView: handlePushNotificationReceived called")
        print("🔔 StatusView: Notification name: \(notification.name.rawValue)")
        
        guard !pushNotificationReceived else {
            print("⚠️ Push notification already received, ignoring")
            return
        }
        guard !hasNavigatedToWebView else {
            print("⚠️ Already navigated to WebView, ignoring push notification")
            return
        }
        
        pushNotificationReceived = true
        timeoutTimer?.invalidate()
        
        print("📱 Push notification received - checking status and type")
        
        guard let userInfo = notification.userInfo else {
            print("⚠️ No userInfo in notification")
            // checkSubmissionStatus()
            return
        }
        
        print("🔍 DEBUG - Full userInfo: \(userInfo)")
        
        // Get originalUserInfo if exists (from AppDelegate)
        let actualUserInfo: [AnyHashable: Any]
        if let original = userInfo["originalUserInfo"] as? [AnyHashable: Any] {
            print("🔍 DEBUG - Using originalUserInfo")
            actualUserInfo = original
        } else {
            print("🔍 DEBUG - Using direct userInfo")
            actualUserInfo = userInfo
        }
        
        print("🔍 DEBUG - actualUserInfo: \(actualUserInfo)")
        
        // Check status = "success"
        let status = actualUserInfo["status"] as? String ?? ""
        let statusValid = status.lowercased() == "success"
        
        // Check type = "kyc"
        let type = actualUserInfo["type"] as? String ?? ""
        let typeValid = type.lowercased() == "kyc"
        
        print("📍 Status: '\(status)' -> \(statusValid ? "✅ success" : "❌ not success")")
        print("📍 Type: '\(type)' -> \(typeValid ? "✅ kyc" : "❌ not kyc")")
        
        // Handle KYC notification based on status
        if typeValid {
            if statusValid {
                print("✅ KYC success - redirecting to WebView")
                hasNavigatedToWebView = true
                updateCheckpointFinishKyc()
            } else {
                print("❌ KYC failed - showing alert and returning to host app")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "Verifikasi data diri Anda belum sesuai. Pastikan dokumen KTP dan proses perekaman wajah Anda valid."
                    self.showAlert = true
                }
            }
        } else {
            print("⚠️ Push notification invalid (type: \(typeValid)) - calling checkSubmission API")
            // checkSubmissionStatus()
        }
    }
    
    private func checkSubmissionStatus() {
        DispatchQueue.global(qos: .userInitiated).async {
            OnboardingAPIService.shared.checkSubmission { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if self.isVerificationPassed(response) {
                            self.updateCheckpointFinishKyc()
                        } else {
                            self.handleVerificationFailed()
                        }
                    case .failure(let error):
                        print("❌ Check submission failed: \(error)")
                        self.handleVerificationFailed()
                    }
                }
            }
        }
    }
    
    private func handleVerificationFailed() {
        retryCount += 1
        print("⚠️ Verification failed. Retry attempt \(retryCount)/\(maxRetries)")
        
        if retryCount < maxRetries {
            print("🔄 Retrying in \(Int(retryDelay)) seconds...")
            // DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
            //     self.checkSubmissionStatus()
            // }
        } else {
            print("❌ Max retries reached. Showing error alert.")
            self.isLoading = false
            self.alertMessage = "Verifikasi data diri Anda belum sesuai. Pastikan dokumen KTP dan proses perekaman wajah Anda valid."
            self.showAlert = true
        }
    }
    
    private func handleAlertDismiss() {
        timeoutTimer?.invalidate()
        self.closeSDK()
    }
    
    private func isVerificationPassed(_ response: CheckSubmissionResponse) -> Bool {
        guard let verificationResult = response.data?.verificationResult else {
            print("⚠️ No verification result found")
            return false
        }
        
        let nikPass = verificationResult.nik?.uppercased() == "PASS"
        let namePass = verificationResult.name?.uppercased() == "PASS"
        let dobPass = verificationResult.dateOfBirth?.uppercased() == "PASS"
        let selfiePass = verificationResult.selfie?.uppercased() == "PASS"
        
        let allPassed = nikPass && namePass && dobPass && selfiePass
        
        print("🔍 Verification Result:")
        print("  - NIK: \(verificationResult.nik ?? "N/A") -> \(nikPass ? "✅" : "❌")")
        print("  - Name: \(verificationResult.name ?? "N/A") -> \(namePass ? "✅" : "❌")")
        print("  - DOB: \(verificationResult.dateOfBirth ?? "N/A") -> \(dobPass ? "✅" : "❌")")
        print("  - Selfie: \(verificationResult.selfie ?? "N/A") -> \(selfiePass ? "✅" : "❌")")
        print("  - All Passed: \(allPassed ? "✅" : "❌")")
        
        return allPassed
    }
    
    private func updateCheckpointFinishKyc() {
        timeoutTimer?.invalidate()
        
        OnboardingAPIService.shared.updateCheckpoint(checkpoint: "FinishKyc") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ Update checkpoint FinishKyc success: \(String(describing: response.data?.checkpoint))")
                    if let newCheckpoint = response.data?.checkpoint {
                        SessionManager.shared.setCheckpoint(newCheckpoint)
                    }
                    self.navigateToWebView()
                case .failure(let error):
                    print("❌ Update checkpoint FinishKyc failed: \(error)")
                    // Tetap navigate meskipun update checkpoint gagal
                    self.navigateToWebView()
                }
            }
        }
    }
    
    private func navigateToWebView() {
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToWebView"), object: nil)
    }
    
    private func navigateToRetryKYC() {
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToRetryKYC"), object: nil)
    }
    
    private func closeSDK() {
        CobSDKManager.shared.notifyError(message: "Verifikasi KYC gagal")
    }
}

public class StatusViewController: UIViewController {
    public var onBackPressed: (() -> Void)?
    private var hasNavigated = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSDKDismissal),
            name: NSNotification.Name("CobSDKDismiss"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigateToWebView),
            name: NSNotification.Name("NavigateToWebView"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigateToRetryKYC),
            name: NSNotification.Name("NavigateToRetryKYC"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigateBackToEmailVerification),
            name: NSNotification.Name("NavigateBackToEmailVerification"),
            object: nil
        )
        
        
        if #available(iOS 14.0, *) {
            let hostingController = UIHostingController(rootView: StatusView(onBackPressed: onBackPressed))
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            hostingController.didMove(toParent: self)
        }
    }
    
    @objc private func handleSDKDismissal() {
        // Handled by CobSDKManager
    }
    
    @objc private func handleNavigateToWebView() {
        guard !hasNavigated else {
            print("⚠️ StatusViewController: Already navigated, ignoring")
            return
        }
        hasNavigated = true
        print("✅ StatusViewController: Navigating to WebView")
        let webViewController = WebViewController()
        navigationController?.pushViewController(webViewController, animated: true)
    }
    
    @objc private func handleNavigateToRetryKYC() {
        let ulangVC = UlangSDKCobViewController()
        navigationController?.pushViewController(ulangVC, animated: true)
    }
    
    @objc private func handleNavigateBackToEmailVerification() {
        // Pop back to EmailVerificationViewController
        navigationController?.popToRootViewController(animated: true)
    }
    

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
}

// Custom shape for top-only rounded corners
@available(iOS 13.0, *)
struct StatusTopRoundedRectangle: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: radius))
        path.addArc(center: CGPoint(x: radius, y: radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        path.addArc(center: CGPoint(x: rect.width - radius, y: radius), radius: radius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}