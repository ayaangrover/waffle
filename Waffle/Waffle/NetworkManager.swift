import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    let baseUrl = "https://bec6d0a6-c784-416f-9c13-36065e848a92-00-j08wl6y0j2ej.kirk.replit.dev/"
    
    func fetchMessages(completion: @escaping ([String]) -> Void) {
        guard let url = URL(string: baseUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let messages = try? JSONDecoder().decode([String].self, from: data) {
                    DispatchQueue.main.async {
                        completion(messages)
                    }
                }
            }
        }.resume()
    }
    
    func sendMessage(_ message: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: baseUrl + "send/\(message)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let responseMessage = String(data: data, encoding: .utf8) {
                print(responseMessage)
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }.resume()
    }
    
    func clearMessages(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: baseUrl + "clear") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let responseMessage = String(data: data, encoding: .utf8) {
                print(responseMessage)
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }.resume()
    }
}
