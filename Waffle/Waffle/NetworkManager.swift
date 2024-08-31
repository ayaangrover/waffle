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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        senderID = try container.decode(String.self, forKey: .senderID)
        roomID = try container.decode(String.self, forKey: .roomID)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        profilePictureURL = try container.decodeIfPresent(String.self, forKey: .profilePictureURL)
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
    @Published var users: [UserData] = []
    @Published var rooms: [String] = ["general"]
    @Published var currentRoomID: String = "general"
    private let baseURL = "https://waffle.ayaangrover.hackclub.app/"

    init() {
        fetchRooms()
    }

    func fetchMessages(for roomID: String) {
        guard let url = URL(string: "\(baseURL)messages?room=\(roomID)") else {
            print("Invalid URL")
            return
        }
        
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
            
            do {
                let fetchedMessages = try JSONDecoder().decode([Message].self, from: data)
                let processedMessages = fetchedMessages.map { message -> Message in
                    let cleanedContent = message.content.replacingOccurrences(of: " ", with: "")
                    if EncryptionManager.isEncrypted(cleanedContent) {
                        if let decryptedContent = EncryptionManager.decrypt(cleanedContent) {
                            return Message(id: message.id, content: decryptedContent, senderID: message.senderID, roomID: message.roomID, timestamp: message.timestamp, profilePictureURL: message.profilePictureURL)
                        } else {
                            return Message(id: message.id, content: "This message uses a different encryption. Tell this user to update their app!", senderID: message.senderID, roomID: message.roomID, timestamp: message.timestamp, profilePictureURL: message.profilePictureURL)
                        }
                    } else {
                        return message
                    }
                }
                DispatchQueue.main.async {
                    self.messages[roomID] = processedMessages
                }
            } catch {
                print("Error decoding messages: \(error)")
            }
        }.resume()
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
                              profilePictureURL: currentUser.photoURL?.absoluteString ?? "")
        
        do {
            let jsonData = try JSONEncoder().encode(message)
            request.httpBody = jsonData
        } catch {
            print("Error encoding message: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error sending message: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self?.fetchMessages(for: roomID)
            }
        }.resume()
    }
    
    func createRoom(_ name: String) {
        guard let url = URL(string: "\(baseURL)create-room") else {
            print("Invalid URL for creating room")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["roomName": name]
        
        do {
            let jsonData = try JSONEncoder().encode(body)
            request.httpBody = jsonData
        } catch {
            print("Error encoding room name: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error creating room: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self?.rooms.append(name)
                self?.currentRoomID = name
                self?.fetchMessages(for: name)
            }
        }.resume()
    }
    
    func fetchRooms() {
        guard let url = URL(string: "\(baseURL)rooms") else {
            print("Invalid URL for fetching rooms")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching rooms: \(error)")
                return
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
        let urlString = roomID != nil ? "\(baseURL)clear?room=\(roomID!)" : "\(baseURL)clear"
        guard let url = URL(string: urlString) else {
            print("Invalid URL for clearing messages")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] _, _, error in
            if let error = error {
                print("Error clearing messages: \(error)")
                return
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
    
    func getFirebaseIdToken(completion: @escaping (String?, Error?) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
            return
        }
        
        currentUser.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let token = idToken else {
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"]))
                return
            }
            
            completion(token, nil)
        }
    }
}
