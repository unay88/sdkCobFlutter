import SwiftUI
import UIKit
import Combine

@available(iOS 15.0, *)
public struct EmailVerificationView: View {
    @State private var codeInputs = ["", "", "", ""]
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var timer = "00:00"
    @State private var timerSeconds = 0
    @State private var timerActive = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @FocusState private var focusedField: Int?
    let onBackPressed: (() -> Void)?
    let onWelcomeNavigation: (() -> Void)?
    
    public init(email: String = "", phoneNumber: String = "", onBackPressed: (() -> Void)? = nil, onWelcomeNavigation: (() -> Void)? = nil) {
        self.onBackPressed = onBackPressed
        self.onWelcomeNavigation = onWelcomeNavigation
        self._email = State(initialValue: email)
        self._phoneNumber = State(initialValue: phoneNumber)
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with image
                ZStack {
                    SDKImage("header_cob_account_setting")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipped()
                    
                    HStack {
                        Button(action: { dismissSDK() }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                        Spacer()
                        Text("Email Verification")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -10)
                }
                
                Spacer()
            }
            
            // Content with rounded top corners - overlapping header
            ScrollView {
                VStack(spacing: 0) {
                Text("Kami telah mengirimkan kode verifikasi ke alamat Email berikut :")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                    .multilineTextAlignment(.center)
                    .padding(.top, 180)
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(email)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                    .padding(.top, 8)
                
                Button("Ganti Email") { changeEmail() }
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                
                Text("Masukkan Kode Verifikasi Email :")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                    .padding(.top, 60)
                
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        TextField("", text: $codeInputs[index])
                            .frame(width: 70, height: 70)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.black)
                            .background(Color(red: 0xD8/255.0, green: 0xF2/255.0, blue: 0xFF/255.0))
                            .cornerRadius(8)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: index)
                            .onChange(of: codeInputs[index]) { newValue in
                                handleInputChange(index: index, newValue: newValue)
                            }

                    }
                }
                .padding(.top, 20)
                .onAppear {
                    focusedField = 0
                    startInitialTimer()
                    callStartOnboarding()
                }
                
                if timerSeconds > 0 {
                    Text(timer)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                        .padding(.top, 40)
                } else {
                    Text("Waktu OTP telah habis. Silakan kirim ulang kode OTP")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 40)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                }
                
                // Timer receiver - placed separately to ensure continuous updates
                Text("")
                    .frame(width: 0, height: 0)
                    .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                        updateTimer()
                    }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                }
                
                Button("Kirim Ulang") { resendCode() }
                    .font(.system(size: 14))
                    .foregroundColor(timerSeconds <= 0 ? .blue : .gray)
                    .disabled(timerSeconds > 0)
                    .padding(.top, 8)
                
                Spacer()
                
                // Invisible button to dismiss keyboard
                Button("") {
                    focusedField = nil
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.clear)
                .opacity(0.01)
                
                Button(action: { validateAndProceed() }) {
                    Text("Lanjutkan")
                        .font(.custom("Quicksand-Bold", size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 11)
                }
                .background(Color(red: 0xff/255.0, green: 0xc9/255.0, blue: 0x45/255.0))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.92, green: 0.95, blue: 1.0),
                        Color.white
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .clipShape(EmailTopRoundedRectangle(radius: 25))
            .padding(.top, 66)
            
            if isLoading {
                LoadingOverlay(message: "Memuat...")
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Selesai") {
                    focusedField = nil
                }
            }
        }
    }
    
    private func changeEmail() {
        dismissSDK()
    }
    
    private func dismissSDK() {
        CobSDKManager.shared.notifyCancel()
        NotificationCenter.default.post(name: NSNotification.Name("CobSDKDismiss"), object: nil)
    }
    
    private func startInitialTimer() {
        timerSeconds = 180
        timerActive = true
        updateTimerDisplay()
        errorMessage = ""
    }
    
    private func updateTimer() {
        if timerActive && timerSeconds > 0 {
            timerSeconds -= 1
            updateTimerDisplay()
        } else if timerSeconds == 0 {
            timerActive = false
            timerSeconds = -1  // Set to -1 to trigger view update
            timer = "00:00"
        }
    }
    
    private func updateTimerDisplay() {
        let minutes = timerSeconds / 60
        let seconds = timerSeconds % 60
        timer = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func resendCode() {
        errorMessage = ""  // Clear error message on resend
        codeInputs = ["", "", "", ""]  // Clear OTP inputs
        callStartOnboarding()  // Request new OTP
        startInitialTimer()  // Restart timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = 0  // Focus on first field
        }
    }
    
    private func handleInputChange(index: Int, newValue: String) {
        // Clear error message when user starts typing in first field
        if index == 0 && !newValue.isEmpty {
            errorMessage = ""
        }
        
        let filtered = String(newValue.prefix(1)).filter { $0.isNumber }
        codeInputs[index] = filtered
        
        if !filtered.isEmpty && index < 3 {
            focusedField = index + 1
        } else if !filtered.isEmpty && index == 3 {
            // Otomatis tutup keyboard setelah digit ke-4 diisi
            focusedField = nil
        }
        
        if filtered.isEmpty && index > 0 {
            focusedField = index - 1
        }
    }
    
    private func validateAndProceed() {
        let otp = codeInputs.joined()
        
        guard otp.count == 4 else {
            errorMessage = "OTP harus 4 digit"
            return
        }
        
        errorMessage = ""
        
        // Bypass for testing - accept any 4-digit OTP
        if otp == "1234" || otp == "0000" {
            proceedToWelcome()
            return
        }
        
        isLoading = true
        
        OnboardingAPIService.shared.validateOTP(otp: otp) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if response.succeeded == true {
                        // Check checkpoint after OTP validation
                        self.checkCheckpointAndNavigate()
                    } else {
                        // Use message from API response, fallback to default message
                        errorMessage = response.message ?? "OTP salah, silakan coba lagi"
                        codeInputs = ["", "", "", ""]
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedField = 0
                        }
                    }
                case .failure(let error):
                    print("❌ OTP validation failed: \(error)")
                    errorMessage = "Gagal memvalidasi OTP, silakan coba lagi"
                    codeInputs = ["", "", "", ""]
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedField = 0
                    }
                }
            }
        }
    }
    
    private func checkCheckpointAndNavigate() {
        if let checkpoint = SessionManager.shared.getCheckpoint() {
            print("✅ Checkpoint: \(checkpoint)")
            
            if checkpoint == "StartCob" || checkpoint == "StartKyc" {
                print("➡️ Navigating to WelcomeViewController")
                self.proceedToWelcome()
            } else {
                print("➡️ Navigating to WebViewController")
                self.navigateToWebView()
            }
        } else {
            print("⚠️ No checkpoint found, defaulting to WelcomeViewController")
            self.proceedToWelcome()
        }
    }
    
    private func proceedToWelcome() {
        onWelcomeNavigation?()
    }
    

    
    private func generateFCMDeviceToken() {
        print("📤 EmailVerification: Generating FCM device token...")
        
        // Check if FIRMessaging class exists
        guard let messagingClass = NSClassFromString("FIRMessaging") as? NSObjectProtocol else {
            print("❌ EmailVerification: FIRMessaging class not found - Firebase not initialized")
            return
        }
        print("✅ EmailVerification: FIRMessaging class found")
        
        // Get messaging instance
        guard let messaging = messagingClass.perform(NSSelectorFromString("messaging"))?.takeUnretainedValue() else {
            print("❌ EmailVerification: Failed to get messaging instance")
            return
        }
        print("✅ EmailVerification: Messaging instance obtained")
        
        // Get FCM token
        guard let token = messaging.perform(NSSelectorFromString("FCMToken"))?.takeUnretainedValue() as? String else {
            print("❌ EmailVerification: Failed to get FCM token")
            return
        }
        
        print("✅ EmailVerification: FCM device token generated: \(token.prefix(20))...")
        print("🔑 EmailVerification: Full FCM token: \(token)")
        UserDefaults.standard.set(token, forKey: "cob_fcm_device_token")
        
        OnboardingAPIService.shared.sendFCMDeviceToken(token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    print("✅ EmailVerification: FCM token sent successfully")
                case .failure(let error):
                    print("❌ EmailVerification: FCM token API error: \(error)")
                }
            }
        }
    }
    
    private func callStartOnboarding() {
        isLoading = true
        
        OnboardingAPIService.shared.startOnboarding(
            phoneNumber: phoneNumber,
            email: email
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.succeeded == true {
                        print("✅ Start onboarding success")
                        // Generate FCM device token setelah session ID tersedia
                        self.generateFCMDeviceToken()
                    } else {
                        let message = response.message ?? "Phone number or email already exists"
                        if message == "Phone number or email already exists" {
                            self.showAlertAndDismiss(message: message)
                        } else {
                            self.errorMessage = message
                        }
                    }

                case .failure(let error):
                    print("❌ Start onboarding failed: \(error)")
                    self.errorMessage = "Gagal memulai proses verifikasi"
                }
            }
        }
    }
    
    private func showAlertAndDismiss(message: String) {
        // Find the root view controller to present alert
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            dismissSDK()
            return
        }
        
        let alert = UIAlertController(title: "Informasi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismissSDK()
        })
        
        // Present from the topmost view controller
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        
        topVC.present(alert, animated: true)
    }
    
    private func navigateToWebView() {
        onWelcomeNavigation?()
    }
}

public class EmailVerificationViewController: UIViewController {
    public var onBackPressed: (() -> Void)?
    public var phoneNumber: String = ""
    public var email: String = ""
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSDKDismissal),
            name: NSNotification.Name("CobSDKDismiss"),
            object: nil
        )
        
        if #available(iOS 15.0, *) {
            let hostingController = UIHostingController(rootView: EmailVerificationView(
                email: email,
                phoneNumber: phoneNumber,
                onBackPressed: onBackPressed,
                onWelcomeNavigation: { [weak self] in
                    self?.navigateToWelcome()
                }
            ))
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
    
    private func navigateToWelcome() {
        if let checkpoint = SessionManager.shared.getCheckpoint() {
            if checkpoint == "StartCob" || checkpoint == "StartKyc" {
                let welcomeVC = WelcomeViewController()
                navigationController?.pushViewController(welcomeVC, animated: true)
            } else {
                let webVC = WebViewController()
                navigationController?.pushViewController(webVC, animated: true)
            }
        } else {
            let welcomeVC = WelcomeViewController()
            navigationController?.pushViewController(welcomeVC, animated: true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
}

@available(iOS 13.0, *)
struct EmailTopRoundedRectangle: Shape {
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
