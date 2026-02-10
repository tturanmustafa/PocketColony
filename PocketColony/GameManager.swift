//
//  GameManager.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// GameManager.swift
// Merkezi oyun yöneticisi - tüm sistemleri koordine eder

import Foundation
import SwiftUI
import SpriteKit
import Combine
import Observation

@Observable
class GameManager: ObservableObject {
    static let shared = GameManager()
    
    // Core
    var gameState: GameState = GameState()
    var colonyScene: ColonyScene!
    var isInitialized = false
    
    // Sistemler
    let resourceSystem = ResourceSystem()
    let buildSystem = BuildSystem()
    let combatSystem = CombatSystem()
    let waveSystem = WaveSystem()
    let colonistAI = ColonistAI()
    
    // Servisler
    let cloudKit = CloudKitService.shared
    let haptics = HapticsService.shared
    
    // Zamanlayıcılar
    private var gameTimer: Timer?
    private var autoSaveTimer: Timer?
    private var isPaused = false
    
    // Toast mesajları
    var toastMessages: [ToastMessage] = []
    
    private init() {
        colonyScene = ColonyScene(size: UIScreen.main.bounds.size)
        colonyScene.scaleMode = .resizeFill
        colonyScene.gameManager = self
    }
    
    // MARK: - Başlatma
    func initialize() async {
        // CloudKit'ten yükle veya yeni oyun
        if let savedState = loadLocalState() {
            gameState = savedState
            calculateOfflineProgress()
        } else {
            setupNewGame()
        }
        
        // Scene'i kur
        await MainActor.run {
            colonyScene.setupColony(with: gameState)
            startGameLoop()
            isInitialized = true
        }
    }
    
    // MARK: - Yeni Oyun
    func setupNewGame() {
        gameState = GameState()
        
        // Başlangıç odaları
        let commandCenter = Room(type: .commandCenter, gridX: 2, gridY: 0)
        let firstQuarters = Room(type: .quarters, gridX: 1, gridY: 0)
        let firstFarm = Room(type: .farm, gridX: 3, gridY: 0)
        
        gameState.rooms = [commandCenter, firstQuarters, firstFarm]
        
        // Başlangıç kolonistleri
        for _ in 0..<3 {
            var colonist = Colonist.random(rarity: .common)
            colonist.state = .idle
            gameState.colonists.append(colonist)
        }
        
        // Başlangıç kaynakları
        gameState.resources = [
            .food: 100,
            .water: 100,
            .energy: 50,
            .metal: 200,
            .crystal: 0,
            .gems: 50
        ]
        
        showToast("🏗️ Kolonin kuruldu! Derinlere inmeye hazır ol.", type: .info)
    }
    
    // MARK: - Oyun Döngüsü
    func startGameLoop() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: GameConstants.tickInterval, repeats: true) { [weak self] _ in
            guard let self, !self.isPaused else { return }
            self.gameTick()
        }
        
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: GameConstants.autoSaveInterval, repeats: true) { [weak self] _ in
            self?.saveGame()
        }
    }
    
    func gameTick() {
        // 1. Kaynak üretimi
        resourceSystem.update(gameState: &gameState)
        
        // 2. İnşaat ilerlemesi
        buildSystem.update(gameState: &gameState)
        
        // 3. Kolonist AI
        colonistAI.update(gameState: &gameState)
        
        // 4. Dalga sistemi
        waveSystem.update(gameState: &gameState, manager: self)
        
        // 5. Savaş
        if gameState.isUnderAttack {
            combatSystem.update(gameState: &gameState, scene: colonyScene)
        }
        
        // 6. Gün sayacı
        gameState.totalPlayTime += GameConstants.tickInterval
        if Int(gameState.totalPlayTime) % 300 == 0 { // Her 5 dakikada 1 gün
            gameState.day += 1
        }
        
        // 7. Scene güncelle
        colonyScene.updateVisuals(with: gameState)
    }
    
    // MARK: - İnşaat
    func buildRoom(type: RoomType, gridX: Int, gridY: Int) -> Bool {
        let cost = RoomCost.cost(for: type)
        
        // Maliyet kontrolü
        guard gameState.canAfford(metal: cost.metal, crystal: cost.crystal, energy: cost.energy) else {
            showToast("❌ Yeterli kaynak yok!", type: .error)
            haptics.notification(.error)
            return false
        }
        
        // Pozisyon kontrolü
        guard !gameState.rooms.contains(where: { $0.gridX == gridX && $0.gridY == gridY }) else {
            showToast("❌ Bu alan dolu!", type: .error)
            return false
        }
        
        // Derinlik kontrolü
        guard gridY <= gameState.depth else {
            showToast("❌ Önce asansör ile derinleş!", type: .error)
            return false
        }
        
        // Kaynakları harca
        _ = gameState.spendResource(.metal, amount: Double(cost.metal))
        _ = gameState.spendResource(.crystal, amount: Double(cost.crystal))
        _ = gameState.spendResource(.energy, amount: Double(cost.energy))
        
        // Odayı ekle
        let room = Room(type: type, gridX: gridX, gridY: gridY)
        gameState.rooms.append(room)
        
        // Derinliği güncelle
        if gridY >= gameState.depth {
            gameState.depth = gridY + 1
        }
        
        // Scene'e ekle
        colonyScene.addRoomNode(room)
        
        showToast("\(type.icon) \(type.displayName) inşa ediliyor...", type: .success)
        haptics.impact(.medium)
        
        // Battle Pass XP
        addBattlePassXP(25)
        
        return true
    }
    
    // MARK: - Oda Yükseltme
    func upgradeRoom(_ room: Room) -> Bool {
        guard let index = gameState.rooms.firstIndex(where: { $0.id == room.id }) else { return false }
        
        let nextLevel = room.level + 1
        let cost = RoomCost.cost(for: room.type, level: nextLevel)
        
        guard gameState.canAfford(metal: cost.metal, crystal: cost.crystal, energy: cost.energy) else {
            showToast("❌ Yükseltme için kaynak yetersiz!", type: .error)
            return false
        }
        
        _ = gameState.spendResource(.metal, amount: Double(cost.metal))
        _ = gameState.spendResource(.crystal, amount: Double(cost.crystal))
        _ = gameState.spendResource(.energy, amount: Double(cost.energy))
        
        gameState.rooms[index].level = nextLevel
        gameState.rooms[index].maxHitPoints = Double(nextLevel * 100)
        gameState.rooms[index].hitPoints = gameState.rooms[index].maxHitPoints
        
        showToast("⬆️ \(room.type.displayName) Seviye \(nextLevel)!", type: .success)
        haptics.impact(.heavy)
        addBattlePassXP(50)
        
        return true
    }
    
    // MARK: - Kolonist Atama
    func assignColonist(_ colonist: Colonist, to room: Room) {
        guard let colonistIndex = gameState.colonists.firstIndex(where: { $0.id == colonist.id }),
              let roomIndex = gameState.rooms.firstIndex(where: { $0.id == room.id }) else { return }
        
        // Eski odadan çıkar
        if let oldRoomID = colonist.assignedRoomID,
           let oldIndex = gameState.rooms.firstIndex(where: { $0.id == oldRoomID }) {
            gameState.rooms[oldIndex].assignedColonists.removeAll { $0 == colonist.id }
        }
        
        // Yeni odaya ata
        gameState.colonists[colonistIndex].assignedRoomID = room.id
        gameState.colonists[colonistIndex].state = .working
        gameState.rooms[roomIndex].assignedColonists.append(colonist.id)
        
        haptics.impact(.light)
    }
    
    // MARK: - Gacha
    func performGachaPull(count: Int = 1) -> [Colonist] {
        let cost = count == 10 ? GameBalance.tenPullCost : GameBalance.singlePullCost * count
        guard gameState.spendResource(.gems, amount: Double(cost)) else {
            showToast("💎 Yeterli Gem yok!", type: .error)
            return []
        }
        
        var results: [Colonist] = []
        
        for _ in 0..<count {
            gameState.gachaPity += 1
            
            let rarity: Rarity
            if gameState.gachaPity >= GameBalance.guaranteedLegendaryPity {
                rarity = .legendary
                gameState.gachaPity = 0
            } else if gameState.gachaPity >= GameBalance.guaranteedEpicPity &&
                        gameState.gachaPity % GameBalance.guaranteedEpicPity == 0 {
                rarity = .epic
            } else {
                rarity = rollRarity()
            }
            
            let colonist = Colonist.random(rarity: rarity)
            results.append(colonist)
            gameState.colonists.append(colonist)
            
            if rarity == .legendary || rarity == .epic {
                gameState.gachaPity = rarity == .legendary ? 0 : gameState.gachaPity
                showToast("✨ \(rarity.displayName) kahraman bulundu: \(colonist.name)!", type: .legendary)
                haptics.notification(.success)
            }
        }
        
        addBattlePassXP(count * 10)
        return results
    }
    
    private func rollRarity() -> Rarity {
        let roll = Double.random(in: 0...1)
        var cumulative: Double = 0
        for rarity in Rarity.allCases {
            cumulative += rarity.gachaProbability
            if roll <= cumulative { return rarity }
        }
        return .common
    }
    
    // MARK: - İnşaat Hızlandırma
    func speedUpBuild(room: Room, gemCost: Int) -> Bool {
        guard gameState.spendResource(.gems, amount: Double(gemCost)) else {
            showToast("💎 Yeterli Gem yok!", type: .error)
            return false
        }
        
        guard let index = gameState.rooms.firstIndex(where: { $0.id == room.id }) else { return false }
        
        gameState.rooms[index].isBuilt = true
        gameState.rooms[index].buildProgress = 1.0
        
        colonyScene.completeRoomBuild(room.id)
        showToast("⚡ \(room.type.displayName) anında tamamlandı!", type: .success)
        haptics.notification(.success)
        
        return true
    }
    
    // MARK: - Battle Pass
    func addBattlePassXP(_ amount: Int) {
        gameState.battlePassXP += amount
        let requiredXP = GameBalance.xpPerLevel
        while gameState.battlePassXP >= requiredXP {
            gameState.battlePassXP -= requiredXP
            gameState.battlePassLevel += 1
            showToast("🎖️ Battle Pass Seviye \(gameState.battlePassLevel)!", type: .info)
        }
    }
    
    // MARK: - Offline İlerleme
    func calculateOfflineProgress() {
        let now = Date()
        let elapsed = now.timeIntervalSince(gameState.lastSaveDate)
        let cappedHours = min(elapsed / 3600, GameBalance.maxOfflineHours)
        let offlineSeconds = cappedHours * 3600 * GameBalance.offlineEfficiency
        
        guard offlineSeconds > 60 else { return } // En az 1 dakika
        
        // Kaynak üretimini hesapla
        let ticks = Int(offlineSeconds / GameConstants.tickInterval)
        for _ in 0..<ticks {
            resourceSystem.update(gameState: &gameState)
        }
        
        let hours = Int(cappedHours)
        let minutes = Int((cappedHours - Double(hours)) * 60)
        showToast("⏰ \(hours)s \(minutes)dk boyunca kaynaklar toplandı!", type: .info)
    }
    
    // MARK: - Kayıt/Yükleme
    func saveGame() {
        gameState.lastSaveDate = Date()
        
        if let data = try? JSONEncoder().encode(gameState) {
            UserDefaults.standard.set(data, forKey: "pocket_colony_save")
        }
        
        // CloudKit'e async kaydet
        Task {
            await cloudKit.saveGameState(gameState)
        }
    }
    
    func loadLocalState() -> GameState? {
        guard let data = UserDefaults.standard.data(forKey: "pocket_colony_save"),
              let state = try? JSONDecoder().decode(GameState.self, from: data) else {
            return nil
        }
        return state
    }
    
    // MARK: - Pause/Resume
    func pauseGame() {
        isPaused = true
    }
    
    func resumeGame() {
        isPaused = false
    }
    
    // MARK: - Toast
    func showToast(_ message: String, type: ToastType) {
        let toast = ToastMessage(message: message, type: type)
        toastMessages.append(toast)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.toastMessages.removeAll { $0.id == toast.id }
        }
    }
}

// MARK: - Toast
struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    let timestamp = Date()
}

enum ToastType {
    case info, success, error, warning, legendary
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .legendary: return .purple
        }
    }
}