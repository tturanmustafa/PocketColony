//
//  GameCenterService.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// GameCenterService.swift
// Game Center entegrasyonu

import GameKit
import UIKit

class GameCenterService {
    static let shared = GameCenterService()
    
    var isAuthenticated = false
    var localPlayer = GKLocalPlayer.local
    
    private init() {}
    
    // MARK: - Kimlik Doğrulama
    func authenticate() {
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            if let vc = viewController {
                // Game Center giriş ekranını göster
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true)
                }
            } else if self?.localPlayer.isAuthenticated == true {
                self?.isAuthenticated = true
                print("✅ Game Center: Giriş yapıldı - \(self?.localPlayer.displayName ?? "")")
                
                // Başarımları ve sıralamaları yükle
                self?.loadAchievements()
            } else {
                self?.isAuthenticated = false
                if let error = error {
                    print("❌ Game Center hatası: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Skor Gönder
    func submitScore(_ score: Int, leaderboardID: String) {
        guard isAuthenticated else { return }
        
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: localPlayer,
                    leaderboardIDs: [leaderboardID]
                )
                print("✅ Game Center: Skor gönderildi (\(leaderboardID): \(score))")
            } catch {
                print("❌ Game Center skor hatası: \(error)")
            }
        }
    }
    
    // MARK: - Başarım Bildir
    func reportAchievement(_ id: String, percentComplete: Double = 100) {
        guard isAuthenticated else { return }
        
        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        
        Task {
            do {
                try await GKAchievement.report([achievement])
                print("✅ Game Center: Başarım bildirildi - \(id)")
            } catch {
                print("❌ Game Center başarım hatası: \(error)")
            }
        }
    }
    
    // MARK: - Sıralama Tablosunu Göster
    func showLeaderboard() {
        guard isAuthenticated else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let gcVC = GKGameCenterViewController(state: .leaderboards)
            gcVC.gameCenterDelegate = GameCenterDelegate.shared
            rootVC.present(gcVC, animated: true)
        }
    }
    
    // MARK: - Başarımları Yükle
    private func loadAchievements() {
        Task {
            do {
                let achievements = try await GKAchievement.loadAchievements()
                print("ℹ️ Game Center: \(achievements.count) başarım yüklendi")
            } catch {
                print("❌ Game Center başarım yükleme: \(error)")
            }
        }
    }
    
    // MARK: - Oyun Olaylarını Bildir
    func onRoomBuilt() {
        reportAchievement("first_room")
    }
    
    func onDepthReached(_ depth: Int) {
        if depth >= 10 {
            reportAchievement("depth_10")
        }
        submitScore(depth, leaderboardID: "colony_depth")
    }
    
    func onWaveSurvived(_ wave: Int) {
        if wave >= 50 {
            reportAchievement("survive_wave_50")
        }
        submitScore(wave, leaderboardID: "wave_survived")
    }
    
    func onLegendaryHeroFound() {
        reportAchievement("legendary_hero")
    }
}

// Game Center Delegate
class GameCenterDelegate: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDelegate()
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

// MARK: - AudioService
import AVFoundation

class AudioService {
    static let shared = AudioService()
    
    private var bgPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    var isMusicEnabled: Bool = true
    var isSFXEnabled: Bool = true
    
    private init() {
        // Audio session konfigürasyonu
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session hatası: \(error)")
        }
    }
    
    func playBackgroundMusic(named name: String) {
        guard isMusicEnabled else { return }
        
        // Gerçek projede Asset'ten yüklenecek
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("ℹ️ Müzik dosyası bulunamadı: \(name).mp3 — placeholder olarak sessiz")
            return
        }
        
        do {
            bgPlayer = try AVAudioPlayer(contentsOf: url)
            bgPlayer?.numberOfLoops = -1 // Sonsuz döngü
            bgPlayer?.volume = 0.3
            bgPlayer?.play()
        } catch {
            print("❌ Müzik çalma hatası: \(error)")
        }
    }
    
    func playSFX(named name: String) {
        guard isSFXEnabled else { return }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.5
            player.play()
            sfxPlayers[name] = player
        } catch {
            print("❌ SFX hatası: \(error)")
        }
    }
    
    func pause() {
        bgPlayer?.pause()
    }
    
    func resume() {
        guard isMusicEnabled else { return }
        bgPlayer?.play()
    }
    
    func stopAll() {
        bgPlayer?.stop()
        sfxPlayers.values.forEach { $0.stop() }
    }
}

// MARK: - HapticsService
import CoreHaptics

class HapticsService {
    static let shared = HapticsService()
    
    var isEnabled: Bool = true
    private var engine: CHHapticEngine?
    
    private init() {
        setupEngine()
    }
    
    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            print("❌ Haptic engine hatası: \(error)")
        }
    }
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // Özel haptic pattern - inşaat tamamlanma
    func playBuildComplete() {
        guard isEnabled, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            
            let events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.1),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ], relativeTime: 0.2),
            ]
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            impact(.heavy)
        }
    }
    
    // Gacha çekilişi haptic
    func playGachaReveal(rarity: Rarity) {
        guard isEnabled else { return }
        
        switch rarity {
        case .common, .uncommon:
            impact(.light)
        case .rare:
            impact(.medium)
        case .epic:
            notification(.success)
        case .legendary:
            playBuildComplete()
        }
    }
}

// MARK: - NotificationService
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Bildirim izni verildi")
            } else if let error = error {
                print("❌ Bildirim izni hatası: \(error)")
            }
        }
    }
    
    func scheduleReturnReminders() {
        let center = UNUserNotificationCenter.current()
        
        // Mevcut bildirimleri temizle
        center.removeAllPendingNotificationRequests()
        
        // 1 saat sonra
        scheduleNotification(
            id: "return_1h",
            title: "🏗️ İnşaat Tamamlandı!",
            body: "Kolonindeki inşaat bitti. Geri dön ve yeni odalar inşa et!",
            delay: 3600
        )
        
        // 4 saat sonra
        scheduleNotification(
            id: "return_4h",
            title: "📦 Kaynakların Doldu!",
            body: "Depolar dolmak üzere. Kaynaklarını topla!",
            delay: 14400
        )
        
        // 24 saat sonra
        scheduleNotification(
            id: "return_24h",
            title: "👥 Kolonistlerin Seni Bekliyor!",
            body: "Kolonin senin yönetimini özledi. Geri dön!",
            delay: 86400
        )
        
        // 3 gün sonra
        scheduleNotification(
            id: "return_3d",
            title: "⚠️ Koloni Tehlikede!",
            body: "Uzun süredir gelmiyorsun. Kolonin saldırı altında olabilir!",
            delay: 259200
        )
    }
    
    private func scheduleNotification(id: String, title: String, body: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Bildirim planlama hatası: \(error)")
            }
        }
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}