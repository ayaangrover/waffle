import SwiftUI
import Firebase

@main
struct WaffleApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            SettingsView()
        }
    }
}
