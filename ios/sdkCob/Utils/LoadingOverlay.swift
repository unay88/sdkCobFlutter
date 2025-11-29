import SwiftUI

@available(iOS 14.0, *)
struct LoadingOverlay: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Custom arc spinner
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                
                Text(message)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0x13/255.0, green: 0x4b/255.0, blue: 0x70/255.0))
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
}