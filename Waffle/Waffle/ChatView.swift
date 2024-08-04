import SwiftUI
import FirebaseAuth

struct ChatView: View {
    @State private var messages: [String] = []
    @State private var newMessage: String = ""

    var body: some View {
        VStack {
            List(messages, id: \.self) { message in
                Text(message)
            }
            HStack {
                TextField("Enter message", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    Text("Send")
                }
            }
            .padding()
        }
        .onAppear(perform: fetchMessages)
    }
    
    func fetchMessages() {
        NetworkManager.shared.fetchMessages { messages in
            self.messages = messages
        }
    }
    
    func sendMessage() {
        guard let user = Auth.auth().currentUser else { return }
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let message = "\(newMessage) - \(user.displayName ?? "Unknown") @ \(date)"
        
        NetworkManager.shared.sendMessage(message) { success in
            if success {
                self.newMessage = ""
                self.fetchMessages()
            }
        }
    }
}
