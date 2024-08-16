import Foundation
import Combine
import SwiftUI

class NetworkManager: ObservableObject {
    @Published var messages: [String] = []
    private let baseURL = "https://waffle.ayaangrover.hackclub.app/"

    func fetchMessages() {
        guard let url = URL(string: baseURL) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching messages: \(error)")
                return
            }
            
            // Debugging
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let fetchedMessages = try JSONDecoder().decode([String].self, from: data)
                        let processedMessages = fetchedMessages.compactMap { message -> String? in
                            print("Processing message: \(message)")
                            // Remove any spaces that might have been added
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
}
