import SwiftUI
import UIKit

@available(iOS 14.0, *)
public struct ProsesView: View {
    @State private var isAnimating = false
    public let onBackPressed: (() -> Void)?
    
    public init(onBackPressed: (() -> Void)? = nil) {
        self.onBackPressed = onBackPressed
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Character on rocket illustration
            VStack(spacing: 40) {
                // Icon from asset
                SDKImage("icon_intro2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                
                // Loading spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                
                // Process text
                Text("Sedang Dalam Proses...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .background(Color.white)
        .onAppear {
            // Simulate process completion after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Navigate to next screen or complete process
                completeProcess()
            }
        }
    }
    
    private func completeProcess() {
        // Handle process completion
        print("Process completed")
        // You can navigate to the next screen here
    }
}

public class ProsesViewController: UIViewController {
    public var onBackPressed: (() -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            let hostingController = UIHostingController(rootView: ProsesView(onBackPressed: onBackPressed))
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
