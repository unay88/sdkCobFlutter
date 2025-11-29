import SwiftUI
import UIKit

@available(iOS 14.0, *)
public struct KycSuccessView: View {
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
                        .frame(height: 80)
                        .clipped()
                }
                
                Spacer()
            }
            
            // Content with rounded top corners - overlapping header
            VStack(spacing: 0) {
                Spacer()
                
                // Character illustration with success icon
                ZStack {
                    SDKImage("icon_male2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                    
                    // Green checkmark icon overlay
                    Circle()
                        .fill(Color.green)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                        )
                        .offset(x: 60, y: 60)
                }
                
                Spacer().frame(height: 40)
                
                // Title
                Text("E-KYC Berhasil Dilakukan!")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Spacer().frame(height: 16)
                
                // Description
                Text("Sekarang Anda akan diminta untuk mengecek kembali data E-KTP yang telah didapatkan")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Continue button
                Button(action: { continueProcess() }) {
                    Text("Selanjutnya")
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
            .background(Color.white)
            .clipShape(TopRoundedRectangle(radius: 25))
            .padding(.top, 66)
        }
    }
    
    private func continueProcess() {
        // Complete SDK flow and notify success
        CobSDKManager.shared.notifySuccess(data: [
            "status": "kyc_success",
            "message": "KYC verification completed successfully"
        ])
        NotificationCenter.default.post(name: NSNotification.Name("CobSDKDismiss"), object: nil)
    }
}

// Custom shape for top-only rounded corners
@available(iOS 13.0, *)
struct TopRoundedRectangle: Shape {
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

public class KycSuccessViewController: UIViewController {
    public var onBackPressed: (() -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            let hostingController = UIHostingController(rootView: KycSuccessView(onBackPressed: onBackPressed))
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
