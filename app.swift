import SwiftUI

@main
struct HelloWorldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("Hello, World!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Welcome to my first SwiftUI app!")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button("Get Started") {
                print("Button clicked!")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
