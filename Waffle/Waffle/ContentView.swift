import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

struct ContentView: View {
    
    @State private var user: User?
    @State private var isSignedIn = false
    @StateObject private var networkManager = NetworkManager()
    @State private var newMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Button(action: signOut) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        Text("Messages")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    .frame(height: 60) // Adjust the height of the bar
                    
                    Spacer()
                }
                .background(Color(UIColor.systemGray6))
                .frame(width: geometry.size.width, height: 120) // Extend the bar lower
                .edgesIgnoringSafeArea(.top)
            }
            .frame(height: 120) // Ensure the bar's height

            if isSignedIn {
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 10) {
                                ForEach(networkManager.messages, id: \.self) { message in
                                    MessageView(message: message, isCurrentUser: isMessageFromCurrentUser(message))
                                        .id(message) // Assign unique ID for scroll position
                                }
                            }
                            .padding(.bottom, 80) // Ensure there's space above the input bar
                            .onChange(of: networkManager.messages) { _ in
                                // Scroll to the latest message
                                if let lastMessage = networkManager.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Enter your message", text: $newMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .background(Color(UIColor.systemBackground))
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    .background(Color(UIColor.systemBackground))
                }
                .padding(.bottom, 10) // Adjust padding if needed
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
                networkManager.fetchMessages()
                Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
                    networkManager.fetchMessages()
                }
            }
        }
    }
    
    private func sendMessage() {
        guard let user = user else { return }
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        let formattedMessage = "\(trimmedMessage) \n(Sent by \(user.displayName?.components(separatedBy: " ").first ?? "User") at \(formattedCurrentDateTime()))"
        networkManager.sendMessage(formattedMessage)
        newMessage = ""
    }
    
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Failed to get client ID")
            return
        }
        
        _ = GIDConfiguration(clientID: clientID)
        
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
                    print("Full error details: \(error)")
                    return
                }
                self.user = authResult?.user
                self.isSignedIn = true
                networkManager.fetchMessages()
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isSignedIn = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    private func getRootViewController() -> UIViewController {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            fatalError("Unable to get root view controller")
        }
        return rootVC
    }
    
    private func formattedCurrentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy, h:mm a" // Excludes seconds
        return formatter.string(from: Date())
    }
    
    private func isMessageFromCurrentUser(_ message: String) -> Bool {
        guard let user = user else { return false }
        let firstName = user.displayName?.components(separatedBy: " ").first ?? ""
        return message.contains("Sent by \(firstName) at")
    }
}

struct MessageView: View {
    let message: String
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
                VStack(alignment: .trailing) {
                    Text(message)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .frame(maxWidth: 300, alignment: .trailing)
                    Text("Just now") // Placeholder for timestamp, adjust as needed
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.trailing, 5)
                }
            } else {
                VStack(alignment: .leading) {
                    Text(message)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                        .frame(maxWidth: 300, alignment: .leading)
                    Text("Just now") // Placeholder for timestamp, adjust as needed
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 5) // Adjust bottom padding to ensure messages aren't cut off
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .font(.largeTitle)
            .padding()
    }
}
