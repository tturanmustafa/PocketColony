//
//  ResearchItem.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// ResearchDefinitions.swift
// Araştırma ağacı tanımlamaları

import Foundation

struct ResearchItem: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let metalCost: Int
    let crystalCost: Int
    let researchTime: TimeInterval // saniye
    let prerequisites: [String]   // Gereken araştırmalar
    let effects: [ResearchEffect]
    let tier: Int // 1-4
}

enum ResearchEffect {
    case unlockRoom(RoomType)
    case productionBoost(ResourceType, multiplier: Double)
    case defenseBoost(multiplier: Double)
    case maxDepthIncrease(amount: Int)
    case colonistHealRate(multiplier: Double)
    case offlineEfficiency(multiplier: Double)
    case storageIncrease(amount: Double)
    case turretDamageBoost(multiplier: Double)
    case turretRangeBoost(multiplier: Double)
}

// MARK: - Tüm Araştırmalar
let allResearchItems: [ResearchItem] = [
    // Tier 1 - Başlangıç
    ResearchItem(
        id: "medicine",
        name: "Tıp Bilimi",
        icon: "💊",
        description: "Revir inşa etmeyi açar. Kolonistler daha hızlı iyileşir.",
        metalCost: 500,
        crystalCost: 0,
        researchTime: 300,
        prerequisites: [],
        effects: [.unlockRoom(.medbay), .colonistHealRate(multiplier: 2.0)],
        tier: 1
    ),
    ResearchItem(
        id: "radar_tech",
        name: "Radar Teknolojisi",
        icon: "📡",
        description: "Radar inşa etmeyi açar. Düşmanları önceden tespit et.",
        metalCost: 800,
        crystalCost: 0,
        researchTime: 450,
        prerequisites: [],
        effects: [.unlockRoom(.radar)],
        tier: 1
    ),
    ResearchItem(
        id: "weapon_crafting",
        name: "Silah Üretimi",
        icon: "⚔️",
        description: "Silah Atölyesi açar. Taretlerin hasarını artır.",
        metalCost: 600,
        crystalCost: 0,
        researchTime: 360,
        prerequisites: [],
        effects: [.unlockRoom(.workshop), .turretDamageBoost(multiplier: 1.25)],
        tier: 1
    ),
    
    // Tier 2 - Orta
    ResearchItem(
        id: "crystal_extraction",
        name: "Kristal Çıkarımı",
        icon: "💎",
        description: "Kristal Lab açar. Derinlerdeki kristalleri işle.",
        metalCost: 1000,
        crystalCost: 50,
        researchTime: 600,
        prerequisites: ["advanced_mining"],
        effects: [.unlockRoom(.crystalLab)],
        tier: 2
    ),
    ResearchItem(
        id: "trade_routes",
        name: "Ticaret Yolları",
        icon: "🏪",
        description: "Ticaret Noktası açar. Yüzeyle kaynak ticareti yap.",
        metalCost: 1200,
        crystalCost: 30,
        researchTime: 720,
        prerequisites: [],
        effects: [.unlockRoom(.tradingPost)],
        tier: 2
    ),
    ResearchItem(
        id: "advanced_mining",
        name: "İleri Madencilik",
        icon: "⛏️",
        description: "Maden üretimi 2 katına çıkar.",
        metalCost: 700,
        crystalCost: 0,
        researchTime: 480,
        prerequisites: [],
        effects: [.productionBoost(.metal, multiplier: 2.0)],
        tier: 2
    ),
    
    // Tier 3 - İleri
    ResearchItem(
        id: "fortification",
        name: "Tahkimat",
        icon: "🏰",
        description: "Duvarlar ve tüm binalar 2 kat dayanıklı.",
        metalCost: 900,
        crystalCost: 30,
        researchTime: 540,
        prerequisites: ["weapon_crafting"],
        effects: [.defenseBoost(multiplier: 2.0)],
        tier: 3
    ),
    ResearchItem(
        id: "automation",
        name: "Otomasyon",
        icon: "🤖",
        description: "Atanmamış odalar %50 verimle çalışır (normalde %30).",
        metalCost: 1500,
        crystalCost: 80,
        researchTime: 900,
        prerequisites: ["advanced_mining"],
        effects: [.offlineEfficiency(multiplier: 1.7)],
        tier: 3
    ),
    ResearchItem(
        id: "expanded_storage",
        name: "Genişletilmiş Depolama",
        icon: "📦",
        description: "Tüm kaynak kapasiteleri +500.",
        metalCost: 800,
        crystalCost: 40,
        researchTime: 600,
        prerequisites: [],
        effects: [.storageIncrease(amount: 500)],
        tier: 3
    ),
    
    // Tier 4 - Master
    ResearchItem(
        id: "deep_drill",
        name: "Derin Sondaj",
        icon: "🔩",
        description: "Maksimum derinlik +20 kat.",
        metalCost: 2000,
        crystalCost: 100,
        researchTime: 1200,
        prerequisites: ["advanced_mining", "crystal_extraction"],
        effects: [.maxDepthIncrease(amount: 20)],
        tier: 4
    ),
    ResearchItem(
        id: "bioengineering",
        name: "Biyomühendislik",
        icon: "🧬",
        description: "Kolonist iyileşme hızı 3 katına çıkar.",
        metalCost: 2500,
        crystalCost: 150,
        researchTime: 1500,
        prerequisites: ["medicine"],
        effects: [.colonistHealRate(multiplier: 3.0)],
        tier: 4
    ),
    ResearchItem(
        id: "laser_turrets",
        name: "Lazer Taretler",
        icon: "🔫",
        description: "Taretler %50 daha fazla hasar ve menzil.",
        metalCost: 3000,
        crystalCost: 200,
        researchTime: 1800,
        prerequisites: ["weapon_crafting", "fortification"],
        effects: [
            .turretDamageBoost(multiplier: 1.5),
            .turretRangeBoost(multiplier: 1.5)
        ],
        tier: 4
    ),
    ResearchItem(
        id: "quantum_farming",
        name: "Kuantum Tarım",
        icon: "🌿",
        description: "Yiyecek ve su üretimi 3 katına çıkar.",
        metalCost: 2000,
        crystalCost: 120,
        researchTime: 1200,
        prerequisites: ["automation"],
        effects: [
            .productionBoost(.food, multiplier: 3.0),
            .productionBoost(.water, multiplier: 3.0)
        ],
        tier: 4
    ),
]

// MARK: - Gacha Pool
struct GachaHero {
    let name: String
    let title: String
    let rarity: Rarity
    let primarySkill: ColonistSkill
    let specialAbility: String
    let lore: String
}

let gachaPool: [GachaHero] = [
    // Legendary
    GachaHero(name: "Atlas", title: "Yeraltı Kahramanı", rarity: .legendary, primarySkill: .combat,
              specialAbility: "Tüm taretlere +50% hasar", lore: "Yüzey savaşlarının efsanevi generali."),
    GachaHero(name: "Nova", title: "Kristal Büyücüsü", rarity: .legendary, primarySkill: .science,
              specialAbility: "Kristal üretimi x3", lore: "Kristallerin sırlarını çözen dahi bilim insanı."),
    
    // Epic
    GachaHero(name: "Rüzgar", title: "Hızlı Madenci", rarity: .epic, primarySkill: .mining,
              specialAbility: "Maden hızı x2", lore: "Elleri kazıyı seven tecrübeli bir madenci."),
    GachaHero(name: "Yıldız", title: "Şef Healer", rarity: .epic, primarySkill: .medicine,
              specialAbility: "Tüm kolonistler +20 HP/dk", lore: "Savaş meydanında yetişmiş bir savaş hemşiresi."),
    GachaHero(name: "Kaya", title: "Baş Mühendis", rarity: .epic, primarySkill: .engineering,
              specialAbility: "İnşaat hızı x1.5", lore: "Her şeyi tamir edebilen mekanik deha."),
    GachaHero(name: "Nehir", title: "Çiftçi Kraliçesi", rarity: .epic, primarySkill: .farming,
              specialAbility: "Yiyecek üretimi x2", lore: "Çorak toprakta bile mahsul yetiştirebilir."),
    
    // Rare
    GachaHero(name: "Deniz", title: "Keşifçi", rarity: .rare, primarySkill: .mining,
              specialAbility: "Nadir kaynak bulma +20%", lore: "Karanlık tünellerin cesur kaşifi."),
    GachaHero(name: "Ece", title: "Araştırmacı", rarity: .rare, primarySkill: .science,
              specialAbility: "Araştırma hızı +30%", lore: "Merakı asla bitmeyen genç bilim insanı."),
    GachaHero(name: "Can", title: "Nişancı", rarity: .rare, primarySkill: .combat,
              specialAbility: "Taret menzili +25%", lore: "Gözünden hiçbir şey kaçmaz."),
]