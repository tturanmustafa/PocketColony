//
//  PocketColonyApp.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// PocketColonyApp.swift
// Pocket Colony: Underground
// Ana uygulama giriş noktası

import SwiftUI
import SpriteKit
import CloudKit
import GameKit

@main
struct PocketColonyApp: App {
    @StateObject private var gameManager = GameManager.shared
    @StateObject private var storeService = StoreKitService.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .environmentObject(storeService)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhase(newPhase)
                }
        }
    }
    
    private func setupApp() {
        // Ekranı portrait kilitle
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Servisleri başlat
        Task {
            await gameManager.initialize()
            await storeService.loadProducts()
            GameCenterService.shared.authenticate()
            AudioService.shared.playBackgroundMusic(named: "ambient_underground")
        }
    }
    
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            gameManager.resumeGame()
            AudioService.shared.resume()
        case .inactive:
            gameManager.pauseGame()
        case .background:
            gameManager.saveGame()
            AudioService.shared.pause()
            NotificationService.shared.scheduleReturnReminders()
        @unknown default:
            break
        }
    }
}