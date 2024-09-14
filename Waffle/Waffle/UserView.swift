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
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No user logged in"
            isLoading = false
            return
        }
        
        let roomID = networkManager.currentRoomID
        
        guard let url = URL(string: "\(networkManager.baseURL)room-members?roomId=\(roomID)&userId=\(currentUser.uid)") else {
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
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    let members = try JSONDecoder().decode([String].self, from: data)
                    roomMembers = members
                } catch {
                    errorMessage = "Error decoding data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
