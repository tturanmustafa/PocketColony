//
//  GachaView.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// GachaView.swift
// Kahraman çekiliş sistemi

import SwiftUI

struct GachaView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var gameManager: GameManager
    @State private var isAnimating = false
    @State private var results: [Colonist] = []
    @State private var showResults = false
    @State private var currentResultIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("✨ Kahraman Çekilişi")
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
                
                if showResults {
                    resultView
                } else if isAnimating {
                    animationView
                } else {
                    pullOptionsView
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e"))
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Pull Options
    private var pullOptionsView: some View {
        VStack(spacing: 16) {
            // Banner görsel
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3), .orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 150)
                
                VStack {
                    Text("⭐")
                        .font(.system(size: 50))
                    Text("Efsanevi Kahramanlar Bekliyor!")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Pity: \(gameManager.gameState.gachaPity)/\(GameBalance.guaranteedLegendaryPity)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal)
            
            // Oranlar
            HStack(spacing: 8) {
                ForEach(Rarity.allCases, id: \.rawValue) { rarity in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(rarity.color)
                            .frame(width: 12, height: 12)
                        Text("\(Int(rarity.gachaProbability * 100))%")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(rarity.color)
                    }
                }
            }
            
            // Çekim butonları
            HStack(spacing: 16) {
                // Tek çekim
                Button {
                    performPull(count: 1)
                } label: {
                    VStack(spacing: 4) {
                        Text("1x Çekim")
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack(spacing: 2) {
                            Text("💠")
                            Text("\(GameBalance.singlePullCost)")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(.cyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    )
                }
                
                // 10x çekim
                Button {
                    performPull(count: 10)
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 2) {
                            Text("10x Çekim")
                                .font(.headline)
                            Text("🔥")
                        }
                        .foregroundColor(.white)
                        HStack(spacing: 2) {
                            Text("💠")
                            Text("\(GameBalance.tenPullCost)")
                                .font(.subheadline.bold())
                            Text("(1 bedava!)")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.orange, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Animation
    private var animationView: some View {
        VStack(spacing: 20) {
            ZStack {
                // Dönen halka
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .blue, .cyan, .green, .yellow, .orange, .red, .purple],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                
                Text("✨")
                    .font(.system(size: 50))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            Text("Kahraman aranıyor...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(40)
    }
    
    // MARK: - Results
    private var resultView: some View {
        VStack(spacing: 16) {
            if currentResultIndex < results.count {
                let colonist = results[currentResultIndex]
                
                VStack(spacing: 12) {
                    // Nadirlik efekti
                    ZStack {
                        Circle()
                            .fill(colonist.rarity.color.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .stroke(colonist.rarity.color, lineWidth: 3)
                            .frame(width: 100, height: 100)
                        
                        Text(colonist.primarySkill.icon)
                            .font(.system(size: 40))
                    }
                    
                    Text(colonist.name)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text(colonist.rarity.displayName)
                        .font(.headline)
                        .foregroundColor(colonist.rarity.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(colonist.rarity.color.opacity(0.2))
                        )
                    
                    Text("Uzmanlık: \(colonist.primarySkill.displayName) \(colonist.primarySkill.icon)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .transition(.scale.combined(with: .opacity))
                
                // Sonraki / Kapat
                HStack(spacing: 16) {
                    if currentResultIndex < results.count - 1 {
                        Button {
                            withAnimation { currentResultIndex += 1 }
                        } label: {
                            Text("Sonraki (\(results.count - currentResultIndex - 1) kaldı)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.blue))
                        }
                    }
                    
                    Button {
                        showResults = false
                        results = []
                        currentResultIndex = 0
                    } label: {
                        Text(currentResultIndex >= results.count - 1 ? "Tamam" : "Hepsini Geç")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.gray.opacity(0.5)))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Actions
    private func performPull(count: Int) {
        isAnimating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let pulled = gameManager.performGachaPull(count: count)
            isAnimating = false
            
            if !pulled.isEmpty {
                results = pulled.sorted { $0.rarity.statMultiplier > $1.rarity.statMultiplier }
                currentResultIndex = 0
                showResults = true
            }
        }
    }
}

// MARK: - BattlePassView
struct BattlePassView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var gameManager: GameManager
    
    let rewards: [(level: Int, free: String, premium: String)] = [
        (1, "🌾 100 Yiyecek", "💠 50 Gem"),
        (5, "⛏️ 200 Metal", "🎖️ Nadir Kahraman"),
        (10, "💧 300 Su", "💠 100 Gem"),
        (15, "⚡ 200 Enerji", "⭐ Destansı Kahraman"),
        (20, "⛏️ 500 Metal", "💠 200 Gem"),
        (25, "💎 50 Kristal", "🏰 Özel Oda Dizaynı"),
        (30, "🌾 500 Yiyecek", "💠 300 Gem"),
        (35, "⛏️ 800 Metal", "⭐ Destansı Kahraman"),
        (40, "💎 100 Kristal", "💠 500 Gem"),
        (45, "⚡ 500 Enerji", "🌟 Efsanevi Kahraman"),
        (50, "💠 200 Gem", "🏆 Sezon Şampiyonu Ünvanı"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("🎖️ Sezon Bileti")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Sezon \(gameManager.gameState.season) — Seviye \(gameManager.gameState.battlePassLevel)/\(GameBalance.battlePassLevels)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // XP bar
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(
                                    LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: geo.size.width * CGFloat(gameManager.gameState.battlePassXP) / CGFloat(GameBalance.xpPerLevel))
                        }
                    }
                    .frame(height: 10)
                    
                    Text("\(gameManager.gameState.battlePassXP)/\(GameBalance.xpPerLevel) XP")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Premium satın alma
                if !gameManager.gameState.battlePassPurchased {
                    Button {
                        // StoreKit satın alma
                        HapticsService.shared.impact(.medium)
                    } label: {
                        HStack {
                            Text("👑 Premium Sezon Bileti Al")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("$4.99")
                                .font(.headline.bold())
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(colors: [.orange.opacity(0.3), .yellow.opacity(0.3)],
                                                 startPoint: .leading, endPoint: .trailing)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Ödül listesi
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(rewards, id: \.level) { reward in
                            let unlocked = gameManager.gameState.battlePassLevel >= reward.level
                            let claimed = gameManager.gameState.claimedRewards.contains(reward.level)
                            
                            HStack(spacing: 12) {
                                // Seviye numarası
                                Text("\(reward.level)")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(unlocked ? .yellow : .gray)
                                    .frame(width: 30)
                                
                                // Ücretsiz ödül
                                VStack(spacing: 2) {
                                    Text("Ücretsiz")
                                        .font(.system(size: 8))
                                        .foregroundColor(.gray)
                                    Text(reward.free)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(unlocked ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                                )
                                
                                // Premium ödül
                                VStack(spacing: 2) {
                                    Text("👑 Premium")
                                        .font(.system(size: 8))
                                        .foregroundColor(.yellow.opacity(0.7))
                                    Text(reward.premium)
                                        .font(.caption)
                                        .foregroundColor(gameManager.gameState.battlePassPurchased ? .white : .gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            gameManager.gameState.battlePassPurchased && unlocked ?
                                            Color.yellow.opacity(0.15) : Color.white.opacity(0.03)
                                        )
                                        .overlay(
                                            !gameManager.gameState.battlePassPurchased ?
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.black.opacity(0.4)) : nil
                                        )
                                )
                                
                                // Claim button
                                if unlocked && !claimed {
                                    Button {
                                        claimReward(level: reward.level)
                                    } label: {
                                        Image(systemName: "gift.fill")
                                            .foregroundColor(.yellow)
                                    }
                                } else if claimed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 350)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e"))
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
    
    private func claimReward(level: Int) {
        gameManager.gameState.claimedRewards.insert(level)
        gameManager.showToast("🎁 Seviye \(level) ödülü alındı!", type: .success)
        HapticsService.shared.notification(.success)
        gameManager.addBattlePassXP(0) // UI güncelle
    }
}