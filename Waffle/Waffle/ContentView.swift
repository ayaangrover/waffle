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
            // Top Bar (only show when signed in)
            if isSignedIn {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        Spacer().frame(height: 90) // Spacing above the bar
                        
                        HStack {
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color("Icons"))
                            }
                            .padding(.leading)
                            
                            Spacer()
                            
                            Text("Messages")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 5) // Center text vertically
                            
                            Spacer()
                            
                            Button(action: signOut) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color("Icons"))
                            }
                            .padding(.trailing)
                        }
                        .padding(.horizontal)
                        .frame(height: 50) // Height of the bar
                        
                        Spacer()
                    }
                    .background(Color("Background"))
                    .frame(width: geometry.size.width, height: 70) // Adjusted height of the grey bar
                    .edgesIgnoringSafeArea(.top)
                }
                .frame(height: 70) // Ensure the bar's height matches
            }
            
            if isSignedIn {
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 10) {
                                ForEach(0..<networkManager.messages.count, id: \.self) { index in
                                    let message = networkManager.messages[index]
                                    let isCurrentUserMessage = isMessageFromCurrentUser(message)
                                    let shouldShowTimestamp = shouldShowTimestamp(for: index)
                                    
                                    HStack {
                                        if isCurrentUserMessage {
                                            Spacer()
                                            VStack(alignment: .trailing) {
                                                HStack {
                                                    VStack(alignment: .trailing) {
                                                        Text(messageWithoutLastParentheses(message))
                                                            .padding(10)
                                                            .background(Color("Accent"))
                                                            .foregroundColor(.white)
                                                            .cornerRadius(20)
                                                            .frame(maxWidth: 300, alignment: .trailing)
                                                        if shouldShowTimestamp, let timestamp = extractLastParenthesesContent(from: message) {
                                                            Text(timestamp)
                                                                .font(.caption)
                                                                .foregroundColor(.gray)
                                                                .padding(.trailing, 5)
                                                        }
                                                    }
                                                    if let profileImageURL = user?.photoURL {
                                                        AsyncImage(url: profileImageURL) { image in
                                                            image.resizable()
                                                                 .aspectRatio(contentMode: .fill)
                                                                 .clipShape(Circle())
                                                        } placeholder: {
                                                            Circle().fill(Color.gray)
                                                        }
                                                        .frame(width: 40, height: 40)
                                                    }
                                                }
                                            }
                                        } else {
                                            HStack {
                                                if let profileImageURL = extractProfileImageURL(from: message) {
                                                    AsyncImage(url: profileImageURL) { image in
                                                        image.resizable()
                                                             .aspectRatio(contentMode: .fill)
                                                             .clipShape(Circle())
                                                    } placeholder: {
                                                        Circle().fill(Color.gray)
                                                    }
                                                    .frame(width: 40, height: 40)
                                                }
                                                VStack(alignment: .leading) {
                                                    Text(messageWithoutLastParentheses(message))
                                                        .padding(10)
                                                        .background(Color.gray.opacity(0.2))
                                                        .cornerRadius(20)
                                                        .frame(maxWidth: 300, alignment: .leading)
                                                    if shouldShowTimestamp, let timestamp = extractLastParenthesesContent(from: message) {
                                                        Text(timestamp)
                                                            .font(.caption)
                                                            .foregroundColor(.gray)
                                                            .padding(.leading, 5)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 2) // Adjust bottom padding
                                    .id(message) // Assign unique ID for scroll position
                                }
                            }
                            .padding(.bottom, 10) // Ensure space above input bar
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
                            .frame(height:24)
                            .cornerRadius(15)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color("Accent"))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    .background(Color(UIColor.systemBackground))
                }
                .padding(.bottom, 5) // Adjust padding if needed
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
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                    networkManager.fetchMessages()
                }
            }
        }
    }
    
    private func sendMessage() {
        guard let user = user else { return }
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Create a message string without the URL
//        let formattedMessage = "\(trimmedMessage) \n(Sent by \(user.displayName?.components(separatedBy: " ").first ?? "User") at \(formattedCurrentDateTime()))"
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
    
    private func extractLastParenthesesContent(from message: String) -> String? {
        guard let lastOpenParenIndex = message.lastIndex(of: "("),
              let lastCloseParenIndex = message.lastIndex(of: ")"),
              lastOpenParenIndex < lastCloseParenIndex else {
            return nil
        }
        let startIndex = message.index(after: lastOpenParenIndex)
        let endIndex = lastCloseParenIndex
        return String(message[startIndex..<endIndex])
    }
    
    private func messageWithoutLastParentheses(_ message: String) -> String {
        guard let lastOpenParenIndex = message.lastIndex(of: "("),
              let lastCloseParenIndex = message.lastIndex(of: ")"),
              lastOpenParenIndex < lastCloseParenIndex else {
            return message
        }
        return String(message[..<lastOpenParenIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func shouldShowTimestamp(for index: Int) -> Bool {
        guard index < networkManager.messages.count else { return false }
        
        let message = networkManager.messages[index]
        let isCurrentUserMessage = isMessageFromCurrentUser(message)
        
        // Check if the next message is from a different user
        if index < networkManager.messages.count - 1 {
            let nextMessage = networkManager.messages[index + 1]
            let isNextMessageFromSameUser = isMessageFromCurrentUser(nextMessage) == isCurrentUserMessage
            return !isNextMessageFromSameUser
        }
        
        // Always show timestamp for the last message
        return true
    }
    
    private func extractProfileImageURL(from message: String) -> URL? {
        guard let urlString = extractLastParenthesesContent(from: message), let url = URL(string: urlString) else {
            return nil
        }
        return url
    }

}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        if hex.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
