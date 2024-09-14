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
    @State private var showRoomCreationView = false
    @State private var showRoomMemberEditView = false
    @State private var showUserView = false
    @State private var newRoomName = ""
    @State private var newRoomMembers = ""
    @State private var editingRoomID = ""
    @State private var navigationPath = NavigationPath()
    @State private var showAuthorizationError = false
    

    var body: some View {
        VStack(spacing: 0) {
            if isSignedIn {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        Spacer().frame(height: 90)
                        
                        HStack {
                            Button(action: {
                                showUserView = true
                            }) {
                                Image(systemName: "person")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color("Icons"))
                            }
                            .padding(.leading)
                            
                            Spacer()
                            
                            Text(networkManager.currentRoomID)
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
                                ForEach(networkManager.messages[networkManager.currentRoomID] ?? []) { message in
                                    let processedMessage = processMessage(message.content)
                                    
                                    let isCurrentUserMessage = message.senderID == user?.uid
                                    
                                    VStack(spacing: 5) {
                                        if !processedMessage.text.isEmpty || processedMessage.mediaURL != nil || processedMessage.youtubeVideoId != nil {
                                            HStack(alignment: .top) {
                                                if !isCurrentUserMessage {
                                                    ProfileImageView(imageURL: message.profilePictureURL!)
                                                }
                                                if isCurrentUserMessage {
                                                    Spacer()
                                                }
                                                VStack(alignment: isCurrentUserMessage ? .trailing : .leading) {
                                                    MessageContentView(
                                                        processedMessage: processedMessage,
                                                        senderName: message.senderID,
                                                        timestamp: formatTimestamp(message.timestamp),
                                                        isCurrentUser: isCurrentUserMessage
                                                    )
                                                    
                                                    Text("\(formatTimestamp(message.timestamp))")
                                                        .font(.caption)
                                                        .foregroundColor((Color("Grey")))
                                                }
                                                if !isCurrentUserMessage {
                                                    Spacer()
                                                }
                                                
                                                if isCurrentUserMessage {
                                                    ProfileImageView(imageURL: message.profilePictureURL!)
                                                }
                                            }
                                            .padding(.horizontal)
                                            .padding(.bottom, 2)
                                        }
                                    }
                                    .id(message.id)
                                }
                            }
                            .padding(.bottom, 10)
                            .onChange(of: networkManager.messages[networkManager.currentRoomID]) { messages in
                                if let lastMessage = messages?.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
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
                
                HStack {
                    Menu {
                        ForEach(networkManager.rooms, id: \.self) { room in
                            Button(action: {
                                networkManager.joinRoom(room)
                            }) {
                                Text(room)
                            }
                        }
                        
                        Button(action: {
                            showRoomCreationView = true
                        }) {
                            Text("Create New Room")
                        }
                    } label: {
                        Text("Rooms")
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        showRoomMemberEditView = true
                        editingRoomID = networkManager.currentRoomID
                    }) {
                        Text("Edit Members")
                    }
                    .padding()
                }
            } else {
                LoginView(signInAction: signInWithGoogle)
            }
        }
        .onAppear {
            if let currentUser = Auth.auth().currentUser {
                print("Logged in, fetching messages...")
                self.user = currentUser
                self.isSignedIn = true
                networkManager.fetchRooms()
                networkManager.fetchMessages(for: networkManager.currentRoomID)
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                    networkManager.fetchMessages(for: networkManager.currentRoomID)
                }
            }
            NotificationCenter.default.addObserver(forName: .authorizationErrorNotification, object: nil, queue: .main) { _ in
                    self.showAuthorizationError = true
                }
        }
        .alert(isPresented: $showAuthorizationError) {
            Alert(
                title: Text("Authorization Error"),
                message: Text("You are not authorized to access this room. Please check your room membership."),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showUserView) {
            UserView().environmentObject(networkManager)
        }
        .sheet(isPresented: $showRoomCreationView) {
                    VStack {
                        TextField("Enter room name", text: $newRoomName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        TextField("Enter member emails (comma-separated)", text: $newRoomMembers)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button("Create Room") {
                            if !newRoomName.isEmpty {
                                let memberList = newRoomMembers.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                networkManager.createRoom(newRoomName, members: memberList)
                                newRoomName = ""
                                newRoomMembers = ""
                                showRoomCreationView = false
                            }
                        }
                        .padding()
                    }
                }
            .sheet(isPresented: $showRoomMemberEditView) {
                    VStack {
                        TextField("Enter new member emails (comma-separated)", text: $newRoomMembers)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button("Update Members") {
                            let memberList = newRoomMembers.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                            networkManager.editRoomMembers(roomID: editingRoomID, newMembers: memberList)
                            newRoomMembers = ""
                            showRoomMemberEditView = false
                        }
                        .padding()
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
        
        networkManager.sendMessage(newMessage, to: networkManager.currentRoomID)
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
                networkManager.fetchMessages(for: networkManager.currentRoomID)
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
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy, h:mm a"
        return formatter.string(from: date)
    }
    
    private func formattedCurrentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy, h:mm a"
        return formatter.string(from: Date())
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
                Circle().fill(Color("Grey"))
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
                    Image("GoogleLogo")
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
                            Rectangle().fill(Color("Accent").opacity(0.3))
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
                    .background(Color("Accent").opacity(0.1))
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

struct MessageContentView: View {
    let processedMessage: ProcessedMessage
    let senderName: String
    let timestamp: String
    let isCurrentUser: Bool
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading) {
            if !processedMessage.text.isEmpty {
                Text(processedMessage.text)
                    .padding(10)
                    .background(isCurrentUser ? Color("Accent") : Color("Grey"))
                    .foregroundColor(.white)
                    .cornerRadius(50)
            }
            
            if let mediaURL = processedMessage.mediaURL {
                MediaView(url: mediaURL, mediaType: processedMessage.mediaType)
            }
            
            if let youtubeVideoId = processedMessage.youtubeVideoId {
                YouTubePreviewView(videoId: youtubeVideoId)
            }
        }
    }
}
