import UIKit
import AVFoundation

protocol ScannerViewControllerDelegate: AnyObject {
    func didFind(barcode: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var isFlashOn: Bool = false
    
    private let overlayView = UIView()
    private let scannerBorderView = UIView()
    
    // 🔹 NOUVEAU : Gestion des scans multiples
    private var lastScannedCode: String?
    private var lastScanTime: Date = Date()
    private let scanCooldown: TimeInterval = 2.0 // 2 secondes entre chaque scan du même code
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuration de la vue
        view.backgroundColor = .black
        setupOverlayView()
        
        // Configuration du scanner
        setupCaptureSession()
    }
    
    private func setupOverlayView() {
        // Ajout de la vue de superposition semi-transparente
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Création d'un trou transparent dans la vue de superposition
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: overlayView.bounds)
        
        // Taille du rectangle de scan (80% de la largeur)
        let scanRectWidth = view.bounds.width * 0.8
        let scanRectHeight = scanRectWidth * 0.7 // Ratio 10:7 pour le rectangle
        let scanRect = CGRect(
            x: (view.bounds.width - scanRectWidth) / 2,
            y: (view.bounds.height - scanRectHeight) / 2,
            width: scanRectWidth,
            height: scanRectHeight
        )
        
        // Découper le rectangle de scan
        let scanPath = UIBezierPath(roundedRect: scanRect, cornerRadius: 10)
        path.append(scanPath.reversing())
        maskLayer.path = path.cgPath
        overlayView.layer.mask = maskLayer
        
        // Ajouter une bordure blanche autour du rectangle de scan
        scannerBorderView.translatesAutoresizingMaskIntoConstraints = false
        scannerBorderView.layer.borderWidth = 3
        scannerBorderView.layer.borderColor = UIColor.white.cgColor
        scannerBorderView.layer.cornerRadius = 10
        view.addSubview(scannerBorderView)
        
        NSLayoutConstraint.activate([
            scannerBorderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scannerBorderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scannerBorderView.widthAnchor.constraint(equalToConstant: scanRectWidth),
            scannerBorderView.heightAnchor.constraint(equalToConstant: scanRectHeight)
        ])
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("❌ ERREUR: Aucun appareil photo trouvé")
            return
        }
        
        do {
            // Configuration de l'entrée vidéo
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("❌ ERREUR: Impossible d'ajouter l'entrée vidéo")
                return
            }
            
            // Configuration de la sortie metadata
            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr, .upce]
            } else {
                print("❌ ERREUR: Impossible d'ajouter la sortie metadata")
                return
            }
            
            // Configuration de la prévisualisation
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            // Déplacer les éléments d'interface au premier plan
            view.bringSubviewToFront(overlayView)
            view.bringSubviewToFront(scannerBorderView)
            
            // Configuration de la zone d'intérêt
            DispatchQueue.main.async {
                // Cette configuration doit être faite après que le previewLayer est correctement initialisé
                let scanRectWidth = self.view.bounds.width * 0.8
                let scanRectHeight = scanRectWidth * 0.7
                let scanRect = CGRect(
                    x: (self.view.bounds.width - scanRectWidth) / 2,
                    y: (self.view.bounds.height - scanRectHeight) / 2,
                    width: scanRectWidth,
                    height: scanRectHeight
                )
                
                let rectOfInterest = self.previewLayer.metadataOutputRectConverted(fromLayerRect: scanRect)
                metadataOutput.rectOfInterest = rectOfInterest
            }
            
            // Démarrer la session en arrière-plan
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
            
        } catch {
            print("❌ ERREUR: Impossible d'obtenir l'entrée vidéo : \(error.localizedDescription)")
            return
        }
    }
    
    func toggleFlash(isOn: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("❌ Flash non disponible")
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("❌ Impossible d'activer la lampe torche : \(error.localizedDescription)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    // 🔹 MODIFIÉ : Gestion améliorée du scan avec son et vibration
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            
            // 🔹 NOUVEAU : Éviter les scans multiples du même code
            let currentTime = Date()
            if let lastCode = lastScannedCode,
               lastCode == stringValue,
               currentTime.timeIntervalSince(lastScanTime) < scanCooldown {
                print("⏰ Scan du même code ignoré (cooldown)")
                return
            }
            
            // Mettre à jour les informations de dernier scan
            lastScannedCode = stringValue
            lastScanTime = currentTime
            
            print("📱 Code-barres scanné: \(stringValue)")
            
            // 🔹 NOUVEAU : Jouer le son et vibration de scan
            DispatchQueue.main.async {
                SoundManager.shared.playScanSound()
                SoundManager.shared.triggerScanHaptic()
            }
            
            // 🔹 NOUVEAU : Animation visuelle du scan réussi
            animateSuccessfulScan()
            
            // Notification du délégué et arrêt de la session (après un délai pour le feedback)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.delegate?.didFind(barcode: stringValue)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.stopRunning()
                }
            }
        }
    }
    
    // 🔹 NOUVEAU : Animation visuelle lors d'un scan réussi
    private func animateSuccessfulScan() {
        // Changer brièvement la couleur de la bordure en vert
        let originalColor = scannerBorderView.layer.borderColor
        
        UIView.animate(withDuration: 0.2, animations: {
            self.scannerBorderView.layer.borderColor = UIColor.green.cgColor
            self.scannerBorderView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.scannerBorderView.layer.borderColor = originalColor
                self.scannerBorderView.transform = CGAffineTransform.identity
            }
        }
    }
    
    // 🔹 NOUVEAU : Méthode pour jouer un son d'erreur
    func playErrorFeedback() {
        DispatchQueue.main.async {
            SoundManager.shared.playErrorSound()
            SoundManager.shared.triggerErrorHaptic()
        }
        
        // Animation visuelle d'erreur
        let originalColor = scannerBorderView.layer.borderColor
        
        UIView.animate(withDuration: 0.1, animations: {
            self.scannerBorderView.layer.borderColor = UIColor.red.cgColor
        }) { _ in
            UIView.animate(withDuration: 0.1, delay: 0.1, options: [], animations: {
                self.scannerBorderView.layer.borderColor = originalColor
            })
        }
    }
    
    // 🔹 NOUVEAU : Méthode pour réactiver le scanner
    func resetScanner() {
        lastScannedCode = nil
        lastScanTime = Date()
        
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
}
