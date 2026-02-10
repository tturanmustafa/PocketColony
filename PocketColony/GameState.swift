//
//  GameState.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// GameState.swift
// Ana oyun durumu modeli

import Foundation
import Observation

@Observable
class GameState: Codable {
    var playerName: String = "Komutan"
    var colonyName: String = "Yeni Koloni"
    var depth: Int = 1
    var wave: Int = 0
    var day: Int = 1
    var season: Int = 1
    
    // Kaynaklar
    var resources: [ResourceType: Double] = [
        .food: 100,
        .water: 100,
        .energy: 50,
        .metal: 200,
        .crystal: 0,
        .gems: 50
    ]
    
    // Kaynak kapasiteleri
    var resourceCapacity: [ResourceType: Double] = [
        .food: 500,
        .water: 500,
        .energy: 200,
        .metal: 500,
        .crystal: 100,
        .gems: 99999
    ]
    
    // Odalar
    var rooms: [Room] = []
    
    // Kolonistler
    var colonists: [Colonist] = []
    
    // Araştırmalar
    var completedResearch: Set<String> = []
    var currentResearch: String? = nil
    var researchProgress: Double = 0
    
    // Savaş
    var isUnderAttack: Bool = false
    var waveEnemiesRemaining: Int = 0
    var totalWavesSurvived: Int = 0
    
    // Battle Pass
    var battlePassXP: Int = 0
    var battlePassLevel: Int = 0
    var battlePassPurchased: Bool = false
    var claimedRewards: Set<Int> = []
    
    // Gacha
    var gachaPity: Int = 0  // Pity counter
    
    // Meta
    var totalPlayTime: TimeInterval = 0
    var lastSaveDate: Date = Date()
    var createdDate: Date = Date()
    var version: Int = 1
    
    // MARK: - Computed Properties
    var populationCapacity: Int {
        rooms.filter { $0.type == .quarters && $0.isBuilt }
            .reduce(0) { $0 + (2 * $1.level) } + 5 // Komuta merkezi 5 kişi
    }
    
    var populationCount: Int { colonists.count }
    
    var happinessLevel: Double {
        let base = GameBalance.baseHappiness
        let cafeteriasBonus = Double(rooms.filter { $0.type == .cafeteria && $0.isBuilt }.count) * GameBalance.cafeteriaHappinessBonus * 100
        let loungeBonus = Double(rooms.filter { $0.type == .lounge && $0.isBuilt }.count) * GameBalance.loungeHappinessBonus * 100
        let overcrowding = populationCount > populationCapacity ?
            Double(populationCount - populationCapacity) * GameBalance.overcrowdingPenalty * 100 : 0
        return min(100, max(0, base + cafeteriasBonus + loungeBonus - overcrowding))
    }
    
    var defenseRating: Int {
        rooms.filter { $0.category == .defense && $0.isBuilt }
            .reduce(0) { $0 + ($1.level * 10) }
    }
    
    // MARK: - Resource Helpers
    func resource(_ type: ResourceType) -> Double {
        resources[type] ?? 0
    }
    
    func capacity(_ type: ResourceType) -> Double {
        resourceCapacity[type] ?? 0
    }
    
    func addResource(_ type: ResourceType, amount: Double) {
        let current = resources[type] ?? 0
        let cap = resourceCapacity[type] ?? Double.infinity
        resources[type] = min(cap, current + amount)
    }
    
    func spendResource(_ type: ResourceType, amount: Double) -> Bool {
        let current = resources[type] ?? 0
        guard current >= amount else { return false }
        resources[type] = current - amount
        return true
    }
    
    func canAfford(metal: Int, crystal: Int, energy: Int) -> Bool {
        resource(.metal) >= Double(metal) &&
        resource(.crystal) >= Double(crystal) &&
        resource(.energy) >= Double(energy)
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case playerName, colonyName, depth, wave, day, season
        case resources, resourceCapacity, rooms, colonists
        case completedResearch, currentResearch, researchProgress
        case isUnderAttack, waveEnemiesRemaining, totalWavesSurvived
        case battlePassXP, battlePassLevel, battlePassPurchased, claimedRewards
        case gachaPity, totalPlayTime, lastSaveDate, createdDate, version
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerName = try container.decode(String.self, forKey: .playerName)
        colonyName = try container.decode(String.self, forKey: .colonyName)
        depth = try container.decode(Int.self, forKey: .depth)
        wave = try container.decode(Int.self, forKey: .wave)
        day = try container.decode(Int.self, forKey: .day)
        season = try container.decode(Int.self, forKey: .season)
        resources = try container.decode([ResourceType: Double].self, forKey: .resources)
        resourceCapacity = try container.decode([ResourceType: Double].self, forKey: .resourceCapacity)
        rooms = try container.decode([Room].self, forKey: .rooms)
        colonists = try container.decode([Colonist].self, forKey: .colonists)
        completedResearch = try container.decode(Set<String>.self, forKey: .completedResearch)
        currentResearch = try container.decodeIfPresent(String.self, forKey: .currentResearch)
        researchProgress = try container.decode(Double.self, forKey: .researchProgress)
        isUnderAttack = try container.decode(Bool.self, forKey: .isUnderAttack)
        waveEnemiesRemaining = try container.decode(Int.self, forKey: .waveEnemiesRemaining)
        totalWavesSurvived = try container.decode(Int.self, forKey: .totalWavesSurvived)
        battlePassXP = try container.decode(Int.self, forKey: .battlePassXP)
        battlePassLevel = try container.decode(Int.self, forKey: .battlePassLevel)
        battlePassPurchased = try container.decode(Bool.self, forKey: .battlePassPurchased)
        claimedRewards = try container.decode(Set<Int>.self, forKey: .claimedRewards)
        gachaPity = try container.decode(Int.self, forKey: .gachaPity)
        totalPlayTime = try container.decode(TimeInterval.self, forKey: .totalPlayTime)
        lastSaveDate = try container.decode(Date.self, forKey: .lastSaveDate)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        version = try container.decode(Int.self, forKey: .version)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerName, forKey: .playerName)
        try container.encode(colonyName, forKey: .colonyName)
        try container.encode(depth, forKey: .depth)
        try container.encode(wave, forKey: .wave)
        try container.encode(day, forKey: .day)
        try container.encode(season, forKey: .season)
        try container.encode(resources, forKey: .resources)
        try container.encode(resourceCapacity, forKey: .resourceCapacity)
        try container.encode(rooms, forKey: .rooms)
        try container.encode(colonists, forKey: .colonists)
        try container.encode(completedResearch, forKey: .completedResearch)
        try container.encode(currentResearch, forKey: .currentResearch)
        try container.encode(researchProgress, forKey: .researchProgress)
        try container.encode(isUnderAttack, forKey: .isUnderAttack)
        try container.encode(waveEnemiesRemaining, forKey: .waveEnemiesRemaining)
        try container.encode(totalWavesSurvived, forKey: .totalWavesSurvived)
        try container.encode(battlePassXP, forKey: .battlePassXP)
        try container.encode(battlePassLevel, forKey: .battlePassLevel)
        try container.encode(battlePassPurchased, forKey: .battlePassPurchased)
        try container.encode(claimedRewards, forKey: .claimedRewards)
        try container.encode(gachaPity, forKey: .gachaPity)
        try container.encode(totalPlayTime, forKey: .totalPlayTime)
        try container.encode(lastSaveDate, forKey: .lastSaveDate)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(version, forKey: .version)
    }
    
    init() {
        // Default initializer for creating new game states
    }
}

// MARK: - Room Model
struct Room: Codable, Identifiable {
    let id: UUID
    var type: RoomType
    var level: Int
    var gridX: Int          // Grid pozisyonu X (0-4)
    var gridY: Int          // Grid pozisyonu Y (derinlik, 0 = yüzey)
    var isBuilt: Bool       // İnşaat tamamlandı mı
    var buildProgress: Double // 0.0 - 1.0
    var buildStartDate: Date?
    var assignedColonists: [UUID] // Atanmış kolonist ID'leri
    var hitPoints: Double   // Saldırı hasarı
    var maxHitPoints: Double
    
    var category: RoomCategory { type.category }
    var displayName: String { type.displayName }
    
    var buildTimeRemaining: TimeInterval {
        guard let start = buildStartDate, !isBuilt else { return 0 }
        let cost = RoomCost.cost(for: type, level: level)
        let elapsed = Date().timeIntervalSince(start)
        return max(0, cost.buildTime - elapsed)
    }
    
    init(type: RoomType, gridX: Int, gridY: Int, level: Int = 1) {
        self.id = UUID()
        self.type = type
        self.level = level
        self.gridX = gridX
        self.gridY = gridY
        self.isBuilt = type == .commandCenter
        self.buildProgress = type == .commandCenter ? 1.0 : 0.0
        self.buildStartDate = type == .commandCenter ? nil : Date()
        self.assignedColonists = []
        self.maxHitPoints = Double(level * 100)
        self.hitPoints = self.maxHitPoints
    }
}

// MARK: - Colonist Model
struct Colonist: Identifiable {
    let id: UUID
    var name: String
    var rarity: Rarity
    var level: Int
    var experience: Double
    
    // Yetenekler (0-100)
    var skills: [ColonistSkill: Int]
    var primarySkill: ColonistSkill
    
    // Durum
    var health: Double      // 0-100
    var hunger: Double      // 0-100 (100 = tok)
    var thirst: Double      // 0-100 (100 = kana kana)
    var happiness: Double   // 0-100
    var isAlive: Bool
    
    // Atama
    var assignedRoomID: UUID?
    var state: ColonistState
    
    // Görsel
    var skinTone: Int       // 0-5
    var hairStyle: Int      // 0-9
    var outfit: Int         // 0-9
    
    // Explicit initializer for all properties
    init(
        id: UUID,
        name: String,
        rarity: Rarity,
        level: Int,
        experience: Double,
        skills: [ColonistSkill: Int],
        primarySkill: ColonistSkill,
        health: Double,
        hunger: Double,
        thirst: Double,
        happiness: Double,
        isAlive: Bool,
        assignedRoomID: UUID?,
        state: ColonistState,
        skinTone: Int,
        hairStyle: Int,
        outfit: Int
    ) {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.level = level
        self.experience = experience
        self.skills = skills
        self.primarySkill = primarySkill
        self.health = health
        self.hunger = hunger
        self.thirst = thirst
        self.happiness = happiness
        self.isAlive = isAlive
        self.assignedRoomID = assignedRoomID
        self.state = state
        self.skinTone = skinTone
        self.hairStyle = hairStyle
        self.outfit = outfit
    }
    
    var effectiveSkill(_ skill: ColonistSkill) -> Double {
        let base = Double(skills[skill] ?? 1)
        return base * rarity.statMultiplier * (1 + Double(level - 1) * 0.1)
    }
    
    var xpToNextLevel: Double {
        Double(level * level * 100)
    }
    
    static func random(rarity: Rarity) -> Colonist {
        let names: [String] = [
            "Ayşe", "Mehmet", "Zeynep", "Ali", "Elif", "Mustafa",
            "Fatma", "Hasan", "Emine", "Ahmet", "Hatice", "İbrahim",
            "Merve", "Osman", "Yasemin", "Hüseyin", "Esra", "Burak",
            "Seda", "Emre", "Derya", "Can", "Deniz", "Ece",
            "Atlas", "Nova", "Rüzgar", "Yıldız", "Kaya", "Nehir"
        ]
        
        let allSkills = ColonistSkill.allCases
        var skills: [ColonistSkill: Int] = [:]
        let primary = allSkills.randomElement()!
        
        for skill in allSkills {
            let base = skill == primary ? Int.random(in: 50...80) : Int.random(in: 5...40)
            skills[skill] = Int(Double(base) * rarity.statMultiplier)
        }
        
        return Colonist(
            id: UUID(),
            name: names.randomElement()!,
            rarity: rarity,
            level: 1,
            experience: 0,
            skills: skills,
            primarySkill: primary,
            health: 100,
            hunger: 80,
            thirst: 80,
            happiness: 70,
            isAlive: true,
            assignedRoomID: nil,
            state: .idle,
            skinTone: Int.random(in: 0...5),
            hairStyle: Int.random(in: 0...9),
            outfit: Int.random(in: 0...9)
        )
    }
}

// MARK: - Colonist Codable
extension Colonist: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, rarity, level, experience
        case skills, primarySkill
        case health, hunger, thirst, happiness, isAlive
        case assignedRoomID, state
        case skinTone, hairStyle, outfit
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode all properties first
        let decodedId = try container.decode(UUID.self, forKey: .id)
        let decodedName = try container.decode(String.self, forKey: .name)
        let decodedRarity = try container.decode(Rarity.self, forKey: .rarity)
        let decodedLevel = try container.decode(Int.self, forKey: .level)
        let decodedExperience = try container.decode(Double.self, forKey: .experience)
        
        // Decode skills dictionary
        let skillsDict = try container.decode([String: Int].self, forKey: .skills)
        var decodedSkills: [ColonistSkill: Int] = [:]
        for (key, value) in skillsDict {
            if let skill = ColonistSkill(rawValue: key) {
                decodedSkills[skill] = value
            }
        }
        
        let decodedPrimarySkill = try container.decode(ColonistSkill.self, forKey: .primarySkill)
        let decodedHealth = try container.decode(Double.self, forKey: .health)
        let decodedHunger = try container.decode(Double.self, forKey: .hunger)
        let decodedThirst = try container.decode(Double.self, forKey: .thirst)
        let decodedHappiness = try container.decode(Double.self, forKey: .happiness)
        let decodedIsAlive = try container.decode(Bool.self, forKey: .isAlive)
        let decodedAssignedRoomID = try container.decodeIfPresent(UUID.self, forKey: .assignedRoomID)
        let decodedState = try container.decode(ColonistState.self, forKey: .state)
        let decodedSkinTone = try container.decode(Int.self, forKey: .skinTone)
        let decodedHairStyle = try container.decode(Int.self, forKey: .hairStyle)
        let decodedOutfit = try container.decode(Int.self, forKey: .outfit)
        
        // Initialize using the memberwise initializer
        self.init(
            id: decodedId,
            name: decodedName,
            rarity: decodedRarity,
            level: decodedLevel,
            experience: decodedExperience,
            skills: decodedSkills,
            primarySkill: decodedPrimarySkill,
            health: decodedHealth,
            hunger: decodedHunger,
            thirst: decodedThirst,
            happiness: decodedHappiness,
            isAlive: decodedIsAlive,
            assignedRoomID: decodedAssignedRoomID,
            state: decodedState,
            skinTone: decodedSkinTone,
            hairStyle: decodedHairStyle,
            outfit: decodedOutfit
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(level, forKey: .level)
        try container.encode(experience, forKey: .experience)
        
        // Encode skills dictionary
        var skillsDict: [String: Int] = [:]
        for (skill, value) in skills {
            skillsDict[skill.rawValue] = value
        }
        try container.encode(skillsDict, forKey: .skills)
        
        try container.encode(primarySkill, forKey: .primarySkill)
        try container.encode(health, forKey: .health)
        try container.encode(hunger, forKey: .hunger)
        try container.encode(thirst, forKey: .thirst)
        try container.encode(happiness, forKey: .happiness)
        try container.encode(isAlive, forKey: .isAlive)
        try container.encode(assignedRoomID, forKey: .assignedRoomID)
        try container.encode(state, forKey: .state)
        try container.encode(skinTone, forKey: .skinTone)
        try container.encode(hairStyle, forKey: .hairStyle)
        try container.encode(outfit, forKey: .outfit)
    }
}

enum ColonistState: String, Codable {
    case idle       // Boşta
    case working    // Çalışıyor
    case resting    // Dinleniyor
    case eating     // Yemek yiyor
    case fighting   // Savaşıyor
    case injured    // Yaralı
    case dead       // Ölü
}

// MARK: - Enemy Model
struct Enemy: Codable, Identifiable {
    let id: UUID
    var type: EnemyType
    var health: Double
    var maxHealth: Double
    var damage: Double
    var speed: Double
    var positionX: Double
    var positionY: Double
    var targetRoomID: UUID?
    var isAlive: Bool
    
    static func create(type: EnemyType, waveMultiplier: Double) -> Enemy {
        let stats = EnemyStats.stats(for: type)
        return Enemy(
            id: UUID(),
            type: type,
            health: stats.health * waveMultiplier,
            maxHealth: stats.health * waveMultiplier,
            damage: stats.damage * waveMultiplier,
            speed: stats.speed,
            positionX: 0,
            positionY: 0,
            targetRoomID: nil,
            isAlive: true
        )
    }
}

struct EnemyStats {
    let health: Double
    let damage: Double
    let speed: Double
    let reward: [ResourceType: Double]
    
    static func stats(for type: EnemyType) -> EnemyStats {
        switch type {
        case .mutantRat:
            return EnemyStats(health: 30, damage: 5, speed: 3, reward: [.food: 5, .metal: 2])
        case .raider:
            return EnemyStats(health: 80, damage: 15, speed: 2, reward: [.metal: 10, .crystal: 2])
        case .mechDrone:
            return EnemyStats(health: 60, damage: 20, speed: 4, reward: [.metal: 15, .energy: 10])
        case .tunnelWorm:
            return EnemyStats(health: 150, damage: 25, speed: 1.5, reward: [.metal: 20, .crystal: 5])
        case .bossGolem:
            return EnemyStats(health: 500, damage: 40, speed: 1, reward: [.metal: 100, .crystal: 30, .gems: 10])
        case .bossQueen:
            return EnemyStats(health: 800, damage: 30, speed: 0.8, reward: [.crystal: 50, .gems: 20])
        }
    }
}
