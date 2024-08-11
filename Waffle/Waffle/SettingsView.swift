import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

struct SettingsView: View {
    @State private var profileImage: UIImage?
    @State private var imageURL: String?
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 100, height: 100)
            }

            Button("Change Profile Picture") {
                isImagePickerPresented = true
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
                    .onChange(of: selectedImage) { newImage in
                        if let image = newImage {
                            uploadImage(image)
                        }
                    }
            }

            if imageURL != nil {
                // Display or use the profile picture URL
            }
        }
        .onAppear {
            fetchProfileImageURL()
        }
    }

    private func fetchProfileImageURL() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("users").document(userID)
        
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                self.imageURL = document.data()?["profileImageURL"] as? String
                if let imageURL = self.imageURL {
                    downloadImage(from: imageURL)
                }
            }
        }
    }

    private func downloadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }
        task.resume()
    }
    
    private func uploadImage(_ image: UIImage) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(userID).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.75) {
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error)")
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error)")
                        return
                    }
                    
                    if let url = url {
                        let imageURL = url.absoluteString
                        updateProfileImageURL(imageURL)
                    }
                }
            }
        }
    }
    
    private func updateProfileImageURL(_ imageURL: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("users").document(userID)
        
        docRef.updateData(["profileImageURL": imageURL]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                self.imageURL = imageURL
                downloadImage(from: imageURL)
            }
        }
    }
}
