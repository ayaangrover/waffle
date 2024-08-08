import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

struct ContentView: View {
    
    @State private var user: User?
    @State private var isSignedIn = false

    var body: some View {
        VStack {
            if isSignedIn {
                Text("Welcome, \(user?.displayName ?? "User")!")
            } else {
                Button("Sign In with Google") {
                    signInWithGoogle()
                }
            }
        }
        .onAppear {
            if let currentUser = Auth.auth().currentUser {
                self.user = currentUser
                self.isSignedIn = true
            }
        }
    }
    
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Failed to get client ID")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
            if let error = error {
                print("Error during sign-in: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Error retrieving tokens")
                return
            }
            let accessToken = user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error signing in with Google: \(error.localizedDescription)")
                } else {
                    self.user = authResult?.user
                    self.isSignedIn = true
                }
            }
        }
    }
    
    private func getRootViewController() -> UIViewController {
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("Unable to get root view controller")
        }
        return rootVC
    }
}
