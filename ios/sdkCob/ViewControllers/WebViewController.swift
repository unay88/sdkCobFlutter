import UIKit
import WebKit
import DigitalIdentity

public class WebViewController: UIViewController {
    
    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    private var isNavigatingBack = false
    private var hasRedirectedToSuccess = false
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable back navigation
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        setupUI()
        setupWebView()
        setupActivityIndicator()
        setupPushNotificationListener()
        loadKYCResult()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        let whiteBackgroundView = UIView()
        whiteBackgroundView.backgroundColor = .white
        whiteBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(whiteBackgroundView)
        
        NSLayoutConstraint.activate([
            whiteBackgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            whiteBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            whiteBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            whiteBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "NativeBridge")
        
        // Enable form state preservation
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Configure preferences for better NextJS handling
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = preferences
        
        // Enable localStorage and sessionStorage persistence
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        // Configure process pool for better memory management
        config.processPool = WKProcessPool()
        
        // Inject JavaScript to make NativeBridge available and preserve form state
        let jsCode = """
            window.NativeBridge = {
                postMessage: function(message) {
                    window.webkit.messageHandlers.NativeBridge.postMessage(message);
                }
            };
            
            // Form state preservation
            (function() {
                var formData = {};
                
                function saveFormData() {
                    var inputs = document.querySelectorAll('input, select, textarea');
                    inputs.forEach(function(input) {
                        if (input.name || input.id) {
                            var key = input.name || input.id;
                            if (input.type === 'checkbox' || input.type === 'radio') {
                                formData[key] = input.checked;
                            } else {
                                formData[key] = input.value;
                            }
                        }
                    });
                    sessionStorage.setItem('formData', JSON.stringify(formData));
                }
                
                function restoreFormData() {
                    var savedData = sessionStorage.getItem('formData');
                    if (savedData) {
                        try {
                            formData = JSON.parse(savedData);
                            var inputs = document.querySelectorAll('input, select, textarea');
                            inputs.forEach(function(input) {
                                if (input.name || input.id) {
                                    var key = input.name || input.id;
                                    if (formData[key] !== undefined) {
                                        if (input.type === 'checkbox' || input.type === 'radio') {
                                            input.checked = formData[key];
                                        } else {
                                            input.value = formData[key];
                                        }
                                    }
                                }
                            });
                        } catch(e) {
                            console.log('Error restoring form data:', e);
                        }
                    }
                }
                
                // Save form data on input changes
                document.addEventListener('input', saveFormData);
                document.addEventListener('change', saveFormData);
                
                // Restore form data when page loads
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', restoreFormData);
                } else {
                    restoreFormData();
                }
                
                // Also restore after a short delay to handle dynamic content
                setTimeout(restoreFormData, 500);
            })();
        """
        let userScript = WKUserScript(source: jsCode, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.alpha = 0.0
        
        // Enable back/forward cache and NextJS context preservation
        if #available(iOS 14.0, *) {
            webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        webView.allowsBackForwardNavigationGestures = true
        
        // Disable cache to prevent stale context issues
        webView.configuration.websiteDataStore.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0),
            completionHandler: {}
        )
        
        // Enable custom user agent for better NextJS compatibility
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupActivityIndicator() {
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .large)
        } else {
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupPushNotificationListener() {
        print("🔔 WebViewController: Setting up StatusCob push notification listener")
        
        // Listen for StatusCobPushNotification (exact match from AppDelegate)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStatusCobPushNotification(_:)),
            name: NSNotification.Name("StatusCobPushNotification"),
            object: nil
        )
        
        // Debug: Listen for StatusKyc notifications too
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStatusKycNotification(_:)),
            name: NSNotification.Name("StatusKycPushNotification"),
            object: nil
        )
        

        
        print("✅ WebViewController: All notification listeners setup complete")
    }
    
    @objc private func handleStatusCobPushNotification(_ notification: Notification) {
        guard !hasRedirectedToSuccess else {
            print("⚠️ WebViewController: Already redirected to success, ignoring FCM")
            return
        }
        
        print("📱 WebViewController: Push notification received")
        print("📱 WebViewController: Notification userInfo: \(notification.userInfo ?? [:])")
        
        guard let userInfo = notification.userInfo else {
            print("⚠️ WebViewController: No userInfo in notification")
            return
        }
        
        print("🔍 WebViewController DEBUG - Full userInfo: \(userInfo)")
        
        // Get originalUserInfo if exists (from AppDelegate)
        let actualUserInfo: [AnyHashable: Any]
        if let original = userInfo["originalUserInfo"] as? [AnyHashable: Any] {
            print("🔍 WebViewController DEBUG - Using originalUserInfo")
            actualUserInfo = original
        } else {
            print("🔍 WebViewController DEBUG - Using direct userInfo")
            actualUserInfo = userInfo
        }
        
        // Check status = "success" and type = "cob"
        let status = actualUserInfo["status"] as? String ?? ""
        let type = actualUserInfo["type"] as? String ?? ""
        
        let statusValid = status.lowercased() == "success"
        let typeValid = type.lowercased() == "cob"
        
        print("📍 WebViewController: Status: '\(status)' -> \(statusValid ? "✅ success" : "❌ not success")")
        print("📍 WebViewController: Type: '\(type)' -> \(typeValid ? "✅ cob" : "❌ not cob")")
        
        // Redirect if status is "success" AND type is "cob"
        if statusValid && typeValid {
            hasRedirectedToSuccess = true
            print("✅ WebViewController: Valid COB notification - redirecting to success URL")
            
            guard let sessionId = SessionManager.shared.getSessionId() else {
                print("❌ WebViewController: No session ID found")
                return
            }
            
            let successUrl = "\(SDKConfiguration.getSuccessUrl())/\(sessionId)"
            print("🌐 WebViewController: Loading success URL: \(successUrl)")
            
            guard let url = URL(string: successUrl) else {
                print("❌ WebViewController: Invalid success URL: \(successUrl)")
                return
            }
            
            DispatchQueue.main.async {
                print("🔄 WebViewController: Executing webView.load on main thread")
                let request = URLRequest(url: url)
                self.webView.load(request)
                print("✅ WebViewController: webView.load executed")
            }
        } else {
            print("⚠️ WebViewController: Not a valid COB notification (status: \(statusValid), type: \(typeValid))")
        }
    }
    
    @objc private func handleAnyStatusCobNotification(_ notification: Notification) {
        print("🔍 WebViewController: Any StatusCob notification received!")
        print("🔍 WebViewController: Notification name: \(notification.name.rawValue)")
        print("🔍 WebViewController: Notification userInfo: \(notification.userInfo ?? [:])")
        
        // Forward to main handler
        handleStatusCobPushNotification(notification)
    }
    
    @objc private func handleStatusKycNotification(_ notification: Notification) {
        print("🔍 WebViewController: StatusKyc notification received (debug)")
        print("🔍 WebViewController: Notification name: \(notification.name.rawValue)")
        print("🔍 WebViewController: Notification userInfo: \(notification.userInfo ?? [:])")
    }
    
    private func loadKYCResult() {
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ [INIT] No session ID found")
            showError("Session ID not available")
            return
        }
        
        let urlString = "\(SDKConfiguration.getKYCResultUrl())/\(sessionId)"
        guard let url = URL(string: urlString) else {
            print("❌ [INIT] Invalid URL: \(urlString)")
            showError("Invalid URL")
            return
        }
        
        print("🌐 [INIT] Loading KYC Result: \(urlString)")
        print("🌐 [INIT] WebViewController instance: \(Unmanaged.passUnretained(self).toOpaque())")
        print("📱 [INIT] iOS User Agent: \(webView.customUserAgent ?? "default")")
        print("📱 [INIT] Platform: iOS")
        activityIndicator.startAnimating()
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("📱 WebViewController will disappear - setting flag")
        hasRedirectedToSuccess = true
    }
    
    deinit {
        print("📱 WebViewController deinit - cleaning up")
        NotificationCenter.default.removeObserver(self)
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Public Methods for External Push Notification Handling
    
    /// Method to be called by host application when StatusCob push notification is received
    public func handleExternalStatusCobNotification(userInfo: [AnyHashable: Any]) {
        print("📨 WebViewController: External StatusCob notification received from host app")
        print("📨 WebViewController: UserInfo: \(userInfo)")
        
        // Create notification object and forward to handler
        let notification = Notification(
            name: NSNotification.Name("StatusCobPushNotification"),
            object: nil,
            userInfo: userInfo as? [AnyHashable: Any]
        )
        
        handleStatusCobPushNotification(notification)
    }
    
    /// Static method to handle push notification for any WebViewController instance
    public static func handleStatusCobPushNotification(userInfo: [AnyHashable: Any]) {
        print("📨 WebViewController: Static method - StatusCob notification received")
        
        // Post notification to NotificationCenter for any listening WebViewController
        NotificationCenter.default.post(
            name: NSNotification.Name("StatusCobPushNotification"),
            object: nil,
            userInfo: userInfo as? [AnyHashable: Any]
        )
    }
}

extension WebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("🌐 WebView started loading: \(webView.url?.absoluteString ?? "unknown")")
        print("🌐 WebViewController instance: \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        
        // Fade in WebView after loading
        UIView.animate(withDuration: 0.3) {
            webView.alpha = 1.0
        }
        
        // Restore form data after page loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            webView.evaluateJavaScript("""
                if (typeof restoreFormData === 'function') {
                    restoreFormData();
                } else {
                    var savedData = sessionStorage.getItem('formData');
                    if (savedData) {
                        try {
                            var formData = JSON.parse(savedData);
                            var inputs = document.querySelectorAll('input, select, textarea');
                            inputs.forEach(function(input) {
                                if (input.name || input.id) {
                                    var key = input.name || input.id;
                                    if (formData[key] !== undefined) {
                                        if (input.type === 'checkbox' || input.type === 'radio') {
                                            input.checked = formData[key];
                                        } else {
                                            input.value = formData[key];
                                        }
                                    }
                                }
                            });
                        } catch(e) {
                            console.log('Error restoring form data:', e);
                        }
                    }
                }
            """) { result, error in
                if let error = error {
                    print("❌ Error restoring form data: \(error)")
                } else {
                    print("✅ Form data restoration executed")
                }
            }
        }
        
        // Additional restoration for dynamic NextJS content
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            webView.evaluateJavaScript("""
                // Trigger NextJS hydration if needed
                if (window.next && window.next.router) {
                    console.log('NextJS router available');
                }
                
                // Additional form restoration for dynamic content
                var savedData = sessionStorage.getItem('formData');
                if (savedData) {
                    try {
                        var formData = JSON.parse(savedData);
                        var inputs = document.querySelectorAll('input, select, textarea');
                        inputs.forEach(function(input) {
                            if (input.name || input.id) {
                                var key = input.name || input.id;
                                if (formData[key] !== undefined) {
                                    if (input.type === 'checkbox' || input.type === 'radio') {
                                        input.checked = formData[key];
                                    } else {
                                        input.value = formData[key];
                                    }
                                }
                            }
                        });
                    } catch(e) {
                        console.log('Error in delayed restoration:', e);
                    }
                }
            """) { _, _ in }
        }
        
        print("✅ WebView finished loading: \(webView.url?.absoluteString ?? "unknown")")
        print("🌐 WebViewController instance: \(Unmanaged.passUnretained(self).toOpaque())")
        
        // Only set flag if we're on success URL
        if let currentUrl = webView.url?.absoluteString, currentUrl.contains(SDKConfiguration.getSuccessUrl()) {
            hasRedirectedToSuccess = true
            print("🚫 WebView: On success URL - hasRedirectedToSuccess set to true")
        } else {
            print("📍 WebView: On regular URL - keeping hasRedirectedToSuccess as \(hasRedirectedToSuccess)")
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        print("❌ WebView failed to load: \(error)")
        print("❌ WebView URL: \(webView.url?.absoluteString ?? "unknown")")
        showError("Failed to load page: \(error.localizedDescription)")
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        print("❌ WebView failed provisional navigation: \(error)")
        print("❌ WebView URL: \(webView.url?.absoluteString ?? "unknown")")
        showError("Failed to load page: \(error.localizedDescription)")
    }
}

extension WebViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "NativeBridge", let messageBody = message.body as? String {
            print("📱 Received message from WebView: \(messageBody)")
            print("🌐 Current URL: \(webView.url?.absoluteString ?? "unknown")")
            print("📱 User Agent: \(webView.customUserAgent ?? "default")")
            print("🔍 NEW CODE ACTIVE: \(Unmanaged.passUnretained(self).toOpaque()) - hasRedirectedToSuccess=\(hasRedirectedToSuccess)")
            
            if messageBody == "closeWebView" {
                print("✅ WebView: closeWebView trigger received - back to ValidasiHp")
                navigateBackToHost(withResult: "cancelled")
            } else if messageBody == "retryKyc" {
                print("🔄 NEW FLOW: retryKyc received - starting reinitiate flow")
                startReinitiateFlow()
            } else if messageBody == "FinishCob" {
                print("✅ WebView: FinishCob trigger received - navigate to HomePage")
                navigateBackToHost(withResult: "success")
            // } else if messageBody == "formFinished" {
            //     print("✅ WebView: formFinished trigger received - navigate to HomePage")
            //     navigateBackToHost(withResult: "success")
            } else if messageBody == "disableRefresh" {
                print("✅ WebView: disableRefresh trigger received (iOS gets this instead of FinishCob) - navigate to HomePage")
                navigateBackToHost(withResult: "success")
            } else if messageBody == "waitingAccountNumber" {
                print("⏳ WebView: waitingAccountNumber trigger received - starting long polling")
                startLongPolling()
            } else {
                print("⚠️ WebView: Unknown message received: \(messageBody)")
            }
        }
    }
    
    private func navigateBackToHost(withResult result: String = "success") {
        guard !isNavigatingBack else { return }
        isNavigatingBack = true
        
        print("🔙 WebView: Closing SDK with result: \(result)")
        
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "NativeBridge")
        
        if result == "success" {
            print("✅ WebView: Calling notifySuccess with success data")
            CobSDKManager.shared.notifySuccess(data: [
                "status": "success",
                "message": "COB completed successfully",
                "action": "navigate_to_home",
                "result": "success"
            ])
        } else {
            print("❌ WebView: Calling notifyCancel for result: \(result)")
            CobSDKManager.shared.notifyCancel()
        }
    }
    
    public func navigateToRetryKYC() {
        print("🔄 navigateToRetryKYC called")
        print("🔄 hasRedirectedToSuccess = \(hasRedirectedToSuccess)")
        print("🔄 WebViewController instance: \(Unmanaged.passUnretained(self).toOpaque())")
        
        guard !hasRedirectedToSuccess else {
            print("⚠️ WebView: Already redirected to success, ignoring retry KYC navigation")
            return
        }
        
        // Additional safety check
        if let currentUrl = webView.url?.absoluteString, currentUrl.contains("kyc-result") {
            print("⚠️ WebView: URL contains kyc-result, blocking retry KYC navigation")
            return
        }
        
        print("🔄 WebView: Navigating to Retry KYC")
        let ulangVC = UlangSDKCobViewController()
        navigationController?.pushViewController(ulangVC, animated: true)
    }
    
    private func startLongPolling() {
        guard !hasRedirectedToSuccess else {
            print("⚠️ WebViewController: Already redirected to success, ignoring long polling")
            return
        }
        
        print("🔄 Starting long polling...")
        OnboardingAPIService.shared.longPooling { [weak self] result in
            guard let self = self, !self.hasRedirectedToSuccess else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ Long polling success: \(response)")
                    self.hasRedirectedToSuccess = true
                    self.redirectToSuccessUrl()
                case .failure(let error):
                    print("❌ Long polling failed: \(error)")
                }
            }
        }
    }
    
    private func redirectToSuccessUrl() {
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ WebViewController: No session ID found")
            return
        }
        
        let successUrl = "\(SDKConfiguration.getSuccessUrl())/\(sessionId)"
        print("🌐 WebViewController: Loading success URL: \(successUrl)")
        
        guard let url = URL(string: successUrl) else {
            print("❌ WebViewController: Invalid success URL: \(successUrl)")
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
        print("✅ WebViewController: webView.load executed")
    }
    
    private func startReinitiateFlow() {
        let currentSession = SessionManager.shared.getSessionId() ?? "NO_SESSION"
        print("🔄 [FLOW] Starting reinitiate flow...")
        print("🔄 [FLOW] Current session before reinitiate: \(currentSession)")
        print("🔄 [FLOW] WebViewController instance: \(Unmanaged.passUnretained(self).toOpaque())")
        
        OnboardingAPIService.shared.reinitiateOnboarding { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    if response.succeeded == true {
                        let newSession = SessionManager.shared.getSessionId() ?? "NO_SESSION"
                        print("✅ [FLOW] Reinitiate success - launching KYC")
                        print("✅ [FLOW] New session after reinitiate: \(newSession)")
                        print("✅ [FLOW] Session changed: \(currentSession) -> \(newSession)")
                        self.launchKYCVerification()
                    } else {
                        print("❌ [FLOW] Reinitiate failed: \(response.message ?? "Unknown error")")
                    }
                case .failure(let error):
                    print("❌ [FLOW] Reinitiate failed: \(error)")
                }
            }
        }
    }
    
    private func launchKYCVerification() {
        let token = SessionManager.shared.getToken()
        let sessionId = SessionManager.shared.getSessionId() ?? "NO_SESSION"
        
        print("🚀 [FLOW] Launching KYC verification...")
        print("🚀 [FLOW] Using session: \(sessionId)")
        print("🚀 [FLOW] Token available: \(token != nil)")
        
        guard let finalToken = token else {
            print("❌ [FLOW] Token not available")
            return
        }
        
        let correlationId = sessionId
        
        let kycConfig = DigitalIdentityKYCVerificationConfig(
            baseUrl: SDKConfiguration.getKYCBaseUrl(),
            token: finalToken,
            correlationId: correlationId,
            language: .indonesia,
            theme: BJBThemeHelper.createCustomTheme()
        )
        
        print("🚀 [FLOW] KYC Config - baseUrl: \(SDKConfiguration.getKYCBaseUrl())")
        print("🚀 [FLOW] KYC Config - correlationId: \(correlationId)")
        
        do {
            try DigitalIdentitySdk.shared.launchKYCVerification(
                config: kycConfig,
                viewcontroller: self,
                helpCenter: SDKHelpCenterDelegate()
            ) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleKYCResult(result)
                }
            }
            print("🚀 [FLOW] KYC verification launched successfully")
        } catch {
            print("❌ [FLOW] Failed to launch KYC: \(error)")
        }
    }
    
    private func handleKYCResult(_ result: Any) {
        let resultString = String(describing: result)
        let sessionId = SessionManager.shared.getSessionId() ?? "NO_SESSION"
        
        print("🔍 [FLOW] KYC Result received: \(resultString)")
        print("🔍 [FLOW] Current session after KYC: \(sessionId)")
        print("🔍 [FLOW] WebViewController instance: \(Unmanaged.passUnretained(self).toOpaque())")
        
        if resultString.lowercased().contains("success") || resultString.lowercased().contains("completed") {
            print("✅ [FLOW] KYC completed - reloading WebView with new session")
            reloadWebViewWithNewSession()
        } else if resultString.lowercased().contains("cancel") || resultString.lowercased().contains("dismiss") {
            print("⚠️ [FLOW] KYC cancelled by user - staying in current WebView")
        } else {
            print("❌ [FLOW] KYC not completed: \(resultString)")
        }
    }
    
    private func reloadWebViewWithNewSession() {
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ [FLOW] No session ID found for reload")
            return
        }
        
        let urlString = "\(SDKConfiguration.getKYCResultUrl())/\(sessionId)"
        guard let url = URL(string: urlString) else {
            print("❌ [FLOW] Invalid URL for reload: \(urlString)")
            return
        }
        
        print("🔄 [FLOW] Reloading WebView with new session")
        print("🔄 [FLOW] New URL: \(urlString)")
        print("🔄 [FLOW] WebViewController instance: \(Unmanaged.passUnretained(self).toOpaque())")
        print("🔄 [FLOW] Previous URL: \(webView.url?.absoluteString ?? "none")")
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        print("✅ [FLOW] WebView reload initiated")
    }

private class SDKHelpCenterDelegate: DigitalIdentityHelpCenterDelegate {
    func isHelpCTAEnabled(for type: DigitalIdentityHelpCenterType) -> Bool {
        return true
    }
    
    func onHelpCTAClicked(in viewController: UIViewController, type: DigitalIdentityHelpCenterType) {
        print("ℹ️ Help center clicked")
    }
}

}
