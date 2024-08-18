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

class NetworkManager: ObservableObject {
    @Published var messages: [String] = []
    @Published var users: [UserData] = []
    private let baseURL = "https://waffle.ayaangrover.hackclub.app/"
    private let adminBaseURL = "https://waffle-admin.ayaangrover.hackclub.app/"


    func fetchMessages() {
        guard let url = URL(string: baseURL) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
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
                let fetchedMessages = try JSONDecoder().decode([String].self, from: data)
                let processedMessages = fetchedMessages.compactMap { message -> String? in
                    print("Processing message: \(message)")
                    let cleanedMessage = message.replacingOccurrences(of: " ", with: "")
                    if EncryptionManager.isEncrypted(cleanedMessage) {
                        if let decryptedMessage = EncryptionManager.decrypt(cleanedMessage) {
                            print("Successfully decrypted: \(decryptedMessage)")
                            return decryptedMessage
                        } else {
                            print("Failed to decrypt message: \(cleanedMessage)")
                            return "This message uses a different message encryption. Tell this user to update their app!"
                        }
                    } else {
                        return message
                    }
                }
                DispatchQueue.main.async {
                    self.messages = processedMessages
                    print("Updated messages: \(self.messages)")
                }
            } catch {
                print("Error decoding messages: \(error)")
            }
        }
        task.resume()
    }
    
    func sendMessage(_ message: String) {
        guard let url = URL(string: baseURL + "send") else {
            print("Invalid URL for sending message")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Encryption
        let encryptedMessage = EncryptionManager.encrypt(message) ?? message
        print("Original message: \(message)")
        print("Encrypted message: \(encryptedMessage)")

        // This makes sure the message is ready for encryption.
        // It also ensures there are no discrepancies between what is sent and what is recieved.
        let formattedMessage = encryptedMessage
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = "message=\(formattedMessage)"
        request.httpBody = body.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending message: \(error)")
                return
            }
            
            // Debugging
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                print("No data received from send request")
                return
            }
            
            print("Response from server: \(responseString)")
            
            DispatchQueue.main.async {
                self.fetchMessages()
            }
        }
        task.resume()
    }
    
    func fetchUsers() {
        guard let url = URL(string: adminBaseURL + "users") else {
            print("Invalid URL for fetching users")
            return
        }
        
        getFirebaseIdToken { [weak self] (idToken, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting Firebase ID token: \(error)")
                return
            }
            
            guard let idToken = idToken else {
                print("No ID token received")
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error fetching users: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received when fetching users")
                    return
                }
                
                do {
                    let fetchedUsers = try JSONDecoder().decode([UserData].self, from: data)
                    DispatchQueue.main.async {
                        self.users = fetchedUsers
                    }
                } catch {
                    print("Error decoding users: \(error)")
                }
            }
            task.resume()
        }
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
