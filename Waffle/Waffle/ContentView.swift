import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isSignedIn = false

    var body: some View {
        if isSignedIn {
            ChatView()
        } else {
            LoginView(isSignedIn: $isSignedIn)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
