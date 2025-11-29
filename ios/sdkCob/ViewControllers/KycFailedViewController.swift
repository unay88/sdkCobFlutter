import SwiftUI
import UIKit

@available(iOS 14.0, *)
public struct KycFailedView: View {
    public let onBackPressed: (() -> Void)?
    
    public init(onBackPressed: (() -> Void)? = nil) {
        self.onBackPressed = onBackPressed
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.container, edges: .top)
            
            VStack(spacing: 0) {
                // Header with image
                ZStack {
                    SDKImage("header_cob_account_setting")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 70)
                        .clipped()
                }
                
                // Content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Character illustration with failed icon
                    ZStack {
                        SDKImage("icon_male2")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                        
                        // Red X icon overlay
                        Circle()
                            .fill(Color.red)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .bold))
                            )
                            .offset(x: 60, y: 60)
                    }
                    
                    Spacer().frame(height: 40)
                    
                    // Title
                    Text("E-KYC Gagal Dilakukan!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Spacer().frame(height: 16)
                    
                    // Description
                    Text("Silahkan melakukan ulang E-KYC\nSiapkan kembali KTP dan NPWP")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Try again button
                    Button(action: { tryAgain() }) {
                        Text("Coba Lagi")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color(red: 1.0, green: 0.6, blue: 0.2))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.white)
        }
    }
    
    private func tryAgain() {
        // Complete SDK flow and notify error
        CobSDKManager.shared.notifyError(message: "KYC verification failed")
        NotificationCenter.default.post(name: NSNotification.Name("CobSDKDismiss"), object: nil)
    }
}

public class KycFailedViewController: UIViewController {
    public var onBackPressed: (() -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            let hostingController = UIHostingController(rootView: KycFailedView(onBackPressed: onBackPressed))
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
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
}
