//
//  GameConstants.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// Constants.swift
// Oyun sabitleri, denge ayarları ve konfigürasyon

import Foundation
import SwiftUI

// MARK: - Ekran & Dünya
enum GameConstants {
    static let tileSize: CGFloat = 64
    static let roomWidth: Int = 3        // Oda genişliği (tile cinsinden)
    static let roomHeight: Int = 2       // Oda yüksekliği
    static let maxDepth: Int = 100       // Maksimum derinlik
    static let columnsCount: Int = 5     // Yatayda 5 kolon
    static let autoSaveInterval: TimeInterval = 30
    static let tickInterval: TimeInterval = 1.0  // 1 saniyede bir güncelleme
    
    // Kamera
    static let cameraMinZoom: CGFloat = 0.3
    static let cameraMaxZoom: CGFloat = 1.5
    static let cameraPanSpeed: CGFloat = 1.2
}

// MARK: - Kaynak Türleri
enum ResourceType: String, Codable, CaseIterable, Identifiable {
    case food       // Yiyecek
    case water      // Su
    case energy     // Enerji
    case metal      // Metal
    case crystal    // Kristal (premium kaynak)
    case gems       // Gem (premium para)
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .food: return "Yiyecek"
        case .water: return "Su"
        case .energy: return "Enerji"
        case .metal: return "Metal"
        case .crystal: return "Kristal"
        case .gems: return "Gem"
        }
    }
    
    var icon: String {
        switch self {
        case .food: return "🌾"
        case .water: return "💧"
        case .energy: return "⚡"
        case .metal: return "⛏️"
        case .crystal: return "💎"
        case .gems: return "💠"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .green
        case .water: return .cyan
        case .energy: return .yellow
        case .metal: return .gray
        case .crystal: return .purple
        case .gems: return .blue
        }
    }
}

// MARK: - Oda Türleri
enum RoomType: String, Codable, CaseIterable, Identifiable {
    // Üretim
    case farm           // Yiyecek üret
    case waterPump      // Su çıkar
    case generator      // Enerji üret
    case mine           // Metal kaz
    case crystalLab     // Kristal işle
    
    // Yaşam
    case quarters       // Yaşam alanı (nüfus kapasitesi)
    case medbay         // Sağlık merkezi
    case cafeteria      // Yemekhane (mutluluk)
    case lounge         // Dinlenme alanı (mutluluk)
    
    // Savunma
    case turretBay      // Taret yuvası
    case wall           // Duvar
    case radar          // Radar (erken uyarı)
    case workshop       // Silah atölyesi
    
    // Özel
    case commandCenter  // Komuta merkezi (başlangıç)
    case laboratory     // Araştırma laboratuvarı
    case vault          // Kasa (kaynak depolama)
    case elevator       // Asansör (katlar arası)
    case tradingPost    // Ticaret noktası
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .farm: return "Çiftlik"
        case .waterPump: return "Su Pompası"
        case .generator: return "Jeneratör"
        case .mine: return "Maden"
        case .crystalLab: return "Kristal Lab"
        case .quarters: return "Yaşam Alanı"
        case .medbay: return "Revir"
        case .cafeteria: return "Yemekhane"
        case .lounge: return "Dinlenme Odası"
        case .turretBay: return "Taret Yuvası"
        case .wall: return "Duvar"
        case .radar: return "Radar"
        case .workshop: return "Silah Atölyesi"
        case .commandCenter: return "Komuta Merkezi"
        case .laboratory: return "Laboratuvar"
        case .vault: return "Kasa"
        case .elevator: return "Asansör"
        case .tradingPost: return "Ticaret Noktası"
        }
    }
    
    var icon: String {
        switch self {
        case .farm: return "🌱"
        case .waterPump: return "🚰"
        case .generator: return "🔋"
        case .mine: return "⛏️"
        case .crystalLab: return "🔬"
        case .quarters: return "🏠"
        case .medbay: return "🏥"
        case .cafeteria: return "🍽️"
        case .lounge: return "🛋️"
        case .turretBay: return "🔫"
        case .wall: return "🧱"
        case .radar: return "📡"
        case .workshop: return "🔧"
        case .commandCenter: return "🏛️"
        case .laboratory: return "🧪"
        case .vault: return "🏦"
        case .elevator: return "🛗"
        case .tradingPost: return "🏪"
        }
    }
    
    var category: RoomCategory {
        switch self {
        case .farm, .waterPump, .generator, .mine, .crystalLab:
            return .production
        case .quarters, .medbay, .cafeteria, .lounge:
            return .living
        case .turretBay, .wall, .radar, .workshop:
            return .defense
        case .commandCenter, .laboratory, .vault, .elevator, .tradingPost:
            return .special
        }
    }
}

enum RoomCategory: String, CaseIterable {
    case production = "Üretim"
    case living = "Yaşam"
    case defense = "Savunma"
    case special = "Özel"
    
    var color: Color {
        switch self {
        case .production: return .green
        case .living: return .blue
        case .defense: return .red
        case .special: return .purple
        }
    }
}

// MARK: - Kolonist Nadirlikleri (Gacha)
enum Rarity: String, Codable, CaseIterable {
    case common     // Yaygın - %60
    case uncommon   // Nadir Değil - %25
    case rare       // Nadir - %10
    case epic       // Destansı - %4
    case legendary  // Efsanevi - %1
    
    var displayName: String {
        switch self {
        case .common: return "Yaygın"
        case .uncommon: return "Sıradışı"
        case .rare: return "Nadir"
        case .epic: return "Destansı"
        case .legendary: return "Efsanevi"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var glowColor: Color {
        switch self {
        case .common: return .clear
        case .uncommon: return .green.opacity(0.3)
        case .rare: return .blue.opacity(0.4)
        case .epic: return .purple.opacity(0.5)
        case .legendary: return .orange.opacity(0.6)
        }
    }
    
    var statMultiplier: Double {
        switch self {
        case .common: return 1.0
        case .uncommon: return 1.25
        case .rare: return 1.5
        case .epic: return 2.0
        case .legendary: return 3.0
        }
    }
    
    var gachaProbability: Double {
        switch self {
        case .common: return 0.60
        case .uncommon: return 0.25
        case .rare: return 0.10
        case .epic: return 0.04
        case .legendary: return 0.01
        }
    }
}

// MARK: - Kolonist Yetenekleri
enum ColonistSkill: String, Codable, CaseIterable {
    case farming    // Çiftçilik
    case mining     // Madencilik
    case combat     // Savaş
    case science    // Bilim
    case medicine   // Tıp
    case cooking    // Yemek
    case engineering // Mühendislik
    
    var displayName: String {
        switch self {
        case .farming: return "Çiftçilik"
        case .mining: return "Madencilik"
        case .combat: return "Savaş"
        case .science: return "Bilim"
        case .medicine: return "Tıp"
        case .cooking: return "Yemek"
        case .engineering: return "Mühendislik"
        }
    }
    
    var icon: String {
        switch self {
        case .farming: return "🌾"
        case .mining: return "⛏️"
        case .combat: return "⚔️"
        case .science: return "🔬"
        case .medicine: return "💊"
        case .cooking: return "🍳"
        case .engineering: return "🔧"
        }
    }
}

// MARK: - Düşman Türleri
enum EnemyType: String, Codable {
    case mutantRat      // Mutant Fare
    case raider         // Akıncı
    case mechDrone      // Mekanik Drone
    case tunnelWorm     // Tünel Solucanı
    case bossGolem      // Boss: Taş Golem
    case bossQueen      // Boss: Böcek Kraliçesi
    
    var displayName: String {
        switch self {
        case .mutantRat: return "Mutant Fare"
        case .raider: return "Akıncı"
        case .mechDrone: return "Mekanik Drone"
        case .tunnelWorm: return "Tünel Solucanı"
        case .bossGolem: return "Taş Golem"
        case .bossQueen: return "Böcek Kraliçesi"
        }
    }
}

// MARK: - Oyun Dengesi
enum GameBalance {
    // Kaynak üretim hızları (birim/saniye)
    static let baseFoodProduction: Double = 0.5
    static let baseWaterProduction: Double = 0.4
    static let baseEnergyProduction: Double = 0.3
    static let baseMetalProduction: Double = 0.2
    static let baseCrystalProduction: Double = 0.05
    
    // Tüketim (kolonist başına/saniye)
    static let foodConsumptionPerColonist: Double = 0.1
    static let waterConsumptionPerColonist: Double = 0.08
    static let energyConsumptionPerColonist: Double = 0.05
    
    // İnşaat süreleri (saniye)
    static let baseBuildTime: TimeInterval = 30
    static let buildTimeMultiplierPerLevel: Double = 1.5
    
    // Savaş
    static let baseWaveInterval: TimeInterval = 180  // 3 dakikada bir dalga
    static let waveScalingFactor: Double = 1.15       // Her dalga %15 daha zor
    static let baseTurretDamage: Double = 10
    static let baseTurretRange: CGFloat = 200
    static let baseTurretFireRate: TimeInterval = 1.0
    
    // Mutluluk
    static let baseHappiness: Double = 50
    static let happinessDecayRate: Double = 0.01  // saniye başına
    static let cafeteriaHappinessBonus: Double = 0.05
    static let loungeHappinessBonus: Double = 0.03
    static let overcrowdingPenalty: Double = 0.1
    
    // Gacha
    static let singlePullCost: Int = 100  // 100 gem
    static let tenPullCost: Int = 900     // 900 gem (1 bedava)
    static let guaranteedEpicPity: Int = 50    // 50 çekilişte garanti epic
    static let guaranteedLegendaryPity: Int = 100 // 100 çekilişte garanti legendary
    
    // Offline ilerleme
    static let maxOfflineHours: Double = 8
    static let offlineEfficiency: Double = 0.5  // %50 verimlilik
    
    // Battle Pass
    static let battlePassLevels: Int = 50
    static let xpPerLevel: Int = 1000
    static let seasonDurationDays: Int = 30
}

// MARK: - İnşaat Maliyetleri
struct RoomCost {
    let metal: Int
    let crystal: Int
    let energy: Int
    let buildTime: TimeInterval // saniye
    let requiredDepth: Int      // minimum derinlik
    let requiredResearch: String? // gereken araştırma
    
    static func cost(for type: RoomType, level: Int = 1) -> RoomCost {
        let multiplier = pow(1.5, Double(level - 1))
        
        switch type {
        case .farm:
            return RoomCost(metal: Int(50 * multiplier), crystal: 0, energy: Int(10 * multiplier), buildTime: 30 * multiplier, requiredDepth: 0, requiredResearch: nil)
        case .waterPump:
            return RoomCost(metal: Int(60 * multiplier), crystal: 0, energy: Int(15 * multiplier), buildTime: 45 * multiplier, requiredDepth: 0, requiredResearch: nil)
        case .generator:
            return RoomCost(metal: Int(80 * multiplier), crystal: 0, energy: 0, buildTime: 60 * multiplier, requiredDepth: 0, requiredResearch: nil)
        case .mine:
            return RoomCost(metal: Int(40 * multiplier), crystal: 0, energy: Int(20 * multiplier), buildTime: 45 * multiplier, requiredDepth: 2, requiredResearch: nil)
        case .crystalLab:
            return RoomCost(metal: Int(200 * multiplier), crystal: Int(50 * multiplier), energy: Int(100 * multiplier), buildTime: 300 * multiplier, requiredDepth: 10, requiredResearch: "crystal_extraction")
        case .quarters:
            return RoomCost(metal: Int(30 * multiplier), crystal: 0, energy: Int(5 * multiplier), buildTime: 20 * multiplier, requiredDepth: 0, requiredResearch: nil)
        case .medbay:
            return RoomCost(metal: Int(100 * multiplier), crystal: Int(20 * multiplier), energy: Int(30 * multiplier), buildTime: 120 * multiplier, requiredDepth: 3, requiredResearch: "medicine")
        case .cafeteria:
            return RoomCost(metal: Int(70 * multiplier), crystal: 0, energy: Int(20 * multiplier), buildTime: 60 * multiplier, requiredDepth: 1, requiredResearch: nil)
        case .lounge:
            return RoomCost(metal: Int(60 * multiplier), crystal: Int(10 * multiplier), energy: Int(15 * multiplier), buildTime: 45 * multiplier, requiredDepth: 2, requiredResearch: nil)
        case .turretBay:
            return RoomCost(metal: Int(120 * multiplier), crystal: Int(30 * multiplier), energy: Int(40 * multiplier), buildTime: 90 * multiplier, requiredDepth: 1, requiredResearch: nil)
        case .wall:
            return RoomCost(metal: Int(80 * multiplier), crystal: 0, energy: 0, buildTime: 15 * multiplier, requiredDepth: 0, requiredResearch: nil)
        case .radar:
            return RoomCost(metal: Int(150 * multiplier), crystal: Int(40 * multiplier), energy: Int(60 * multiplier), buildTime: 180 * multiplier, requiredDepth: 5, requiredResearch: "radar_tech")
        case .workshop:
            return RoomCost(metal: Int(100 * multiplier), crystal: Int(25 * multiplier), energy: Int(35 * multiplier), buildTime: 120 * multiplier, requiredDepth: 3, requiredResearch: "weapon_crafting")
        case .commandCenter:
            return RoomCost(metal: 0, crystal: 0, energy: 0, buildTime: 0, requiredDepth: 0, requiredResearch: nil)
        case .laboratory:
            return RoomCost(metal: Int(150 * multiplier), crystal: Int(50 * multiplier), energy: Int(50 * multiplier), buildTime: 180 * multiplier, requiredDepth: 3, requiredResearch: nil)
        case .vault:
            return RoomCost(metal: Int(200 * multiplier), crystal: Int(30 * multiplier), energy: Int(20 * multiplier), buildTime: 120 * multiplier, requiredDepth: 2, requiredResearch: nil)
        case .elevator:
            return RoomCost(metal: Int(100 * multiplier), crystal: 0, energy: Int(50 * multiplier), buildTime: 60 * multiplier, requiredDepth: 0, requiredResearch: nil)
        case .tradingPost:
            return RoomCost(metal: Int(180 * multiplier), crystal: Int(40 * multiplier), energy: Int(40 * multiplier), buildTime: 150 * multiplier, requiredDepth: 5, requiredResearch: "trade_routes")
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}