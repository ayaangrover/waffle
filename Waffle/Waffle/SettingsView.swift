import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct SettingsView: View {
    @State private var profileImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                profileImageView
                changeProfilePictureButton
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .onAppear(perform: fetchProfileImage)
    }
    
    private var profileImageView: some View {
        Group {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                    .shadow(radius: 10)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 100)
                    )
            }
        }
        .padding()
    }
    
    private var changeProfilePictureButton: some View {
        Button(action: { isImagePickerPresented = true }) {
            Text("Change Profile Picture")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            CustomImagePicker(selectedImage: $selectedImage)
                .onChange(of: selectedImage) { newImage in
                    if let image = newImage {
                        uploadImage(image)
                    }
                }
        }
    }

    private func fetchProfileImage() {
        guard let user = Auth.auth().currentUser else { return }
        let email = user.email ?? ""
        let docRef = Firestore.firestore().collection("users").document(email)
        
        isLoading = true
        docRef.getDocument { (document, error) in
            isLoading = false
            if let error = error {
                self.errorMessage = "Error fetching profile: \(error.localizedDescription)"
                return
            }
            
            if let document = document, document.exists,
               let base64String = document.data()?["image"] as? String,
               let imageData = Data(base64Encoded: base64String),
               let image = UIImage(data: imageData) {
                self.profileImage = image
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) {
        guard let user = Auth.auth().currentUser else { return }
        let email = user.email ?? ""
        let docRef = Firestore.firestore().collection("users").document(email)
        
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            self.errorMessage = "Error preparing image for upload"
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        isLoading = true
        docRef.setData(["image": base64String], merge: true) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error updating profile: \(error.localizedDescription)"
                } else {
                    self.profileImage = image
                }
            }
        }
    }
}

struct CustomImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<CustomImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<CustomImagePicker>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CustomImagePicker

        init(_ parent: CustomImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
