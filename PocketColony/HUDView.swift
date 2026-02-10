//
//  HUDView.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// HUDView.swift
// Ana oyun üstü arayüzü

import SwiftUI

struct HUDView: View {
    @Binding var currentOverlay: ContentView.OverlayType?
    var gameState: GameState
    
    var body: some View {
        VStack(spacing: 0) {
            // Üst kaynak çubuğu
            topBar
            
            Spacer()
            
            // Savaş uyarısı
            if gameState.isUnderAttack {
                attackBanner
            }
            
            // Alt menü
            bottomBar
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        VStack(spacing: 4) {
            // Kaynak satırı
            HStack(spacing: 6) {
                ResourcePill(type: .food, amount: gameState.resource(.food), capacity: gameState.capacity(.food))
                ResourcePill(type: .water, amount: gameState.resource(.water), capacity: gameState.capacity(.water))
                ResourcePill(type: .energy, amount: gameState.resource(.energy), capacity: gameState.capacity(.energy))
                ResourcePill(type: .metal, amount: gameState.resource(.metal), capacity: gameState.capacity(.metal))
            }
            
            HStack(spacing: 6) {
                ResourcePill(type: .crystal, amount: gameState.resource(.crystal), capacity: gameState.capacity(.crystal))
                
                Spacer()
                
                // Gem butonu
                Button {
                    currentOverlay = .shop
                    HapticsService.shared.impact(.light)
                } label: {
                    HStack(spacing: 4) {
                        Text("💠")
                            .font(.system(size: 14))
                        Text("\(Int(gameState.resource(.gems)))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                            .overlay(Capsule().stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                    )
                }
                
                // Ayarlar
                Button {
                    currentOverlay = .settings
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            
            // Durum satırı
            HStack(spacing: 12) {
                StatusPill(icon: "👥", text: "\(gameState.populationCount)/\(gameState.populationCapacity)")
                StatusPill(icon: "😊", text: "\(Int(gameState.happinessLevel))%")
                StatusPill(icon: "🛡️", text: "\(gameState.defenseRating)")
                StatusPill(icon: "📏", text: "Kat \(gameState.depth)")
                
                Spacer()
                
                Text("Gün \(gameState.day)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 55) // Safe area
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.85), Color.black.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Attack Banner
    private var attackBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text("⚔️ SALDIRI! Dalga \(gameState.wave) — \(gameState.waveEnemiesRemaining) düşman kaldı")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.8))
                .shadow(color: .red.opacity(0.5), radius: 10)
        )
        .padding(.horizontal)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 0) {
            BottomButton(icon: "hammer.fill", label: "İnşa", color: .green) {
                currentOverlay = .buildMenu
            }
            
            BottomButton(icon: "person.3.fill", label: "Halk", color: .blue) {
                // İlk kolonisti göster
                if let first = gameState.colonists.first {
                    currentOverlay = .colonistDetail(first)
                }
            }
            
            BottomButton(icon: "flask.fill", label: "Araştır", color: .purple) {
                currentOverlay = .research
            }
            
            BottomButton(icon: "sparkles", label: "Gacha", color: .orange) {
                currentOverlay = .gacha
            }
            
            BottomButton(icon: "trophy.fill", label: "Sezon", color: .yellow) {
                currentOverlay = .battlePass
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 30) // Safe area
        .padding(.top, 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Components
struct ResourcePill: View {
    let type: ResourceType
    let amount: Double
    let capacity: Double
    
    var body: some View {
        HStack(spacing: 3) {
            Text(type.icon)
                .font(.system(size: 12))
            Text(formatNumber(amount))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(amount < capacity * 0.1 ? .red : .white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
                .overlay(
                    Capsule()
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func formatNumber(_ value: Double) -> String {
        if value >= 10000 { return "\(Int(value/1000))K" }
        if value >= 1000 { return String(format: "%.1fK", value/1000) }
        return "\(Int(value))"
    }
}

struct StatusPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 2) {
            Text(icon).font(.system(size: 11))
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct BottomButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsService.shared.impact(.light)
            action()
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
    }
}