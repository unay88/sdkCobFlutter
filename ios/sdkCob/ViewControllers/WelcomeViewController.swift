import SwiftUI

@available(iOS 14.0, *)
public struct WelcomeView: View {
    @State private var hasUpdatedCheckpoint = false
    public let onBackPressed: (() -> Void)?
    
    public init(onBackPressed: (() -> Void)? = nil) {
        self.onBackPressed = onBackPressed
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
                        Text("Selamat Datang")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -10)
                }
                Spacer()
            }
                // Content with gradient background
                VStack(spacing: 0) {
                    Spacer()
                    // Character illustration
                    SDKImage("icon_male1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 380, height: 380)
                    
                    Spacer().frame(height: 40)
                    
                    // Main text
                    Text("Anda siap memulai pembukaan Rekening!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    Spacer().frame(height: 16)
                    
                    // Subtitle text
                    VStack(spacing: 4) {
                        Text("Sebelum memulai,")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                            .frame(maxWidth: .infinity)
                        Text("Siapkan KTP dan NPWP kamu ya!")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    // Start button
                    Button(action: { navigateToAccountSelection() }) {
                        Text("Oke, Mulai")
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
                .clipShape(WelcomeTopRoundedRectangle(radius: 25))
                .padding(.top, 66)
                // .ignoresSafeArea(.container, edges: .bottom)
            
        }
        .onAppear {
            if !hasUpdatedCheckpoint {
                // updateCheckpointStartCob()
                hasUpdatedCheckpoint = true
            }
        }
    }
    
    private func updateCheckpointStartCob() {
        OnboardingAPIService.shared.updateCheckpoint(checkpoint: "StartCob") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ Update checkpoint StartCob success: \(String(describing: response.data?.checkpoint))")
                    if let newCheckpoint = response.data?.checkpoint {
                        SessionManager.shared.setCheckpoint(newCheckpoint)
                    }
                case .failure(let error):
                    print("❌ Update checkpoint StartCob failed: \(error)")
                }
            }
        }
    }
    
    private func navigateToAccountSelection() {
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToAccountSelection"), object: nil)
    }
    
    private func dismissSDK() {
        CobSDKManager.shared.notifyCancel()
        NotificationCenter.default.post(name: NSNotification.Name("CobSDKDismiss"), object: nil)
    }
}

@available(iOS 14.0, *)
public struct CompletionView: View {
    public var body: some View {
        VStack {
            Text("Verifikasi Berhasil")
                .font(.title)
                .padding()
            Text("Email Anda telah berhasil diverifikasi")
                .font(.body)
                .foregroundColor(.gray)
        }
    }
}



public class WelcomeViewController: UIViewController {
    public var onBackPressed: (() -> Void)?
    
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
            selector: #selector(handleNavigateToAccountSelection),
            name: NSNotification.Name("NavigateToAccountSelection"),
            object: nil
        )
        
        if #available(iOS 14.0, *) {
            let hostingController = UIHostingController(rootView: WelcomeView(onBackPressed: onBackPressed))
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
    
    @objc private func handleNavigateToAccountSelection() {
        let accountSelectionVC = AccountSelectionViewController()
        navigationController?.pushViewController(accountSelectionVC, animated: true)
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
struct WelcomeTopRoundedRectangle: Shape {
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
