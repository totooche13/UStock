//
//  NotificationService.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 19/06/2025.
//


import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Gestion des autorisations
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Erreur d'autorisation de notification: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(granted)
            }
        }
    }
    
    func checkNotificationSettings(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Gestion des notifications programmées
    
    func scheduleExpirationNotifications(for products: [Produit]) {
        // Récupérer les paramètres utilisateur
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
        let daysThreshold = UserDefaults.standard.integer(forKey: "notification_days_threshold") // Défaut: 3 jours
        let notificationHour = UserDefaults.standard.integer(forKey: "notification_hour") // Défaut: 18h
        let notificationMinute = UserDefaults.standard.integer(forKey: "notification_minute") // Défaut: 0min
        
        // Si les notifications sont désactivées, ne rien faire
        guard notificationsEnabled else { return }
        
        // Valeurs par défaut si pas encore configurées
        let threshold = daysThreshold == 0 ? 3 : daysThreshold
        let hour = notificationHour == 0 ? 18 : notificationHour
        let minute = notificationMinute
        
        print("🔔 Programmation des notifications pour \(hour)h\(minute < 10 ? "0" : "")\(minute), seuil: \(threshold) jours")
        
        // Annuler les notifications existantes
        cancelAllExpirationNotifications()
        
        // Filtrer les produits qui expirent bientôt
        let expiringProducts = products.filter { product in
            product.joursRestants >= 0 && product.joursRestants <= threshold
        }
        
        guard !expiringProducts.isEmpty else {
            print("📭 Aucun produit ne nécessite de notification")
            return
        }
        
        // Programmer la notification pour aujourd'hui (si c'est avant l'heure) et demain
        scheduleDailyNotification(
            hour: hour,
            minute: minute,
            threshold: threshold,
            for: Date(), // Aujourd'hui
            identifier: "expiration_today"
        )
        
        scheduleDailyNotification(
            hour: hour,
            minute: minute,
            threshold: threshold,
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), // Demain
            identifier: "expiration_tomorrow"
        )
    }
    
    private func scheduleDailyNotification(hour: Int, minute: Int, threshold: Int, for date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "🍃 UStock - Produits bientôt périmés"
        content.body = "Vérifiez vos produits qui expirent dans moins de \(threshold) jour\(threshold > 1 ? "s" : "")"
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        // Ajouter des données personnalisées
        content.userInfo = [
            "type": "expiration_check",
            "threshold": threshold
        ]
        
        // Programmer pour l'heure spécifiée
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur programmation notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification programmée pour \(dateComponents.day ?? 0)/\(dateComponents.month ?? 0) à \(hour)h\(minute < 10 ? "0" : "")\(minute)")
            }
        }
    }
    
    // MARK: - Notification immédiate pour test/vérification
    
    func sendImmediateExpirationNotification(for products: [Produit]) {
        let threshold = UserDefaults.standard.integer(forKey: "notification_days_threshold")
        let daysThreshold = threshold == 0 ? 3 : threshold
        
        let expiringProducts = products.filter { product in
            product.joursRestants >= 0 && product.joursRestants <= daysThreshold
        }
        
        guard !expiringProducts.isEmpty else {
            print("📭 Aucun produit ne nécessite de notification immédiate")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🍃 UStock - Attention !"
        
        let count = expiringProducts.count
        if count == 1 {
            content.body = "Vous avez 1 article qui arrive bientôt à expiration"
        } else {
            content.body = "Vous avez \(count) articles qui arrivent bientôt à expiration"
        }
        
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: count)
        
        // Liste des produits dans les données
        let productNames = expiringProducts.prefix(3).map { $0.nom }
        content.userInfo = [
            "type": "expiration_alert",
            "count": count,
            "products": productNames
        ]
        
        // Notification immédiate
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "immediate_expiration", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur notification immédiate: \(error.localizedDescription)")
            } else {
                print("✅ Notification immédiate envoyée pour \(count) produit(s)")
            }
        }
    }
    
    // MARK: - Gestion des notifications
    
    func cancelAllExpirationNotifications() {
        let identifiers = ["expiration_today", "expiration_tomorrow", "immediate_expiration"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🗑️ Notifications d'expiration annulées")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🗑️ Toutes les notifications supprimées")
    }
    
    // MARK: - Utilitaires
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}