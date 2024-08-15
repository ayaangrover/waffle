import Foundation
import Combine
import SwiftUI

class NetworkManager: ObservableObject {
    @Published var messages: [String] = []
    private let baseURL = "https://waffle.ayaangrover.hackclub.app/"

    func fetchMessages() {
        guard let url = URL(string: baseURL) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
                let processedMessages = fetchedMessages.map { message -> String in
                    if EncryptionManager.isEncrypted(message) {
                        return EncryptionManager.decrypt(message) ?? message
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
        guard let url = URL(string: baseURL + "send") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let encryptedMessage = EncryptionManager.encrypt(message) ?? message
        
        let formattedMessage = encryptedMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = "message=\(formattedMessage)"
        request.httpBody = body.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending message: \(error)")
                return
            }
            
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                print("No data received")
                return
            }
            
            print("Response from server: \(responseString)")
            
            // Fetch messages after sending to update the UI
            DispatchQueue.main.async {
                self.fetchMessages()
            }
        }
        task.resume()
    }
}
