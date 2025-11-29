import SwiftUI

@available(iOS 14.0, *)
public struct TestView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Text("Test View aaa")
                .font(.title)
                .padding()
            
            Text("This is a test screen")
                .padding()
        }
    }
}
