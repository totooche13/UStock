import SwiftUI

struct ProfileView: View {
    @State private var userName: String = "Chargement..."
    @State private var userEmail: String = "Chargement..."
    @State private var memberSince: String = "Chargement..."
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
    @State private var showAccountDeletion = false
    
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
                            
                            // 🔹 NOUVEAU : Bouton Notifications
                            NavigationLink(destination: NotificationSettingsView()) {
                                settingsRowView(icon: "bell.fill", text: "Notifications")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Bouton Supprimer le compte
                            Button(action: {
                                showAccountDeletion = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Supprimer mon compte")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(15)
                                .shadow(radius: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
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
            .sheet(isPresented: $showAccountDeletion) {
                AccountDeletionView()
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
            // Sélecteurs d'images
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoPicker(image: $inputImage, completion: loadImage)
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $inputImage, completion: loadImage)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(image: $inputImage, completion: loadImage)
            }
            // Alertes
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
        .preferredColorScheme(.light)
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
                    print("✅ Statut upload: \(response.statusCode)")
                    
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
            print("❌ Token manquant")
            return
        }
        
        let url = URL(string: "https://api.ustock.pro/users/me")!
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ Pas de données")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Données brutes: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ JSON décodé avec succès")
                    
                    let username = json["username"] as? String ?? "Nom d'utilisateur inconnu"
                    let email = json["email"] as? String ?? "Email inconnu"
                    let createdAtString = json["created_at"] as? String
                    let imageUrl = json["profile_image_url"] as? String
                    
                    DispatchQueue.main.async {
                        self.userName = username
                        self.userEmail = email
                        
                        if let createdAtString = createdAtString {
                            self.memberSince = self.formatDateFromISO8601(createdAtString)
                        } else {
                            self.memberSince = "Date non disponible"
                        }
                        
                        if let imageUrl = imageUrl, !imageUrl.isEmpty {
                            self.loadProfileImage(from: imageUrl)
                        }
                    }
                }
            } catch {
                print("❌ Erreur décodage JSON: \(error)")
                DispatchQueue.main.async {
                    self.userName = "Erreur de décodage"
                    self.userEmail = "Impossible de lire les données"
                    self.memberSince = "Erreur de format"
                }
            }
        }.resume()
    }
    
    private func formatDateFromISO8601(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        
        if let date = formatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMMM yyyy"
            displayFormatter.locale = Locale(identifier: "fr_FR")
            return displayFormatter.string(from: date)
        } else {
            return formatDateFromString(isoString)
        }
    }
    
    private func formatDateFromString(_ dateString: String) -> String {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "MMMM yyyy"
                displayFormatter.locale = Locale(identifier: "fr_FR")
                return displayFormatter.string(from: date)
            }
        }
        
        return "Format de date non reconnu"
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
    
    private func logout() {
        AuthManager.shared.removeToken()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: WelcomeView())
            window.makeKeyAndVisible()
        }
    }
    
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
