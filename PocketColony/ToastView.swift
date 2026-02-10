//
//  ToastView.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// ToastAndSettings.swift
// Toast bildirim sistemi ve Ayarlar

import SwiftUI

// MARK: - Toast View
struct ToastView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack {
            VStack(spacing: 6) {
                ForEach(gameManager.toastMessages) { toast in
                    HStack(spacing: 8) {
                        Text(toast.message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(toast.type.color.opacity(0.85))
                            .shadow(color: toast.type.color.opacity(0.3), radius: 8, y: 2)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 100)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: gameManager.toastMessages.count)
            
            Spacer()
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var isPresented: Bool
    @AppStorage("musicEnabled") private var musicEnabled = true
    @AppStorage("sfxEnabled") private var sfxEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("⚙️ Ayarlar")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                VStack(spacing: 12) {
                    // Ses ayarları
                    SettingsToggle(icon: "🎵", title: "Müzik", isOn: $musicEnabled) {
                        if musicEnabled {
                            AudioService.shared.playBackgroundMusic(named: "ambient_underground")
                        } else {
                            AudioService.shared.pause()
                        }
                    }
                    SettingsToggle(icon: "🔊", title: "Ses Efektleri", isOn: $sfxEnabled) {}
                    SettingsToggle(icon: "📳", title: "Titreşim", isOn: $hapticsEnabled) {
                        HapticsService.shared.isEnabled = hapticsEnabled
                    }
                    SettingsToggle(icon: "🔔", title: "Bildirimler", isOn: $notificationsEnabled) {}
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Game Center
                    Button {
                        GameCenterService.shared.showLeaderboard()
                    } label: {
                        HStack {
                            Text("🏆 Game Center Sıralama")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // iCloud sync
                    Button {
                        Task { await CloudKitService.shared.saveGameState(GameManager.shared.gameState) }
                        HapticsService.shared.notification(.success)
                    } label: {
                        HStack {
                            Text("☁️ iCloud'a Kaydet")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.cyan)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Satın almaları geri yükle
                    Button {
                        Task { await StoreKitService.shared.restorePurchases() }
                    } label: {
                        HStack {
                            Text("🔄 Satın Almaları Geri Yükle")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    Text("Pocket Colony: Underground v1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e"))
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
}

struct SettingsToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let onChange: () -> Void
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Text(icon)
                Text(title).foregroundColor(.white)
            }
        }
        .tint(.green)
        .onChange(of: isOn) { _, _ in onChange() }
    }
}