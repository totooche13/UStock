//
//  TestNotificationService.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 08/04/2025.
//


import Foundation
import UserNotifications

class TestNotificationService {
    static let shared = TestNotificationService()
    
    private init() {}
    
    // Demander l'autorisation d'envoyer des notifications
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
    
    // Envoyer une notification de test pour un produit
    func sendTestNotification(for produit: Produit, secondsDelay: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "Produit bientôt périmé"
        content.body = "\(produit.nom) expire le \(produit.peremption) (dans \(produit.joursRestants) jours)"
        content.sound = UNNotificationSound.default
        
        // Créer un identifiant unique pour cette notification
        let identifier = "test-notification-\(UUID().uuidString)"
        
        // Créer un déclencheur pour envoyer la notification après un délai (par défaut 5 secondes)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsDelay, repeats: false)
        
        // Créer la requête de notification
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Ajouter la requête au centre de notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur lors de l'envoi de la notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification programmée avec succès pour dans \(secondsDelay) secondes")
            }
        }
    }
    
    // Vérifier l'état des autorisations de notification
    func checkNotificationSettings(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized
                completion(isAuthorized)
            }
        }
    }
}