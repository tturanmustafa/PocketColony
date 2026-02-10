//
//  ContentView.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// ContentView.swift
// Ana navigasyon ve oyun ekranı

import SwiftUI
import SpriteKit

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showSplash = true
    @State private var currentOverlay: OverlayType? = nil
    
    enum OverlayType: Identifiable {
        case buildMenu, colonistDetail(Colonist), research, battlePass, gacha, settings, shop
        var id: String {
            switch self {
            case .buildMenu: return "build"
            case .colonistDetail: return "colonist"
            case .research: return "research"
            case .battlePass: return "battlepass"
            case .gacha: return "gacha"
            case .settings: return "settings"
            case .shop: return "shop"
            }
        }
    }
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isPresented: $showSplash)
                    .transition(.opacity)
            } else {
                // Ana oyun ekranı
                gameView
                
                // HUD overlay
                HUDView(
                    currentOverlay: $currentOverlay,
                    gameState: gameManager.gameState
                )
                .allowsHitTesting(currentOverlay == nil)
                
                // Modal overlays
                if let overlay = currentOverlay {
                    overlayView(for: overlay)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Toast bildirimleri
                ToastView()
                    .environmentObject(gameManager)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentOverlay?.id)
    }
    
    // MARK: - Game View
    private var gameView: some View {
        SpriteView(
            scene: gameManager.colonyScene,
            preferredFramesPerSecond: 60,
            options: [.allowsTransparency, .ignoresSiblingOrder],
            debugOptions: []
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Overlays
    @ViewBuilder
    private func overlayView(for overlay: OverlayType) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { currentOverlay = nil }
            
            switch overlay {
            case .buildMenu:
                BuildMenuView(isPresented: binding(for: overlay))
                    .environmentObject(gameManager)
            case .colonistDetail(let colonist):
                ColonistDetailView(colonist: colonist, isPresented: binding(for: overlay))
            case .research:
                ResearchTreeView(isPresented: binding(for: overlay))
                    .environmentObject(gameManager)
            case .battlePass:
                BattlePassView(isPresented: binding(for: overlay))
                    .environmentObject(gameManager)
            case .gacha:
                GachaView(isPresented: binding(for: overlay))
                    .environmentObject(gameManager)
            case .settings:
                SettingsView(isPresented: binding(for: overlay))
            case .shop:
                ShopView(isPresented: binding(for: overlay))
                    .environmentObject(gameManager)
            }
        }
    }
    
    private func binding(for overlay: OverlayType) -> Binding<Bool> {
        Binding(
            get: { currentOverlay != nil },
            set: { if !$0 { currentOverlay = nil } }
        )
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @Binding var isPresented: Bool
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 20
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "0a0a1a"),
                    Color(hex: "1a0a2a"),
                    Color(hex: "0a1a0a")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                VStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .orange.opacity(0.6), radius: 20)
                    
                    Text("POCKET COLONY")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("UNDERGROUND")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                        .tracking(8)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // Subtitle
                Text("Derinlere İn. Kolonini Kur. Hayatta Kal.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .offset(y: subtitleOffset)
                    .opacity(logoOpacity)
                
                Spacer()
                
                // Dokunarak başla
                Text("Dokunarak Başla")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .opacity(logoOpacity)
                    .scaleEffect(logoOpacity > 0.8 ? 1 : 0.9)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: logoOpacity)
                    .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            HapticsService.shared.impact(.medium)
            withAnimation(.easeOut(duration: 0.5)) {
                isPresented = false
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
                subtitleOffset = 0
            }
        }
    }
}

// MARK: - Shop View (basit)
struct ShopView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("💎 Mağaza")
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
                
                ScrollView {
                    VStack(spacing: 12) {
                        ShopItemRow(gems: 100, price: "$0.99", icon: "💎", highlight: false)
                        ShopItemRow(gems: 600, price: "$4.99", icon: "💎💎", highlight: true)
                        ShopItemRow(gems: 1500, price: "$9.99", icon: "💎💎💎", highlight: false)
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // VIP
                        VStack(spacing: 8) {
                            Text("👑 VIP Üyelik")
                                .font(.headline)
                                .foregroundColor(.yellow)
                            Text("Reklamsız + Günlük 50 Gem + %20 Hız Bonusu")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("$9.99/ay")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.yellow.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 400)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e"))
            )
            .padding()
        }
    }
}

struct ShopItemRow: View {
    let gems: Int
    let price: String
    let icon: String
    let highlight: Bool
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title)
            VStack(alignment: .leading) {
                Text("\(gems) Gem")
                    .font(.headline)
                    .foregroundColor(.white)
                if highlight {
                    Text("En Popüler!")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            Spacer()
            Button(action: {
                HapticsService.shared.impact(.medium)
            }) {
                Text(price)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(highlight ? Color.orange : Color.blue)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}