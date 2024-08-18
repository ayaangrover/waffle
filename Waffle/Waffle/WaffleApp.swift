import SwiftUI
import Firebase

@main
struct WaffleApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            UserView()
                .modifier(MontserratAlternatesFont(size: 16, weight: .regular))
        }
    }
}
