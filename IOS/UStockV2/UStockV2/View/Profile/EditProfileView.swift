import SwiftUI

struct EditProfileView: View {
    @Binding var userName: String
    @Binding var userEmail: String
    @State private var tempUserName: String = ""
    @State private var tempUserEmail: String = ""
    @State private var profileImage: Image?
    @State private var inputImage: UIImage?
    @State private var showImageSourceSelector = false
    @State private var showPhotoLibrary = false
    @State private var showCamera = false
    @State private var showDocumentPicker = false
    @State private var profileImageUrl: String? = nil
    @State private var isUploadingImage = false
    @State private var showUploadSuccess = false
    @State private var uploadErrorMessage: String?
    @State private var showUploadError = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Photo de profil avec bouton de modification
                    Button(action: {
                        showImageSourceSelector = true
                    }) {
                        VStack {
                            ZStack {
                                if let profileImage = profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color(hex: "156585"), lineWidth: 3))
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(Color(hex: "156585"))
                                }
                                
                                if isUploadingImage {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 120, height: 120)
                                    
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                }
                            }
                            
                            Text(isUploadingImage ? "Upload en cours..." : "Modifier la photo")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "156585"))
                                .padding(.top, 5)
                        }
                    }
                    .disabled(isUploadingImage)
                    .padding(.top, 20)
                    
                    CustomTextField(placeholder: "Nom d'utilisateur", text: $tempUserName)
                    CustomTextField(placeholder: "Email", text: $tempUserEmail)
                    
                    Spacer()
                    
                    Button(action: {
                        userName = tempUserName
                        userEmail = tempUserEmail
                        dismiss()
                    }) {
                        Text("ENREGISTRER")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "689FA7"))
                            .foregroundColor(.black)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
                .padding()
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempUserName = userName
                tempUserEmail = userEmail
                fetchUserProfile()
            }
            .confirmationDialog("Choisir une photo", isPresented: $showImageSourceSelector) {
                Button("Album photo") {
                    showPhotoLibrary = true
                }
                Button("Appareil photo") {
                    showCamera = true
                }
                Button("Fichiers") {
                    showDocumentPicker = true
                }
                Button("Annuler", role: .cancel) {}
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoPicker(image: $inputImage, completion: loadImage)
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $inputImage, completion: loadImage)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(image: $inputImage, completion: loadImage)
            }
            .alert("Photo mise à jour", isPresented: $showUploadSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Votre photo de profil a été mise à jour avec succès.")
            }
            .alert("Erreur upload", isPresented: $showUploadError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(uploadErrorMessage ?? "Une erreur est survenue lors de l'upload de l'image")
            }
        }
    }
    
    // MARK: - Fonctions privées
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
        uploadProfileImage(image: inputImage)
    }
    
    private func uploadProfileImage(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let token = UserDefaults.standard.string(forKey: "authToken") else {
            uploadErrorMessage = "Erreur: Token d'authentification manquant"
            showUploadError = true
            return
        }
        
        isUploadingImage = true
        
        let url = URL(string: "https://api.ustock.pro/users/me/profile-image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isUploadingImage = false
                
                if let error = error {
                    print("❌ Erreur upload: \(error.localizedDescription)")
                    self.uploadErrorMessage = "Erreur réseau: \(error.localizedDescription)"
                    self.showUploadError = true
                    return
                }
                
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        self.showUploadSuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.fetchUserProfile()
                        }
                    } else {
                        self.uploadErrorMessage = "Erreur serveur: Code \(response.statusCode)"
                        self.showUploadError = true
                    }
                }
            }
        }.resume()
    }
    
    private func fetchUserProfile() {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            return
        }
        
        let url = URL(string: "https://api.ustock.pro/users/me")!
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        DispatchQueue.main.async {
                            if let username = json["username"] as? String {
                                self.tempUserName = username
                            }
                            if let email = json["email"] as? String {
                                self.tempUserEmail = email
                            }
                            
                            if let imageUrl = json["profile_image_url"] as? String, !imageUrl.isEmpty {
                                self.profileImageUrl = imageUrl
                                self.loadProfileImage(from: imageUrl)
                            }
                        }
                    }
                } catch {
                    print("❌ Erreur décodage: \(error)")
                }
            }
        }.resume()
    }
    
    private func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = Image(uiImage: uiImage)
                }
            }
        }.resume()
    }
}
