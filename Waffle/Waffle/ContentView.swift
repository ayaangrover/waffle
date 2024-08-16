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
                                    let messageParts = message.components(separatedBy: "||")
                                    let messageContent = messageParts[0]
                                    let profilePictureURL = messageParts.count > 1 ? messageParts[1] : ""
                                    let senderInfo = messageParts.count > 2 ? messageParts[2] : ""
                                    
                                    let isCurrentUserMessage = isMessageFromCurrentUser(senderInfo)
                                    let shouldShowTimestamp = shouldShowTimestamp(for: index)
                                    let isFirstInGroup = isFirstInGroup(at: index)
                                    let (senderName, timestamp) = extractSenderInfoAndTimestamp(from: senderInfo)

                                    HStack {
                                        if isCurrentUserMessage {
                                            Spacer()
                                            VStack(alignment: .trailing) {
                                                HStack {
                                                    VStack(alignment: .trailing) {
                                                        Text(messageContent)
                                                            .padding(10)
                                                            .background(Color("Accent"))
                                                            .foregroundColor(.white)
                                                            .cornerRadius(20)
                                                            .frame(maxWidth: 300, alignment: .trailing)
                                                        if shouldShowTimestamp {
                                                            Text("\(senderName) • \(timestamp)")
                                                                .font(.caption)
                                                                .foregroundColor(.gray)
                                                                .padding(.trailing, 5)
                                                        }
                                                    }
                                                    if isFirstInGroup {
                                                        ProfileImageView(imageURL: profilePictureURL)
                                                    }
                                                }
                                            }
                                        } else {
                                            HStack {
                                                if isFirstInGroup {
                                                    ProfileImageView(imageURL: profilePictureURL)
                                                }
                                                VStack(alignment: .leading) {
                                                    Text(messageContent)
                                                        .padding(10)
                                                        .background(Color.gray.opacity(0.2))
                                                        .cornerRadius(20)
                                                        .frame(maxWidth: 300, alignment: .leading)
                                                    if shouldShowTimestamp {
                                                        Text("\(senderName) • \(timestamp)")
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
                            .frame(width:100, height:24)
                            .cornerRadius(15)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color("Accent"))
                                .clipShape(Circle())
                            .frame(width: 12, height: 12)
                        }
                        .padding()
                    }
                    .background(Color(UIColor.systemBackground))
                }
                .padding(.bottom, 5)
            } else {
                LoginView(signInAction: signInWithGoogle)
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
        
        // Get the user's profile picture URL
        let profilePictureURL = user.photoURL?.absoluteString ?? ""
        
        let formattedMessage = "\(trimmedMessage)||\(profilePictureURL)||(Sent by \(user.displayName?.components(separatedBy: " ").first ?? "User") at \(formattedCurrentDateTime()))"
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
    
    private func isMessageFromCurrentUser(_ senderInfo: String) -> Bool {
        guard let user = user else { return false }
        let firstName = user.displayName?.components(separatedBy: " ").first ?? ""
        return senderInfo.contains("Sent by \(firstName) at")
    }

    private func extractTimestamp(from senderInfo: String) -> String {
        let components = senderInfo.components(separatedBy: "at ")
        if components.count > 1 {
            var timestamp = components[1].trimmingCharacters(in: .whitespaces)
            // Remove the trailing parenthesis
            if timestamp.hasSuffix(")") {
                timestamp = String(timestamp.dropLast())
            }
            return timestamp
        }
        return ""
    }
    
    private func extractSenderInfoAndTimestamp(from senderInfo: String) -> (String, String) {
        let components = senderInfo.components(separatedBy: "at ")
        if components.count > 1 {
            let senderName = components[0].replacingOccurrences(of: "Sent by ", with: "").trimmingCharacters(in: .whitespaces)
            var timestamp = components[1].trimmingCharacters(in: .whitespaces)
            // Remove the trailing parenthesis
            if timestamp.hasSuffix(")") {
                timestamp = String(timestamp.dropLast())
            }
            return (senderName, timestamp)
        }
        return ("", "")
    }

    private func isFirstInGroup(at index: Int) -> Bool {
        if index == 0 { return true }
        let previousMessage = networkManager.messages[index - 1].components(separatedBy: "||")
        let currentMessage = networkManager.messages[index].components(separatedBy: "||")
        let previousSenderInfo = previousMessage.count > 2 ? previousMessage[2] : ""
        let currentSenderInfo = currentMessage.count > 2 ? currentMessage[2] : ""
        return isMessageFromCurrentUser(previousSenderInfo) != isMessageFromCurrentUser(currentSenderInfo)
    }
    
    private func extractProfilePictureURL(_ message: String) -> String {
        let components = message.components(separatedBy: " (Sent by ")
        guard components.count > 1 else { return "" }
        let urlAndTimestamp = components[0].components(separatedBy: " ")
        guard urlAndTimestamp.count > 1 else { return "" }
        return urlAndTimestamp.last ?? ""
    }
}

struct ProfileImageView: View {
    let imageURL: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
            } else {
                Circle().fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = URL(string: imageURL) else {
            print("Invalid URL for profile image")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            } else {
                print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
}

struct LoginView: View {
    let signInAction: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Image("WaffleFull")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
            
            Button(action: signInAction) {
                HStack {
                    Image("GoogleLogo") // Make sure to add this asset to your project
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                    
                    Text("Sign in with Google")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .montserratAlternates(18, weight: .bold)
                }
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(Color("Accent"))
                .cornerRadius(800)
            }
            .padding(.horizontal, 50)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color("Background"))
        .edgesIgnoringSafeArea(.all)
    }
}
