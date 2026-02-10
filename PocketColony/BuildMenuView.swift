//
//  BuildMenuView.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// BuildMenuView.swift
// İnşaat menüsü

import SwiftUI

struct BuildMenuView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedCategory: RoomCategory = .production
    @State private var selectedRoom: RoomType? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("🏗️ İnşaat")
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
                
                // Kategori seçici
                HStack(spacing: 8) {
                    ForEach(RoomCategory.allCases, id: \.rawValue) { cat in
                        Button {
                            selectedCategory = cat
                            HapticsService.shared.impact(.light)
                        } label: {
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(selectedCategory == cat ? .white : .gray)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == cat ? cat.color.opacity(0.3) : Color.clear)
                                        .overlay(
                                            Capsule().stroke(cat.color.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal)
                
                // Oda listesi
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(roomsForCategory, id: \.self) { roomType in
                            BuildRoomCard(
                                roomType: roomType,
                                gameState: gameManager.gameState,
                                isSelected: selectedRoom == roomType,
                                onTap: { selectedRoom = roomType },
                                onBuild: { buildRoom(roomType) }
                            )
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 350)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e"))
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
    
    private var roomsForCategory: [RoomType] {
        RoomType.allCases.filter { $0.category == selectedCategory && $0 != .commandCenter }
    }
    
    private func buildRoom(_ type: RoomType) {
        // Sonraki boş grid pozisyonunu bul
        let depth = gameManager.gameState.depth
        for y in 0...depth {
            for x in 0..<GameConstants.columnsCount {
                if !gameManager.gameState.rooms.contains(where: { $0.gridX == x && $0.gridY == y }) {
                    if gameManager.buildRoom(type: type, gridX: x, gridY: y) {
                        isPresented = false
                    }
                    return
                }
            }
        }
        // Yeni kat aç
        let newY = depth
        if gameManager.buildRoom(type: type, gridX: 0, gridY: newY) {
            isPresented = false
        }
    }
}

struct BuildRoomCard: View {
    let roomType: RoomType
    let gameState: GameState
    let isSelected: Bool
    let onTap: () -> Void
    let onBuild: () -> Void
    
    private var cost: RoomCost { RoomCost.cost(for: roomType) }
    private var canAfford: Bool {
        gameState.canAfford(metal: cost.metal, crystal: cost.crystal, energy: cost.energy)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(roomType.icon)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(roomType.displayName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(roomDescription)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    if isSelected {
                        Button(action: onBuild) {
                            Text("İnşa Et")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(canAfford ? Color.green : Color.gray)
                                )
                        }
                        .disabled(!canAfford)
                    }
                }
                
                if isSelected {
                    // Maliyet detayları
                    HStack(spacing: 12) {
                        if cost.metal > 0 {
                            CostLabel(icon: "⛏️", amount: cost.metal, sufficient: gameState.resource(.metal) >= Double(cost.metal))
                        }
                        if cost.crystal > 0 {
                            CostLabel(icon: "💎", amount: cost.crystal, sufficient: gameState.resource(.crystal) >= Double(cost.crystal))
                        }
                        if cost.energy > 0 {
                            CostLabel(icon: "⚡", amount: cost.energy, sufficient: gameState.resource(.energy) >= Double(cost.energy))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(formatTime(cost.buildTime))
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? roomType.category.color.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? roomType.category.color.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
    
    private var roomDescription: String {
        switch roomType {
        case .farm: return "Yiyecek üretir"
        case .waterPump: return "Su çıkarır"
        case .generator: return "Enerji üretir"
        case .mine: return "Metal kazısı"
        case .crystalLab: return "Kristal işler"
        case .quarters: return "Nüfus kapasitesi +2"
        case .medbay: return "Yaralıları iyileştirir"
        case .cafeteria: return "Mutluluk artırır"
        case .lounge: return "Dinlenme alanı"
        case .turretBay: return "Düşmanlara ateş eder"
        case .wall: return "Savunma bariyeri"
        case .radar: return "Erken uyarı sistemi"
        case .workshop: return "Silah & zırh üretir"
        case .commandCenter: return "Koloni merkezi"
        case .laboratory: return "Araştırma yapar"
        case .vault: return "Kaynak depolama +200"
        case .elevator: return "Yeni kata açılır"
        case .tradingPost: return "Kaynak ticareti"
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return "\(Int(seconds))sn" }
        if seconds < 3600 { return "\(Int(seconds/60))dk" }
        return "\(Int(seconds/3600))sa \(Int(seconds.truncatingRemainder(dividingBy: 3600)/60))dk"
    }
}

struct CostLabel: View {
    let icon: String
    let amount: Int
    let sufficient: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            Text(icon).font(.caption)
            Text("\(amount)")
                .font(.caption.bold())
                .foregroundColor(sufficient ? .white : .red)
        }
    }
}

// MARK: - ColonistDetailView
struct ColonistDetailView: View {
    let colonist: Colonist
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("👤 \(colonist.name)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(colonist.rarity.displayName)
                        .font(.caption.bold())
                        .foregroundColor(colonist.rarity.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(colonist.rarity.color.opacity(0.2))
                        )
                    
                    Spacer()
                    
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Durum çubukları
                VStack(spacing: 8) {
                    StatBar(label: "❤️ Sağlık", value: colonist.health, color: .red)
                    StatBar(label: "🍖 Açlık", value: colonist.hunger, color: .orange)
                    StatBar(label: "💧 Susuzluk", value: colonist.thirst, color: .cyan)
                    StatBar(label: "😊 Mutluluk", value: colonist.happiness, color: .yellow)
                }
                .padding(.horizontal)
                
                // Yetenekler
                VStack(alignment: .leading, spacing: 6) {
                    Text("Yetenekler")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(ColonistSkill.allCases, id: \.rawValue) { skill in
                            let value = colonist.skills[skill] ?? 0
                            HStack {
                                Text(skill.icon)
                                    .font(.caption)
                                Text(skill.displayName)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(value)")
                                    .font(.caption.bold())
                                    .foregroundColor(skill == colonist.primarySkill ? .yellow : .white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(skill == colonist.primarySkill ?
                                          Color.yellow.opacity(0.1) : Color.white.opacity(0.05))
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // Seviye & XP
                HStack {
                    Text("Seviye \(colonist.level)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(Color.cyan)
                                .frame(width: geo.size.width * CGFloat(colonist.experience / colonist.xpToNextLevel))
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(Int(colonist.experience))/\(Int(colonist.xpToNextLevel))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
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

struct StatBar: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value / 100))
                }
            }
            .frame(height: 10)
            
            Text("\(Int(value))%")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - ResearchTreeView
struct ResearchTreeView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var gameManager: GameManager
    
    let researchItems: [(id: String, name: String, icon: String, cost: Int, description: String)] = [
        ("medicine", "Tıp Bilimi", "💊", 500, "Revir inşa etmeyi açar"),
        ("radar_tech", "Radar Teknolojisi", "📡", 800, "Radar inşa etmeyi açar"),
        ("weapon_crafting", "Silah Üretimi", "⚔️", 600, "Silah Atölyesi açar"),
        ("crystal_extraction", "Kristal Çıkarımı", "💎", 1000, "Kristal Lab açar"),
        ("trade_routes", "Ticaret Yolları", "🏪", 1200, "Ticaret Noktası açar"),
        ("advanced_mining", "İleri Madencilik", "⛏️", 700, "Maden verimi x2"),
        ("fortification", "Tahkimat", "🏰", 900, "Duvar dayanıklılığı x2"),
        ("automation", "Otomasyon", "🤖", 1500, "Atanmamış oda verimi %50"),
        ("deep_drill", "Derin Sondaj", "🔩", 2000, "Maksimum derinlik +20"),
        ("bioengineering", "Biyomühendislik", "🧬", 2500, "Kolonist iyileşme hızı x3"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                HStack {
                    Text("🧪 Araştırma Ağacı")
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
                    VStack(spacing: 10) {
                        ForEach(researchItems, id: \.id) { item in
                            let isCompleted = gameManager.gameState.completedResearch.contains(item.id)
                            let isActive = gameManager.gameState.currentResearch == item.id
                            
                            HStack {
                                Text(item.icon)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(item.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(isCompleted ? .green : .white)
                                        if isCompleted {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                        }
                                    }
                                    Text(item.description)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    if isActive {
                                        ProgressView(value: gameManager.gameState.researchProgress)
                                            .tint(.purple)
                                    }
                                }
                                
                                Spacer()
                                
                                if !isCompleted && !isActive {
                                    Button {
                                        startResearch(item.id)
                                    } label: {
                                        HStack(spacing: 2) {
                                            Text("⛏️\(item.cost)")
                                                .font(.caption.bold())
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.purple))
                                    }
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isActive ? Color.purple.opacity(0.15) :
                                            isCompleted ? Color.green.opacity(0.08) :
                                            Color.white.opacity(0.05))
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 450)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a2e"))
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
    
    private func startResearch(_ id: String) {
        guard let item = researchItems.first(where: { $0.id == id }),
              gameManager.gameState.resource(.metal) >= Double(item.cost) else {
            gameManager.showToast("❌ Yeterli metal yok!", type: .error)
            return
        }
        _ = gameManager.gameState.spendResource(.metal, amount: Double(item.cost))
        gameManager.gameState.currentResearch = id
        gameManager.gameState.researchProgress = 0
        gameManager.showToast("🔬 \(item.name) araştırılıyor...", type: .info)
    }
}