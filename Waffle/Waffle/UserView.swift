import SwiftUI


struct UserView: View {
    var body: some View {
        Text("Hello SwiftUI!")
    }
}




//import SwiftUI
//
//public struct UserView: View {
//    @StateObject private var networkManager = NetworkManager()
//    
//    public var body: some View {
//        NavigationView {
//            List(networkManager.users) { user in
//                HStack(spacing: 15) {
//                    ProfileImageView(imageURL: user.profileImageURL)
//                    
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text(user.name)
//                            .font(.headline)
//                            .foregroundColor(Color("Accent"))
//                        
//                        Text(user.email)
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                    }
//                }
//                .padding(.vertical, 8)
//            }
//            .navigationTitle("Users")
//            .onAppear {
//                networkManager.fetchUsers()
//            }
//        }
//        .background(Color("Background"))
//    }
//}
