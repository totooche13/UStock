import Foundation
import AVFoundation
import AudioToolbox
import UIKit

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var isSetup = false
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Configuration Audio
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            isSetup = true
            print("✅ Session audio configurée avec succès")
        } catch {
            print("❌ Erreur configuration session audio: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sons du scanner
    
    /// Joue le son de scan avec bip personnalisé
    func playScanSound() {
        // Vérifier si le son est activé dans les paramètres
        guard UserDefaults.standard.bool(forKey: "scanner_sound_enabled") else {
            print("🔇 Son du scanner désactivé dans les paramètres")
            return
        }
        
        // Essayer d'abord le son personnalisé, sinon utiliser le son système
        if !playCustomScanSound() {
            playSystemScanSound()
        }
    }
    
    /// Joue un son personnalisé de scan (bip de caisse authentique)
    private func playCustomScanSound() -> Bool {
        // Triple bip rapide comme en caisse de supermarché
        let sampleRate: Float = 44100.0
        let beepFreq: Float = 1000.0       // 1000 Hz - fréquence standard caisse
        let beepDuration: Float = 0.08     // 80ms par bip (très court)
        let pauseDuration: Float = 0.04    // 40ms de pause entre bips
        
        // 3 bips : bip + pause + bip + pause + bip
        let beepSamples = Int(beepDuration * sampleRate)
        let pauseSamples = Int(pauseDuration * sampleRate)
        
        var audioData = [Float]()
        
        // Fonction pour créer un bip
        func addBeep() {
            for i in 0..<beepSamples {
                let time = Float(i) / sampleRate
                // Enveloppe ADSR simple pour un son plus propre
                let envelope = min(1.0, Float(i) / Float(beepSamples) * 10) *
                              min(1.0, Float(beepSamples - i) / Float(beepSamples) * 10)
                let amplitude: Float = 0.35 * sin(2.0 * Float.pi * beepFreq * time) * envelope
                audioData.append(amplitude)
            }
        }
        
        // Fonction pour ajouter une pause
        func addPause() {
            for _ in 0..<pauseSamples {
                audioData.append(0.0)
            }
        }
        
        // Créer le triple bip : bip-pause-bip-pause-bip
        addBeep()
        addPause()
        addBeep()
        addPause()
        addBeep()
        
        // Convertir en données audio
        let audioBuffer = audioData.withUnsafeBufferPointer { buffer in
            return Data(buffer: UnsafeBufferPointer(start: buffer.baseAddress, count: buffer.count * MemoryLayout<Float>.size))
        }
        
        do {
            // Créer un fichier audio temporaire
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("scan_beep.wav")
            
            // Créer l'en-tête WAV
            let wavHeader = createWAVHeader(dataSize: audioData.count * 4, sampleRate: Int(sampleRate))
            var finalData = wavHeader
            finalData.append(audioBuffer)
            
            try finalData.write(to: tempURL)
            
            // Jouer le son
            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            audioPlayer?.volume = 0.7
            audioPlayer?.play()
            
            print("🔊 Son de scan personnalisé joué")
            return true
            
        } catch {
            print("❌ Erreur création son personnalisé: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Joue le son système de scan
    private func playSystemScanSound() {
        // Son système "bip" court
        AudioServicesPlaySystemSound(1016) // Son de "tock" système
        print("🔊 Son système de scan joué")
    }
    
    /// Joue un son de succès après ajout de produit
    func playSuccessSound() {
        guard UserDefaults.standard.bool(forKey: "scanner_sound_enabled") else { return }
        
        AudioServicesPlaySystemSound(1054) // Son de "success" système
        print("✅ Son de succès joué")
    }
    
    /// Joue un son d'erreur
    func playErrorSound() {
        guard UserDefaults.standard.bool(forKey: "scanner_sound_enabled") else { return }
        
        AudioServicesPlaySystemSound(1053) // Son d'erreur système
        print("❌ Son d'erreur joué")
    }
    
    // MARK: - Vibrations (Haptic Feedback)
    
    /// Vibre lors du scan (si activé)
    func triggerScanHaptic() {
        guard UserDefaults.standard.bool(forKey: "haptics_enabled") else {
            print("📳 Vibrations désactivées dans les paramètres")
            return
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        print("📳 Vibration de scan déclenchée")
    }
    
    /// Vibre pour confirmer une action (succès)
    func triggerSuccessHaptic() {
        guard UserDefaults.standard.bool(forKey: "haptics_enabled") else { return }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        print("✅ Vibration de succès déclenchée")
    }
    
    /// Vibre pour indiquer une erreur
    func triggerErrorHaptic() {
        guard UserDefaults.standard.bool(forKey: "haptics_enabled") else { return }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
        print("❌ Vibration d'erreur déclenchée")
    }
    
    // MARK: - Utilitaires
    
    /// Crée un en-tête WAV basique
    private func createWAVHeader(dataSize: Int, sampleRate: Int) -> Data {
        var header = Data()
        
        // RIFF Header
        header.append("RIFF".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Data($0) })
        header.append("WAVE".data(using: .ascii)!)
        
        // Format chunk
        header.append("fmt ".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // Chunk size
        header.append(withUnsafeBytes(of: UInt16(3).littleEndian) { Data($0) }) // IEEE float
        header.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // Mono
        header.append(withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) }) // Sample rate
        header.append(withUnsafeBytes(of: UInt32(sampleRate * 4).littleEndian) { Data($0) }) // Byte rate
        header.append(withUnsafeBytes(of: UInt16(4).littleEndian) { Data($0) }) // Block align
        header.append(withUnsafeBytes(of: UInt16(32).littleEndian) { Data($0) }) // Bits per sample
        
        // Data chunk
        header.append("data".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Data($0) })
        
        return header
    }
    
    /// Test tous les sons (pour debug/paramètres)
    func testAllSounds() {
        print("🧪 Test de tous les sons...")
        
        DispatchQueue.main.async {
            self.playScanSound()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.playSuccessSound()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.playErrorSound()
        }
    }
    
    /// Test toutes les vibrations
    func testAllHaptics() {
        print("🧪 Test de toutes les vibrations...")
        
        triggerScanHaptic()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.triggerSuccessHaptic()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.triggerErrorHaptic()
        }
    }
}
