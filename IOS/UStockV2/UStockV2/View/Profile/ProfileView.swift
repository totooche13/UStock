import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var userName: String = "Jean Dupont"
    @State private var userEmail: String = "jean.dupont@example.com"
    @State private var memberSince: String = "Mars 2025"
    @State private var showLogoutConfirmation = false
    @State private var showEditProfile = false
    @State private var showImageSourceSelector = false
    @State private var showPhotoLibrary = false
    @State private var showCamera = false
    @State private var showDocumentPicker = false
    @State private var inputImage: UIImage?
    @State private var profileImage: Image?
    @State private var profileImageUrl: String? = nil
    @State private var isUploadingImage = false
    @State private var showUploadSuccess = false
    @State private var uploadErrorMessage: String?
    @State private var showUploadError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("PROFIL")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.top, 20)
                        
                        // Photo de profil avec sélecteur multiple
                        Button(action: {
                            showImageSourceSelector = true
                        }) {
                            VStack {
                                ZStack {
                                    if let profileImage = profileImage {
                                        profileImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 150)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color(hex: "156585"), lineWidth: 4))
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 150, height: 150)
                                            .foregroundColor(Color(hex: "156585"))
                                    }
                                    
                                    // Indicateur de chargement pendant l'upload
                                    if isUploadingImage {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 150, height: 150)
                                        
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    }
                                }
                                
                                Text(isUploadingImage ? "Upload en cours..." : "Modifier la photo")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "156585"))
                                    .padding(.top, 5)
                            }
                        }
                        .disabled(isUploadingImage)
                        
                        // Infos utilisateur
                        VStack(spacing: 10) {
                            Text(userName)
                                .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text(userEmail)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            
                            Text("Membre depuis \(memberSince)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(radius: 3)
                        .padding(.horizontal)
                        
                        // Options
                        VStack(alignment: .leading, spacing: 15) {
                            Text("PARAMÈTRES")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                                .foregroundColor(.black)
                                .padding(.horizontal)
                                .padding(.top, 5)
                            
                            Button(action: {
                                showEditProfile = true
                            }) {
                                settingsRowView(icon: "person.fill", text: "Modifier mon profil")
                            }
                            
                            // Bouton déconnexion
                            Button(action: {
                                showLogoutConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.white)
                                    Text("DÉCONNEXION")
                                        .font(.custom("ChauPhilomeneOne-Regular", size: 16))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(15)
                                .shadow(radius: 3)
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                    }
                    .padding(.bottom, 100) // Espace pour navigation
                }
            }
            .alert("Déconnexion", isPresented: $showLogoutConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Déconnexion", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir vous déconnecter ?")
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(userName: $userName, userEmail: $userEmail)
            }
            // Action Sheet pour choisir la source d'image
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
            // Sélecteur de photos
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoPicker(image: $inputImage, completion: loadImage)
            }
            // Caméra
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $inputImage, completion: loadImage)
            }
            // Sélecteur de fichiers
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(image: $inputImage, completion: loadImage)
            }
            // Alertes pour l'upload
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
            .onAppear {
                fetchUserProfile()
            }
        }
    }
    
    // Charger l'image sélectionnée
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
        
        // Uploader l'image vers le serveur
        uploadProfileImage(image: inputImage)
    }
    
    // Uploader l'image vers l'API
    private func uploadProfileImage(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let token = UserDefaults.standard.string(forKey: "authToken") else {
            uploadErrorMessage = "Erreur: Token d'authentification manquant"
            showUploadError = true
            return
        }
        
        isUploadingImage = true
        
        let url = URL(string: "https://api.ustock.pro:8443/users/me/profile-image")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Ajouter l'image au body
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
                    print("✅ Statut upload: \(response.statusCode)")
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("📦 Réponse: \(responseString)")
                    }
                    
                    if response.statusCode == 200 {
                        self.showUploadSuccess = true
                        
                        // Rafraîchir le profil pour obtenir la nouvelle URL
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
    
    // Récupérer les informations du profil
    private func fetchUserProfile() {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            return
        }
        
        let url = URL(string: "https://api.ustock.pro:8443/users/me")!
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                do {
                    let decoder = JSONDecoder()
                    let userProfile = try decoder.decode(UserProfile.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.userName = userProfile.username
                        self.userEmail = userProfile.email
                        
                        if let imageUrl = userProfile.profile_image_url, !imageUrl.isEmpty {
                            self.profileImageUrl = imageUrl
                            self.loadProfileImage(from: imageUrl)
                        }
                    }
                } catch {
                    print("❌ Erreur décodage: \(error)")
                }
            }
        }.resume()
    }
    
    // Charger l'image depuis l'URL
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
    
    // Fonction de déconnexion
    private func logout() {
        AuthManager.shared.removeToken()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: WelcomeView())
            window.makeKeyAndVisible()
        }
    }
    
    // Vue pour ligne de paramètre
    private func settingsRowView(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "156585"))
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

// MARK: - Photo Library Picker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var completion: () -> Void
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                        self.parent.completion()
                    }
                }
            }
        }
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Camera Picker
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var completion: () -> Void
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
                parent.completion()
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var completion: () -> Void
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Vérifier si c'est une image
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                
                if let imageData = try? Data(contentsOf: url),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.parent.image = image
                        self.parent.completion()
                    }
                }
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            controller.dismiss(animated: true)
        }
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// Modèle pour décoder la réponse de l'API
struct UserProfile: Codable {
    let id: Int
    let first_name: String
    let last_name: String
    let email: String
    let username: String
    let birth_date: String
    let gender: String
    let profile_image_url: String?
}
