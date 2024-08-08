import Foundation
import Combine

class NetworkManager: ObservableObject {
    @Published var messages: [String] = []
    private let baseURL = "https://bec6d0a6-c784-416f-9c13-36065e848a92-00-j08wl6y0j2ej.kirk.replit.dev/"

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
                let messages = try JSONDecoder().decode([String].self, from: data)
                DispatchQueue.main.async {
                    self.messages = messages
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
        
        let formattedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
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
        }
        task.resume()
    }
}
