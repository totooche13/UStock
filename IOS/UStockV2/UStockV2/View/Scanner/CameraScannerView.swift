//
//  CameraScannerView.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 20/03/2025.
//


import SwiftUI
import AVFoundation

struct CameraScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isShowingScanner: Bool
    @Binding var isFlashOn: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerVC = ScannerViewController()
        scannerVC.delegate = context.coordinator
        scannerVC.isFlashOn = isFlashOn
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.toggleFlash(isOn: isFlashOn)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        var parent: CameraScannerView
        
        init(_ parent: CameraScannerView) {
            self.parent = parent
        }
        
        func didFind(barcode: String) {
            DispatchQueue.main.async {
                self.parent.scannedCode = barcode
                self.parent.isShowingScanner = false
            }
        }
    }
}