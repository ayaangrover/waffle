import Foundation
import Combine
import SwiftUI
import FirebaseAuth

struct UserData: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let profileImageURL: String
}

public struct Message: Identifiable, Codable, Equatable {
    public let id: String
    public let content: String
    public let senderID: String
    public let roomID: String
    public let timestamp: Date
    public let profilePictureURL: String?
    public var isFirstInGroup: Bool = false
    public var isLastInGroup: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, content, senderID, roomID, timestamp, profilePictureURL
    }
    
    public init(id: String, content: String, senderID: String, roomID: String, timestamp: Date, profilePictureURL: String?) {
        self.id = id
        self.content = content
        self.senderID = senderID
        self.roomID = roomID
        self.timestamp = timestamp
        self.profilePictureURL = profilePictureURL
    }
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.content == rhs.content &&
               lhs.senderID == rhs.senderID &&
               lhs.roomID == rhs.roomID &&
               lhs.timestamp == rhs.timestamp &&
               lhs.profilePictureURL == rhs.profilePictureURL
    }
}

public class NetworkManager: ObservableObject {
    @Published var messages: [String: [Message]] = [:]
    @Published var users: [String: UserData] = [:]
    @Published var rooms: [String] = []
    @Published var currentRoomID: String = "General"
    public let baseURL = "https://71cdac9f-034e-45b9-a14e-a52eced71d28-00-4iave9rzd7yu.worf.replit.dev/"

    init() {
        fetchRooms()
    }
    
    func fetchUsers() {
        guard let url = URL(string: "\(baseURL)users") else {
            print("Invalid URL for fetching users")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Fetch users status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received when fetching users")
                return
            }
            
            do {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Received JSON: \(jsonString)")
                }
                
                let fetchedUsers = try JSONDecoder().decode([String: UserData].self, from: data)
                DispatchQueue.main.async {
                    self?.users = fetchedUsers
                }
            } catch {
                print("Error decoding users: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context)")
                    case .keyNotFound(let key, let context):
                        print("Key '\(key)' not found: \(context)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch for type \(type): \(context)")
                    case .valueNotFound(let type, let context):
                        print("Value of type \(type) not found: \(context)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
            }
        }.resume()
    }
    
    public func editRoomMembers(roomID: String, newMembers: [String]) {
        guard let currentUser = Auth.auth().currentUser,
              let url = URL(string: "\(baseURL)edit-room-members") else {
            print("Invalid URL for editing room members or no user logged in")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "roomId": roomID,
            "userEmail": currentUser.email ?? "",
            "newMemberEmails": newMembers
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error encoding room member data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error editing room members: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Room members update status code: \(httpResponse.statusCode)")
            }
            
            print("Room members updated successfully")
        }.resume()
    }
    
    func fetchMessages(for roomID: String) {
        guard let currentUser = Auth.auth().currentUser,
              let userEmail = currentUser.email,
              let encodedEmail = userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)messages?room=\(roomID)&userEmail=\(encodedEmail)&userId=\(currentUser.uid)") else {
            print("Invalid URL, no user logged in, or missing email")
            return
        }
        
        print("Fetching messages for roomID: \(roomID), userID: \(currentUser.uid), userEmail: \(userEmail)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching messages: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Fetch messages status code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 403 {
                    print("Authorization error: User not authorized to access this room")
                    DispatchQueue.main.async {
                        self.messages[roomID] = []
                        NotificationCenter.default.post(name: .authorizationErrorNotification, object: nil)
                    }
                    return
                }
            }
            
            do {
                let fetchedMessages = try JSONDecoder().decode([Message].self, from: data)
                let processedMessages = fetchedMessages.map { message -> Message in
                    let cleanedContent = message.content.replacingOccurrences(of: " ", with: "")
                    if EncryptionManager.isEncrypted(cleanedContent) {
                        if let decryptedContent = EncryptionManager.decrypt(cleanedContent) {
                            return Message(id: message.id,
                                           content: decryptedContent,
                                           senderID: message.senderID,
                                           roomID: message.roomID,
                                           timestamp: message.timestamp,
                                           profilePictureURL: message.profilePictureURL)
                        } else {
                            return Message(id: message.id,
                                           content: "This message uses a different encryption. Tell this user to update their app!",
                                           senderID: message.senderID,
                                           roomID: message.roomID,
                                           timestamp: message.timestamp,
                                           profilePictureURL: message.profilePictureURL)
                        }
                    } else {
                        return message
                    }
                }
                let groupedMessages = self.groupMessages(processedMessages)
                DispatchQueue.main.async {
                    self.messages[roomID] = groupedMessages
                }
            } catch {
                print("Error decoding messages: \(error)")
                if let errorMessage = String(data: data, encoding: .utf8) {
                    print("Server error message: \(errorMessage)")
                }
            }
        }.resume()
    }
    
    func groupMessages(_ messages: [Message]) -> [Message] {
        var groupedMessages: [Message] = []
        var currentSenderID: String?
        
        for (index, message) in messages.enumerated() {
            var updatedMessage = message
            
            if message.senderID != currentSenderID {
                updatedMessage.isFirstInGroup = true
                currentSenderID = message.senderID
            }
            
            if index == messages.count - 1 || messages[index + 1].senderID != currentSenderID {
                updatedMessage.isLastInGroup = true
            }
            
            groupedMessages.append(updatedMessage)
        }
        
        return groupedMessages
    }
    
    func sendMessage(_ content: String, to roomID: String) {
        guard let url = URL(string: "\(baseURL)send") else {
            print("Invalid URL for sending message")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encryptedContent = EncryptionManager.encrypt(content) ?? content
        
        guard let currentUser = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        let message = Message(id: UUID().uuidString,
                              content: encryptedContent,
                              senderID: currentUser.uid,
                              roomID: roomID,
                              timestamp: Date(),
                              profilePictureURL: currentUser.photoURL?.absoluteString)
        
        do {
            let jsonData = try JSONEncoder().encode(message)
            request.httpBody = jsonData
            
            print("Sending message to room: \(roomID)")
            print("Message content: \(content)")
            print("Encrypted content: \(encryptedContent)")
        } catch {
            print("Error encoding message: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error sending message: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Send message status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Server response: \(responseString)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self?.fetchMessages(for: roomID)
            }
        }.resume()
    }
    
    func createRoom(_ name: String, members: [String]) {
        guard let url = URL(string: "\(baseURL)create-room"),
              let currentUser = Auth.auth().currentUser,
              let currentUserEmail = currentUser.email else {
            print("Invalid URL for creating room or no user logged in")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ensure the creator is always included in the member list
        var allMembers = Set(members)
        allMembers.insert(currentUserEmail)
        
        let body: [String: Any] = [
            "roomName": name,
            "creatorEmail": currentUserEmail,
            "memberEmails": Array(allMembers)
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error encoding room data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error creating room: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Create room status code: \(httpResponse.statusCode)")
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Server response for room creation: \(responseString)")
            }
            
            DispatchQueue.main.async {
                self?.rooms.append(name)
                self?.currentRoomID = name
                self?.fetchMessages(for: name)
            }
        }.resume()
    }
    
    func registerUser() {
            guard let currentUser = Auth.auth().currentUser,
                  let url = URL(string: "\(baseURL)register-user") else {
                print("Invalid URL for registering user or no user logged in")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["userId": currentUser.uid, "email": currentUser.email ?? ""]

            do {
                let jsonData = try JSONEncoder().encode(body)
                request.httpBody = jsonData
            } catch {
                print("Error encoding user data: \(error)")
                return
            }

            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("Error registering user: \(error)")
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("Register user status code: \(httpResponse.statusCode)")
                }
            }.resume()
        }
    
    func fetchRooms() {
        guard let currentUser = Auth.auth().currentUser,
              let url = URL(string: "\(baseURL)rooms?userEmail=\(currentUser.email ?? "")") else {
            print("Invalid URL for fetching rooms or no user logged in")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching rooms: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Fetch rooms status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("No data received when fetching rooms")
                return
            }
            
            do {
                let fetchedRooms = try JSONDecoder().decode([String].self, from: data)
                DispatchQueue.main.async {
                    self?.rooms = fetchedRooms
                }
            } catch {
                print("Error decoding rooms: \(error)")
            }
        }.resume()
    }
    
    func joinRoom(_ roomID: String) {
        currentRoomID = roomID
        fetchMessages(for: roomID)
    }
    
    func clearMessages(in roomID: String? = nil) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        let urlString = roomID != nil ? "\(baseURL)clear?room=\(roomID!)&userId=\(currentUser.uid)" : "\(baseURL)clear?userId=\(currentUser.uid)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL for clearing messages")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] _, response, error in
            if let error = error {
                print("Error clearing messages: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Clear messages status code: \(httpResponse.statusCode)")
            }
            
            DispatchQueue.main.async {
                if let roomID = roomID {
                    self?.messages[roomID] = []
                } else {
                    self?.messages = [:]
                }
            }
        }.resume()
    }
    
    func checkRoomMembership(roomID: String, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser,
              let url = URL(string: "\(baseURL)room-members?roomId=\(roomID)&userEmail=\(currentUser.email ?? "")") else {
            print("Invalid URL for checking room membership")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error checking room membership: \(error)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Check room membership status code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }.resume()
    }
}

extension Notification.Name {
    static let authorizationErrorNotification = Notification.Name("authorizationErrorNotification")
}
