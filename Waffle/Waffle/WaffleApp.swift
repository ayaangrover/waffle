import SwiftUI
import Firebase

@main
struct WaffleApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modifier(MontserratAlternatesFont(size: 16, weight: .regular))
        }
    }
}
