import SwiftUI

@available(iOS 14.0, *)
public struct AccountSelectionView: View {
    @State private var selectedCardIndex = 0
    @State private var accountTypes: [AccountType] = []
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hasError = false
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
                        Button(action: { goBackToWelcome() }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                        Spacer()
                        Text("Pilih Rekening Tabungan")
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
                Spacer().frame(height: 40)
                
                // Title
                Text("Pilih Jenis Rekening yang ingin dibuka")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Card Carousel or Error State
                if isLoading {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 200)
                } else if hasError {
                    VStack(spacing: 20) {
                        Text("Gagal memuat data")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Button(action: { retryLoadAccountTypes() }) {
                            Text("Coba Lagi")
                                .font(.custom("Quicksand-Bold", size: 14))
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .padding(.horizontal, 11)
                        }
                        .background(Color(red: 0xff/255.0, green: 0xc9/255.0, blue: 0x45/255.0))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    }
                    .frame(height: 200)
                } else {
                    TabView(selection: $selectedCardIndex) {
                        ForEach(0..<accountTypes.count, id: \.self) { index in
                            VStack(spacing: 16) {
                                // Card Image
                                if let imageUrl = accountTypes[index].imageUrl, !imageUrl.isEmpty {
                                    AsyncImage(url: URL(string: imageUrl)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .cornerRadius(12)
                                        case .failure(_):
                                            SDKImage("Tandamata")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .cornerRadius(12)
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 200)
                                        @unknown default:
                                            SDKImage("Tandamata")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .cornerRadius(12)
                                        }
                                    }
                                } else {
                                    SDKImage("Tandamata")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(12)
                                }
                                
                                // Custom page indicator below image
                                HStack(spacing: 8) {
                                    ForEach(0..<accountTypes.count, id: \.self) { idx in
                                        Circle()
                                            .fill(selectedCardIndex == idx ? Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0) : Color.gray.opacity(0.4))
                                            .frame(width: 8, height: 8)
                                            .animation(.easeInOut(duration: 0.3), value: selectedCardIndex)
                                    }
                                }
                                // .padding(.top, 10)
                                
                                // Card Title
                                Text(accountTypes[index].name ?? "Unknown")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                                
                                // Card Description
                                Text(accountTypes[index].description ?? "No description")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 400)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Continue button
                Button(action: { navigateToCardSelection() }) {
                    Text("Pilih Rekening Ini")
                        .font(.custom("Quicksand-Bold", size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 11)
                }
                .background((!isLoading && !accountTypes.isEmpty) ? Color(red: 0xff/255.0, green: 0xc9/255.0, blue: 0x45/255.0) : Color.gray)
                .cornerRadius(10)
                .disabled(isLoading || accountTypes.isEmpty)
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
            .clipShape(AccountTopRoundedRectangle(radius: 25))
            .padding(.top, 66)
            
            // Loading overlay
            if isLoading {
                LoadingOverlay(message: "Memuat data...")
            }
        }
        .onAppear {
            loadAccountTypes()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func loadAccountTypes() {
        isLoading = true
        hasError = false
        OnboardingAPIService.shared.getAccountTypes { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let accountData = response.data {
                        self.accountTypes = accountData
                        self.isLoading = false
                        self.hasError = false
                        print("✅ Loaded \(accountData.count) account types")
                    }
                case .failure(let error):
                    print("❌ Failed to load account types: \(error)")
                    self.isLoading = false
                    self.hasError = true
                }
            }
        }
    }
    
    private func retryLoadAccountTypes() {
        loadAccountTypes()
    }
    
    private func navigateToCardSelection() {
        // Save selected account type name to session
        if !accountTypes.isEmpty && selectedCardIndex < accountTypes.count {
            let selectedAccountName = accountTypes[selectedCardIndex].name
            SessionManager.shared.setIdAccountType(selectedAccountName)
            
            print("📝 Selected Account Type: \(accountTypes[selectedCardIndex].name ?? "Unknown")")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToCardSelection"), object: nil)
    }
    
    private func goBackToWelcome() {
        NotificationCenter.default.post(name: NSNotification.Name("BackToWelcome"), object: nil)
    }
}

// AccountSelectionViewController is now fully SwiftUI - use AccountSelectionView directly
public class AccountSelectionViewController: UIViewController {
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
            selector: #selector(handleBackToWelcome),
            name: NSNotification.Name("BackToWelcome"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNavigateToCardSelection),
            name: NSNotification.Name("NavigateToCardSelection"),
            object: nil
        )
        
        if #available(iOS 14.0, *) {
            let hostingController = UIHostingController(rootView: AccountSelectionView(onBackPressed: onBackPressed))
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
    
    @objc private func handleBackToWelcome() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleNavigateToCardSelection() {
        let cardSelectionVC = CardSelectionViewController()
        navigationController?.pushViewController(cardSelectionVC, animated: true)
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
struct AccountTopRoundedRectangle: Shape {
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
