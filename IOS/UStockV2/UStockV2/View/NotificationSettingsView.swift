//
//  NotificationSettingsView.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 19/06/2025.
//


import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
    @State private var daysThreshold = UserDefaults.standard.integer(forKey: "notification_days_threshold") == 0 ? 3 : UserDefaults.standard.integer(forKey: "notification_days_threshold")
    @State private var notificationHour = UserDefaults.standard.integer(forKey: "notification_hour") == 0 ? 18 : UserDefaults.standard.integer(forKey: "notification_hour")
    @State private var notificationMinute = UserDefaults.standard.integer(forKey: "notification_minute")
    
    @State private var showingPermissionAlert = false
    @State private var showingTestAlert = false
    @State private var isAuthorized = false
    
    private let hours = Array(0...23)
    private let minutes = Array(stride(from: 0, through: 55, by: 5))
    private let daysOptions = Array(1...7)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // En-tête
                        VStack(spacing: 10) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(hex: "156585"))
                            
                            Text("Notifications d'expiration")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            
                            Text("Recevez des alertes pour vos produits qui périment bientôt")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Activation des notifications
                        SettingsCard {
                            VStack(spacing: 15) {
                                HStack {
                                    Image(systemName: "bell.badge")
                                        .font(.title2)
                                        .foregroundColor(Color(hex: "156585"))
                                    
                                    VStack(alignment: .leading) {
                                        Text("Activer les notifications")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        
                                        Text("Recevoir des alertes automatiques")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $notificationsEnabled)
                                        .tint(Color(hex: "156585"))
                                }
                                
                                if notificationsEnabled && !isAuthorized {
                                    Button(action: {
                                        requestNotificationPermission()
                                    }) {
                                        Text("Autoriser les notifications")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .background(Color.orange)
                                            .cornerRadius(15)
                                    }
                                }
                            }
                        }
                        
                        // Paramètres de seuil
                        if notificationsEnabled {
                            SettingsCard {
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .font(.title2)
                                            .foregroundColor(Color(hex: "156585"))
                                        
                                        Text("Seuil d'alerte")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                    }
                                    
                                    Text("Être alerté pour les produits qui périment dans moins de :")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Picker("Jours", selection: $daysThreshold) {
                                        ForEach(daysOptions, id: \.self) { day in
                                            Text("\(day) jour\(day > 1 ? "s" : "")")
                                                .tag(day)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                            }
                            
                            // Paramètres d'heure
                            SettingsCard {
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .font(.title2)
                                            .foregroundColor(Color(hex: "156585"))
                                        
                                        Text("Heure de notification")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                    }
                                    
                                    Text("Recevoir la notification chaque jour à :")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        // Sélecteur d'heure
                                        Picker("Heure", selection: $notificationHour) {
                                            ForEach(hours, id: \.self) { hour in
                                                Text("\(hour)h")
                                                    .tag(hour)
                                            }
                                        }
                                        .pickerStyle(WheelPickerStyle())
                                        .frame(width: 80, height: 100)
                                        .clipped()
                                        
                                        // Sélecteur de minutes
                                        Picker("Minutes", selection: $notificationMinute) {
                                            ForEach(minutes, id: \.self) { minute in
                                                Text(String(format: "%02d", minute))
                                                    .tag(minute)
                                            }
                                        }
                                        .pickerStyle(WheelPickerStyle())
                                        .frame(width: 80, height: 100)
                                        .clipped()
                                    }
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(10)
                                    
                                    Text("Heure actuelle : \(formatCurrentTime())")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Bouton de test
                            Button(action: {
                                testNotification()
                            }) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title3)
                                    
                                    Text("TESTER LA NOTIFICATION")
                                        .font(.custom("ChauPhilomeneOne-Regular", size: 18))
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "689FA7"))
                                .foregroundColor(.black)
                                .cornerRadius(15)
                                .shadow(radius: 3)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                checkNotificationStatus()
            }
            .alert("Notification envoyée", isPresented: $showingTestAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Une notification de test a été envoyée !")
            }
            .alert("Autorisation requise", isPresented: $showingPermissionAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Ouvrir Réglages") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Pour recevoir des notifications, veuillez les autoriser dans les réglages de l'app.")
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Fonctions privées
    
    private func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notifications_enabled")
        UserDefaults.standard.set(daysThreshold, forKey: "notification_days_threshold")
        UserDefaults.standard.set(notificationHour, forKey: "notification_hour")
        UserDefaults.standard.set(notificationMinute, forKey: "notification_minute")
        
        print("💾 Paramètres sauvegardés:")
        print("- Notifications: \(notificationsEnabled)")
        print("- Seuil: \(daysThreshold) jours")
        print("- Heure: \(notificationHour)h\(notificationMinute < 10 ? "0" : "")\(notificationMinute)")
        
        // Reprogrammer les notifications avec les nouveaux paramètres
        if notificationsEnabled {
            // Ici tu pourras appeler la fonction pour reprogrammer
            // NotificationService.shared.scheduleExpirationNotifications(for: products)
        } else {
            NotificationService.shared.cancelAllExpirationNotifications()
        }
    }
    
    private func checkNotificationStatus() {
        NotificationService.shared.checkNotificationSettings { authorized in
            self.isAuthorized = authorized
        }
    }
    
    private func requestNotificationPermission() {
        NotificationService.shared.requestAuthorization { granted in
            if granted {
                self.isAuthorized = true
            } else {
                self.showingPermissionAlert = true
                self.notificationsEnabled = false
            }
        }
    }
    
    private func testNotification() {
        NotificationService.shared.sendImmediateExpirationNotification(for: [])
        showingTestAlert = true
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Composants helper

struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(Color.white.opacity(0.8))
            .cornerRadius(15)
            .shadow(radius: 3)
            .padding(.horizontal)
    }
}