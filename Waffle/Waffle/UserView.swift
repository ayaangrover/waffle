import SwiftUI
import FirebaseAuth

struct UserView: View {
    @EnvironmentObject private var networkManager: NetworkManager
    @State private var roomMembers: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    List(roomMembers, id: \.self) { email in
                        Text(email)
                    }
                }
            }
            .navigationTitle("Room Members")
        }
        .onAppear(perform: fetchRoomMembers)
    }
    
    private func fetchRoomMembers() {
        guard let currentUser = Auth.auth().currentUser,
              let userEmail = currentUser.email,
              let encodedEmail = userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            errorMessage = "No user logged in or invalid email"
            isLoading = false
            return
        }
        
        let roomID = networkManager.currentRoomID
        
        guard let url = URL(string: "\(networkManager.baseURL)room-members?roomId=\(roomID)&userEmail=\(encodedEmail)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response"
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data else {
                        errorMessage = "No data received"
                        return
                    }
                    
                    do {
                        // Add debug print to see the raw JSON data
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("Received JSON: \(jsonString)")
                        }
                        
                        let members = try JSONDecoder().decode([String].self, from: data)
                        roomMembers = members
                    } catch {
                        errorMessage = "Error while decoding data: \(error.localizedDescription)"
                        // Add more detailed error information
                        print("Decoding error: \(error)")
                    }
                case 403:
                    errorMessage = "You are not authorized to view members of this room"
                case 404:
                    errorMessage = "Room not found"
                default:
                    errorMessage = "Unexpected error: HTTP \(httpResponse.statusCode)"
                }
            }
        }.resume()
    }
}
