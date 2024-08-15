import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var profileImages: [String: UIImage] = [:]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 50)
            
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer().frame(height: 30)
            
            ProfileImageView(email: email, profileImages: $profileImages)
                .frame(width: 150, height: 150)
                .onTapGesture {
                    showingImagePicker = true
                }
            
            Button("Change Profile Picture") {
                showingImagePicker = true
            }
            .foregroundColor(Color("Accent"))
            
            Text("Display Name: \(displayName)")
                .font(.headline)
            
            Spacer()
            
            Button("Save Changes") {
                saveProfileImage()
            }
            .padding()
            .background(Color("Accent"))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(Color("Background"))
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $profileImage, sourceType: .photoLibrary)
        }
        .onAppear(perform: loadUserData)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(Color("Icons"))
        })
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        displayName = user.displayName ?? ""
        email = user.email ?? ""
        
        let docRef = Firestore.firestore().collection("users").document(email)
        docRef.getDocument { document, error in
            if let document = document, document.exists,
               let base64String = document.data()?["image"] as? String,
               let imageData = Data(base64Encoded: base64String),
               let image = UIImage(data: imageData) {
                self.profileImages[email] = image
                self.profileImage = image
            }
        }
    }
    
    private func saveProfileImage() {
        guard let image = profileImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let base64String = imageData.base64EncodedString()
        
        let docRef = Firestore.firestore().collection("users").document(email)
        docRef.setData(["image": base64String]) { error in
            if let error = error {
                print("Error saving profile image: \(error.localizedDescription)")
            } else {
                print("Profile image saved successfully")
                self.profileImages[email] = image
            }
        }
    }
}
