import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var user: User? = nil
    
    var body: some View {
        VStack {
            if isSignedIn {
                ChatView()
            } else {
                // Show the sign-in button if the user is not signed in
                Button(action: {
                    signInWithGoogle()
                }) {
                    Text("Sign in with Google")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .onAppear {
            checkCurrentUser()
        }
    }
    
    private func checkCurrentUser() {
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isSignedIn = true
        }
    }
    
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Failed to get client ID")
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: getRootViewController()) { user, error in
            if let error = error {
                print("Error during sign-in: \(error.localizedDescription)")
                return
            }
            
            guard let authentication = user?.authentication,
                  let idToken = authentication.idToken,
                  let accessToken = authentication.accessToken else {
                print("Error retrieving tokens")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error signing in with Google: \(error.localizedDescription)")
                } else {
                    // Successfully signed in
                    self.user = authResult?.user
                    self.isSignedIn = true
                }
            }
        }
    }
    
    private func getRootViewController() -> UIViewController {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.rootViewController ?? UIViewController()
    }
}

struct ChatView: View {
    @State private var messages: [String] = []
    @State private var newMessage: String = ""
    
    var body: some View {
        VStack {
            List(messages, id: \.self) { message in
                Text(message)
            }
            HStack {
                TextField("Type your message", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    sendMessage()
                }) {
                    Text("Send")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .onAppear {
            fetchMessages()
        }
    }
    
    private func fetchMessages() {
        guard let url = URL(string: "https://61c7a5a8-fbf2-442f-905d-a687daa25c71-00-1kwplgteasmdd.janeway.replit.dev/") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching messages: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let fetchedMessages = try? JSONDecoder().decode([String].self, from: data) else {
                print("Error decoding messages")
                return
            }
            
            DispatchQueue.main.async {
                self.messages = fetchedMessages
            }
        }
        
        task.resume()
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        guard let url = URL(string: "https://61c7a5a8-fbf2-442f-905d-a687daa25c71-00-1kwplgteasmdd.janeway.replit.dev/send/\(newMessage)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self.newMessage = ""
                self.fetchMessages()
            }
        }
        
        task.resume()
    }
}
