import SwiftUI

struct NewsletterView: View {
    @State private var email = ""
    @State private var isSubscribing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Subscribe to Our Newsletter")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Enter your email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal)
            
            Button(action: subscribeToNewsletter) {
                if isSubscribing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Subscribe")
                }
            }
            .frame(minWidth: 200)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(email.isEmpty || isSubscribing)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Subscription Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func subscribeToNewsletter() {
        guard !email.isEmpty else { return }
        
        isSubscribing = true
        
        guard let url = URL(string: "https://waffle-newsletter.ayaangrover.hackclub.app/subscribe") else {
            handleSubscriptionFailure(message: "Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubscribing = false
                
                if let error = error {
                    handleSubscriptionFailure(message: "Error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    handleSubscriptionFailure(message: "No data received from the server")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let message = json["message"] as? String {
                        alertMessage = message
                        showAlert = true
                        if message.lowercased().contains("success") {
                            email = "" // Clear the email field on success
                        }
                    } else {
                        handleSubscriptionFailure(message: "Invalid response from server")
                    }
                } catch {
                    handleSubscriptionFailure(message: "Error parsing server response")
                }
            }
        }.resume()
    }
    
    func handleSubscriptionFailure(message: String) {
        alertMessage = message
        showAlert = true
        isSubscribing = false
    }
}

struct NewsletterView_Previews: PreviewProvider {
    static var previews: some View {
        NewsletterView()
    }
}