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
//                            NavigationLink(action: none) {
//                                Image(systemName: "gearshape")
//                                    .resizable()
//                                    .frame(width: 24, height: 24)
//                                    .foregroundColor(Color("Icons"))
//                            }
//                            .padding(.leading)
                            
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
                                    
                                    let processedMessage = processMessage(messageContent)
                                    
                                    let isCurrentUserMessage = isMessageFromCurrentUser(senderInfo)
                                    let shouldShowTimestamp = shouldShowTimestamp(for: index)
                                    let isFirstInGroup = isFirstInGroup(at: index)
                                    let (senderName, timestamp) = extractSenderInfoAndTimestamp(from: senderInfo)

                                    VStack(spacing: 5) {
                                        if !processedMessage.text.isEmpty || processedMessage.mediaURL != nil || processedMessage.youtubeVideoId != nil {
                                            HStack {
                                                if isCurrentUserMessage {
                                                    Spacer()
                                                    VStack(alignment: .trailing) {
                                                        HStack {
                                                            VStack(alignment: .trailing, spacing: 5) {
                                                                if !processedMessage.text.isEmpty {
                                                                    Text(processedMessage.text)
                                                                        .padding(10)
                                                                        .background(Color("Accent"))
                                                                        .foregroundColor(.white)
                                                                        .cornerRadius(20)
                                                                        .frame(maxWidth: 300, alignment: .trailing)
                                                                }
                                                                
                                                                if let mediaURL = processedMessage.mediaURL {
                                                                    MediaView(url: mediaURL, mediaType: processedMessage.mediaType)
                                                                }
                                                                
                                                                if let youtubeVideoId = processedMessage.youtubeVideoId {
                                                                    YouTubePreviewView(videoId: youtubeVideoId)
                                                                        .frame(maxWidth: 300)
                                                                }
                                                                
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
                                                    // Similar changes for messages from other users
                                                    // ...
                                                }
                                            }
                                            .padding(.horizontal)
                                            .padding(.bottom, 2)
                                        }
                                    }
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
                            .frame(width:300, height:24)
                            .cornerRadius(15)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .frame(width: 18, height: 18)
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
    
    func processMessage(_ message: String) -> ProcessedMessage {
        let cleanedMessage = removeParentheses(from: message)
        let components = cleanedMessage.components(separatedBy: .whitespacesAndNewlines)
        var text = ""
        var mediaURL: URL?
        var mediaType: ProcessedMessage.MediaType = .none
        var youtubeVideoId: String?
        
        for component in components {
            if let url = URL(string: component) {
                if isYouTubeLinkNew(url) {
                    if let videoId = extractYouTubeVideoId(from: url) {
                        youtubeVideoId = videoId
                    }
                    // Don't add the YouTube link to the text
                } else {
                    let lowercasedPath = url.pathExtension.lowercased()
                    if ["png", "jpg", "jpeg"].contains(lowercasedPath) {
                        mediaURL = url
                        mediaType = .image
                    } else if lowercasedPath == "gif" {
                        mediaURL = url
                        mediaType = .gif
                    } else if lowercasedPath == "heic" {
                        mediaURL = url
                        mediaType = .heic
                    } else {
                        text += component + " "
                    }
                }
            } else {
                text += component + " "
            }
        }
        
        // Trim any leading or trailing whitespace
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If there's a YouTube preview and the text is empty, return a ProcessedMessage with no text
        if youtubeVideoId != nil && text.isEmpty {
            return ProcessedMessage(text: "",
                                    mediaURL: mediaURL,
                                    mediaType: mediaType,
                                    youtubeVideoId: youtubeVideoId)
        }
        
        return ProcessedMessage(text: text,
                                mediaURL: mediaURL,
                                mediaType: mediaType,
                                youtubeVideoId: youtubeVideoId)
    }

    func isYouTubeLinkNew(_ url: URL) -> Bool {
        return url.host?.contains("youtube.com") == true || url.host?.contains("youtu.be") == true
    }

    func extractYouTubeVideoId(from url: URL) -> String? {
        if url.host?.contains("youtu.be") == true {
            return url.lastPathComponent
        } else if url.host?.contains("youtube.com") == true {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return videoId
            }
        }
        return nil
    }

    func isYouTubeLink(_ url: URL) -> Bool {
        return url.host?.contains("youtube.com") == true || url.host?.contains("youtu.be") == true
    }

    func fetchYouTubeInfo(from url: URL) -> YouTubeVideoInfo? {
        // This is a placeholder implementation. In a real app, you'd want to use YouTube's API
        // to fetch actual video information. For now, we'll return dummy data.
        let videoId = url.absoluteString.contains("youtu.be") ? url.lastPathComponent : URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "v" })?.value ?? ""
        return YouTubeVideoInfo(id: videoId,
                                title: "YouTube Video Title",
                                thumbnailURL: URL(string: "https://img.youtube.com/vi/\(videoId)/0.jpg")!)
    }

    func removeParentheses(from string: String) -> String {
        var result = ""
        var insideParentheses = false
        
        for char in string {
            if char == "(" {
                insideParentheses = true
            } else if char == ")" {
                insideParentheses = false
            } else if !insideParentheses {
                result.append(char)
            }
        }
        
        return result
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
        // Remove leading and trailing parentheses from the entire string
        let cleanedInfo = senderInfo.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        
        let components = cleanedInfo.components(separatedBy: "at ")
        if components.count > 1 {
            let senderName = components[0].replacingOccurrences(of: "Sent by ", with: "").trimmingCharacters(in: .whitespaces)
            let timestamp = components[1].trimmingCharacters(in: .whitespaces)
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

struct MediaView: View {
    let url: URL
    let mediaType: ProcessedMessage.MediaType
    
    var body: some View {
        Group {
            switch mediaType {
            case .image, .heic:
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Text("Failed to load image")
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
            case .gif:
                GIFView(url: url)
            case .none:
                EmptyView()
            }
        }
        .frame(maxWidth: 300, maxHeight: 300)
        .cornerRadius(20)
    }
}

struct GIFView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let source = CGImageSourceCreateWithData(data as CFData, nil) {
                let imageCount = CGImageSourceGetCount(source)
                var images = [UIImage]()
                var duration: TimeInterval = 0
                
                for i in 0..<imageCount {
                    if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                        images.append(UIImage(cgImage: image))
                    }
                    
                    if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                       let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                        if let delayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                            duration += delayTime
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    uiView.animationImages = images
                    uiView.animationDuration = duration
                    uiView.startAnimating()
                }
            }
        }
    }
}

struct ProcessedMessage {
    let text: String
    let mediaURL: URL?
    let mediaType: MediaType
    let youtubeVideoId: String?
    
    enum MediaType {
        case none, image, gif, heic
    }
}

struct YouTubePreviewView: View {
    @State private var videoInfo: YouTubeVideoInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    let videoId: String

    var body: some View {
        Group {
            if let videoInfo = videoInfo {
                Link(destination: URL(string: "https://www.youtube.com/watch?v=\(videoInfo.id)")!) {
                    HStack(alignment: .top, spacing: 10) {
                        AsyncImage(url: videoInfo.thumbnailURL) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 120, height: 90)
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(videoInfo.title)
                                .font(.caption)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                            Text("YouTube")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .frame(height: 90)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            } else if isLoading {
                ProgressView()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            loadVideoInfo()
        }
    }

    private func loadVideoInfo() {
        isLoading = true
        Task {
            do {
                videoInfo = try await YouTubeAPIManager.shared.fetchVideoInfo(id: videoId)
                isLoading = false
            } catch {
                errorMessage = "Failed to load video info"
                isLoading = false
            }
        }
    }
}

struct YouTubeVideoInfo: Identifiable {
    let id: String
    let title: String
    let thumbnailURL: URL
}
