import SwiftUI
import WebKit

@available(iOS 14.0, *)
public struct TermsView: View {
    @State private var isAgreed = false
    @State private var termsContent = ""
    @State private var isLoading = true
    @State private var hasScrolledToBottom = false
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    public let onBackPressed: (() -> Void)?
    
    public init(onBackPressed: (() -> Void)? = nil) {
        self.onBackPressed = onBackPressed
    }
    
    @State private var htmlContentWithCheckbox = ""
    
    private func generateHTMLContent() {
        let checkboxHTML = """
        <div style="margin-top: 30px; padding: 20px; border-top: 1px solid #ddd;">
            <label style="display: flex; align-items: center; font-size: 14px; cursor: pointer;">
                <input type="checkbox" id="agreeCheckbox" onchange="toggleAgreement()" style="margin-right: 10px; transform: scale(1.2);">
                <span>Saya menyetujui syarat dan ketentuan yang berlaku</span>
            </label>
        </div>
        <script>
        function toggleAgreement() {
            const checkbox = document.getElementById('agreeCheckbox');
            const scrollY = window.pageYOffset;
            window.webkit.messageHandlers.checkboxHandler.postMessage({agreed: checkbox.checked, scrollPosition: scrollY});
        }
        
        function restoreScrollPosition(position) {
            window.scrollTo(0, position);
        }
        </script>
        """
        htmlContentWithCheckbox = termsContent + checkboxHTML
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
                        Button(action: { onBackPressed?() ?? goBackToCardSelection() }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                        Spacer()
                        Text("Syarat & Ketentuan")
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
            VStack(spacing: 0) {
                // Terms content in scrollable view with proper height
                GeometryReader { geometry in
                    if isLoading {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                HTMLView(htmlContent: htmlContentWithCheckbox, isAgreed: $isAgreed, hasScrolledToBottom: $hasScrolledToBottom)
                                    .frame(minHeight: geometry.size.height - 40)
                                
                                // Bottom detection area
                                GeometryReader { bottomGeometry in
                                    Color.clear
                                        .onAppear {
                                            hasScrolledToBottom = true
                                        }
                                        .onChange(of: bottomGeometry.frame(in: .named("scrollView")).minY) { value in
                                            if value <= geometry.size.height {
                                                hasScrolledToBottom = true
                                            }
                                        }
                                }
                                .frame(height: 1)
                            }
                        }
                        .coordinateSpace(name: "scrollView")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: { agreeToTerms() }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSubmitting ? "Loading..." : "Selanjutnya")
                                .font(.custom("Quicksand-Bold", size: 14))
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 11)
                    }
                    .background((isAgreed && !isSubmitting) ? Color(red: 0xff/255.0, green: 0xc9/255.0, blue: 0x45/255.0) : Color.gray)
                    .cornerRadius(10)
                    .disabled(!isAgreed || isSubmitting)
                    
                    // Button(action: { cancelTerms() }) {
                    //     Text("Batal")
                    //         .font(.custom("Quicksand-Bold", size: 14))
                    //         .fontWeight(.bold)
                    //         .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                    //         .frame(maxWidth: .infinity)
                    //         .padding(.vertical, 11)
                    //         .padding(.horizontal, 11)
                    // }
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .padding(.top, -30)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.92, green: 0.95, blue: 1.0),  // Very light blue at bottom
                        Color.white                                // White at top
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .clipShape(TermsTopRoundedRectangle(radius: 25))
            .padding(.top, 66)
            
            // Loading overlay
            if isLoading {
                LoadingOverlay(message: "Memuat syarat...")
            }
        }
        .onAppear {
            loadTermsAndCondition()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func loadTermsAndCondition() {
        // Debug session state
        print("🔍 Terms View - Session Debug:")
        print("  SessionID: \(SessionManager.shared.getSessionId() ?? "nil")")
        print("  IdentityID: \(SessionManager.shared.getIdentityId() ?? "nil")")
        print("  Checkpoint: \(SessionManager.shared.getCheckpoint() ?? "nil")")
        print("  HasValidSession: \(SessionManager.shared.hasValidSession())")
        
        OnboardingAPIService.shared.getTermsAndCondition { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let contentId = response.data?.contentId {
                        self.termsContent = contentId
                        // print("✅ Loaded terms content: \(contentId)")
                    } else {
                        self.termsContent = "Terms and conditions content not available."
                    }
                    self.generateHTMLContent()
                    self.isLoading = false
                case .failure(let error):
                    print("❌ Failed to load terms: \(error)")
                    self.termsContent = "Failed to load terms and conditions. Please try again."
                    self.generateHTMLContent()
                    self.isLoading = false
                }
            }
        }
    }
    
    private func goBackToCardSelection() {
        // Use callback for navigation
        onBackPressed?()
    }
    
    private func agreeToTerms() {
        isSubmitting = true
        
        // Check if we have session data
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ No session ID found - need to start onboarding first")
            self.isSubmitting = false
            self.alertMessage = "Session tidak valid. Silakan mulai ulang proses onboarding."
            self.showAlert = true
            return
        }
        
        print("🚀 No checkpoint - using initiateOnboarding for first time")
        callInitiateOnboarding()
    }
    
    private func callInitiateOnboarding() {
        OnboardingAPIService.shared.initiateOnboarding { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ Initiate API Success: \(response)")
                    if response.succeeded == true {
                        self.updateCheckpointStartKyc()
                    } else {
                        self.isSubmitting = false
                        print("❌ Initiate failed - succeeded: \(response.succeeded ?? false)")
                        let errorMsg = "Gagal memproses persetujuan. Status: \(response.statusCode ?? 0)"
                        self.alertMessage = errorMsg
                        self.showAlert = true
                    }
                case .failure(let error):
                    self.isSubmitting = false
                    print("❌ Initiate API Error: \(error)")
                    self.alertMessage = self.getErrorMessage(error)
                    self.showAlert = true
                }
            }
        }
    }
    
    private func callReinitiateOnboarding() {
        OnboardingAPIService.shared.reinitiateOnboarding { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ Reinitiate API Success: \(response)")
                    if response.succeeded == true {
                        self.updateCheckpointStartKyc()
                    } else {
                        self.isSubmitting = false
                        print("❌ Reinitiate failed - succeeded: \(response.succeeded ?? false)")
                        let errorMsg = "Gagal memproses persetujuan. Status: \(response.statusCode ?? 0)"
                        self.alertMessage = errorMsg
                        self.showAlert = true
                    }
                case .failure(let error):
                    self.isSubmitting = false
                    print("❌ Reinitiate API Error: \(error)")
                    self.alertMessage = self.getErrorMessage(error)
                    self.showAlert = true
                }
            }
        }
    }
    
    private func getErrorMessage(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .noSessionId:
                return "Session tidak valid. Silakan mulai ulang."
            case .noData:
                return "Tidak ada respon dari server."
            case .invalidResponse:
                return "URL tidak valid."
            default:
                return "Terjadi kesalahan API."
            }
        }
        return "Koneksi bermasalah: \(error.localizedDescription)"
    }
    
    private func updateCheckpointStartKyc() {
        OnboardingAPIService.shared.updateCheckpoint(checkpoint: "StartKyc") { result in
            DispatchQueue.main.async {
                self.isSubmitting = false
                switch result {
                case .success(let response):
                    print("✅ Update checkpoint StartKyc success: \(String(describing: response.data?.checkpoint))")
                    if let newCheckpoint = response.data?.checkpoint {
                        SessionManager.shared.setCheckpoint(newCheckpoint)
                    }
                    self.navigateToSDKCob()
                case .failure(let error):
                    print("❌ Update checkpoint StartKyc failed: \(error)")
                    // Tetap navigate meskipun update checkpoint gagal
                    self.navigateToSDKCob()
                }
            }
        }
    }
    
    private func navigateToSDKCob() {
        // Notify UIKit to handle SDKCob navigation
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToSDKCob"), object: nil)
    }
    
    private func cancelTerms() {
        goBackToCardSelection()
    }
}

// TermsViewController is now fully SwiftUI - use TermsView directly
@available(iOS 14.0, *)
public typealias TermsViewController = TermsView

// MARK: - HTMLView for rendering HTML content
@available(iOS 14.0, *)
struct HTMLView: UIViewRepresentable {
    let htmlContent: String
    @Binding var isAgreed: Bool
    @Binding var hasScrolledToBottom: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.configuration.userContentController.add(context.coordinator, name: "checkboxHandler")
        context.coordinator.webView = webView
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only reload if content actually changed, not when isAgreed changes
        if context.coordinator.lastLoadedContent != htmlContent {
            let htmlString = """
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        font-size: 14px;
                        line-height: 1.5;
                        margin: 0;
                        padding: 16px;
                        color: #333;
                    }
                </style>
            </head>
            <body>
                \(htmlContent)
            </body>
            </html>
            """
            uiView.loadHTMLString(htmlString, baseURL: nil)
            context.coordinator.lastLoadedContent = htmlContent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: HTMLView
        weak var webView: WKWebView?
        private var savedScrollPosition: Double = 0
        var lastLoadedContent: String = ""
        
        init(_ parent: HTMLView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "checkboxHandler",
               let body = message.body as? [String: Any],
               let agreed = body["agreed"] as? Bool {
                
                // Save scroll position if provided
                if let scrollPosition = body["scrollPosition"] as? Double {
                    self.savedScrollPosition = scrollPosition
                }
                
                DispatchQueue.main.async {
                    self.parent.isAgreed = agreed
                    
                    // Restore scroll position after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let webView = self.webView {
                            let script = "restoreScrollPosition(\(self.savedScrollPosition));"
                            webView.evaluateJavaScript(script, completionHandler: nil)
                        }
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

// Custom shape for top-only rounded corners
@available(iOS 13.0, *)
struct TermsTopRoundedRectangle: Shape {
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
