import SwiftUI
import FirebaseCore
import Firebase
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn

struct ContentView: View {
    @State private var profileImages: [String: UIImage] = [:]
    @State private var user: User?
    @State private var isSignedIn = false
    @StateObject private var networkManager = NetworkManager()
    @State private var newMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if isSignedIn {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        Spacer().frame(height: 90)
                        
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
                                .padding(.bottom, 5)
                            
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
                        .frame(height: 50)
                        
                        Spacer()
                    }
                    .background(Color("Background"))
                    .frame(width: geometry.size.width, height: 70)
                    .edgesIgnoringSafeArea(.top)
                }
                .frame(height: 70)
                
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 10) {
                                ForEach(0..<networkManager.messages.count, id: \.self) { index in
                                    let message = networkManager.messages[index]
                                    let isCurrentUserMessage = isMessageFromCurrentUser(message)
                                    let shouldShowTimestamp = shouldShowTimestamp(for: index)
                                    let isFirstInGroup = isFirstInGroup(at: index)

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
                                                    if isFirstInGroup {
                                                        ProfileImageView(email: extractEmailFromMessage(message) ?? "", profileImages: $profileImages)
                                                    }
                                                }
                                            }
                                        } else {
                                            HStack {
                                                if isFirstInGroup {
                                                    ProfileImageView(email: extractEmailFromMessage(message) ?? "", profileImages: $profileImages)
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
                                    .padding(.bottom, 2)
                                    .id(message)
                                }
                            }
                            .padding(.bottom, 10)
                            .onChange(of: networkManager.messages) { _ in
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
                .padding(.bottom, 5)
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
        guard let user = user else {
            print("Cannot send message: User is not signed in")
            return
        }
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        let formattedMessage = "\(trimmedMessage) \n(Sent by \(user.displayName?.components(separatedBy: " ").first ?? "User") at \(formattedCurrentDateTime()))"
        networkManager.sendMessage(formattedMessage)
        newMessage = ""
    }
    
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("There is no root view controller!")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Error: ID token missing")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
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
    
    private func formattedCurrentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy, h:mm a"
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
        
        if index < networkManager.messages.count - 1 {
            let nextMessage = networkManager.messages[index + 1]
            let isNextMessageFromSameUser = isMessageFromCurrentUser(nextMessage) == isCurrentUserMessage
            return !isNextMessageFromSameUser
        }
        
        return true
    }
    
    private func isFirstInGroup(at index: Int) -> Bool {
        if index == 0 { return true }
        let previousMessage = networkManager.messages[index - 1]
        let currentMessage = networkManager.messages[index]
        return isMessageFromCurrentUser(previousMessage) != isMessageFromCurrentUser(currentMessage)
    }
    
    private func extractEmailFromMessage(_ message: String) -> String? {
        let components = message.components(separatedBy: "Sent by ")
        guard components.count > 1 else { return nil }
        let nameAndTimestamp = components[1].components(separatedBy: " at ")
        guard nameAndTimestamp.count > 0 else { return nil }
        let name = nameAndTimestamp[0]
        return "\(name.lowercased())@example.com"
    }
}

struct ProfileImageView: View {
    let email: String
    @Binding var profileImages: [String: UIImage]

    var body: some View {
        Group {
            if let image = profileImages[email] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
            } else {
                Circle().fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .onAppear {
                        fetchProfileImage()
                    }
            }
        }
    }

    private func fetchProfileImage() {
        guard !email.isEmpty else {
            print("Email is empty, cannot fetch profile image")
            return
        }
        
        let docRef = Firestore.firestore().collection("users").document(email)
        
        docRef.getDocument { document, error in
            if let error = error {
                print("Error fetching profile image: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists,
               let base64String = document.data()?["image"] as? String,
               let imageData = Data(base64Encoded: base64String),
               let image = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.profileImages[email] = image
                }
            } else {
                print("No profile image found for email: \(email). Using default image.")
                DispatchQueue.main.async {
                    self.profileImages[email] = UIImage(systemName: "person.circle.fill")
                }
            }
        }
    }
}
