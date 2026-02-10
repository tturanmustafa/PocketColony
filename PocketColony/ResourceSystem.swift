//
//  ResourceSystem.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// ResourceSystem.swift
// Kaynak üretimi ve tüketimi

import Foundation

class ResourceSystem {
    func update(gameState: inout GameState) {
        // Üretim
        for room in gameState.rooms where room.isBuilt {
            let efficiency = calculateEfficiency(room: room, colonists: gameState.colonists)
            
            switch room.type {
            case .farm:
                gameState.addResource(.food, amount: GameBalance.baseFoodProduction * efficiency * Double(room.level))
            case .waterPump:
                gameState.addResource(.water, amount: GameBalance.baseWaterProduction * efficiency * Double(room.level))
            case .generator:
                gameState.addResource(.energy, amount: GameBalance.baseEnergyProduction * efficiency * Double(room.level))
            case .mine:
                gameState.addResource(.metal, amount: GameBalance.baseMetalProduction * efficiency * Double(room.level))
            case .crystalLab:
                gameState.addResource(.crystal, amount: GameBalance.baseCrystalProduction * efficiency * Double(room.level))
            default:
                break
            }
        }
        
        // Tüketim (kolonist başına)
        let aliveColonists = gameState.colonists.filter { $0.isAlive }
        let foodCost = GameBalance.foodConsumptionPerColonist * Double(aliveColonists.count)
        let waterCost = GameBalance.waterConsumptionPerColonist * Double(aliveColonists.count)
        let energyCost = GameBalance.energyConsumptionPerColonist * Double(aliveColonists.count)
        
        _ = gameState.spendResource(.food, amount: foodCost)
        _ = gameState.spendResource(.water, amount: waterCost)
        _ = gameState.spendResource(.energy, amount: energyCost)
        
        // Kaynak kapasitesini vault'larla artır
        let vaultCount = gameState.rooms.filter { $0.type == .vault && $0.isBuilt }.count
        let vaultBonus = Double(vaultCount) * 200
        for type in [ResourceType.food, .water, .metal] {
            gameState.resourceCapacity[type] = 500 + vaultBonus
        }
    }
    
    private func calculateEfficiency(room: Room, colonists: [Colonist]) -> Double {
        let assigned = colonists.filter { $0.assignedRoomID == room.id && $0.isAlive }
        if assigned.isEmpty { return 0.3 } // Atanmamış = %30 verim
        
        let relevantSkill: ColonistSkill = {
            switch room.type {
            case .farm, .cafeteria: return .farming
            case .mine: return .mining
            case .crystalLab, .laboratory: return .science
            case .medbay: return .medicine
            case .generator, .turretBay, .workshop: return .engineering
            default: return .farming
            }
        }()
        
        let totalSkill = assigned.reduce(0.0) { $0 + $1.effectiveSkill(relevantSkill) }
        let avgSkill = totalSkill / Double(assigned.count)
        let happinessMultiplier = assigned.reduce(0.0) { $0 + $1.happiness } / Double(assigned.count) / 100
        
        return min(3.0, (avgSkill / 50.0) * happinessMultiplier * Double(assigned.count))
    }
}

// MARK: - BuildSystem
class BuildSystem {
    func update(gameState: inout GameState) {
        for i in gameState.rooms.indices {
            guard !gameState.rooms[i].isBuilt, let startDate = gameState.rooms[i].buildStartDate else { continue }
            
            let cost = RoomCost.cost(for: gameState.rooms[i].type, level: gameState.rooms[i].level)
            let elapsed = Date().timeIntervalSince(startDate)
            let progress = min(1.0, elapsed / cost.buildTime)
            
            gameState.rooms[i].buildProgress = progress
            
            if progress >= 1.0 {
                gameState.rooms[i].isBuilt = true
                gameState.rooms[i].buildProgress = 1.0
            }
        }
    }
}

// MARK: - CombatSystem
class CombatSystem {
    var activeEnemies: [Enemy] = []
    
    func update(gameState: inout GameState, scene: ColonyScene) {
        guard gameState.isUnderAttack else { return }
        
        // Taretler ateş etsin
        let turrets = gameState.rooms.filter { $0.type == .turretBay && $0.isBuilt }
        
        for turret in turrets {
            let turretPos = scene.gridToWorld(x: turret.gridX, y: turret.gridY)
            
            // En yakın düşmanı bul
            if let nearestIndex = activeEnemies.indices.min(by: {
                let pos1 = CGPoint(x: activeEnemies[$0].positionX, y: activeEnemies[$0].positionY)
                let pos2 = CGPoint(x: activeEnemies[$1].positionX, y: activeEnemies[$1].positionY)
                return distance(turretPos, pos1) < distance(turretPos, pos2)
            }) {
                let dist = distance(turretPos, CGPoint(
                    x: activeEnemies[nearestIndex].positionX,
                    y: activeEnemies[nearestIndex].positionY
                ))
                
                if dist <= GameBalance.baseTurretRange * CGFloat(turret.level) {
                    let damage = GameBalance.baseTurretDamage * Double(turret.level)
                    let combatColonists = gameState.colonists.filter { $0.assignedRoomID == turret.id }
                    let skillBonus = combatColonists.reduce(0.0) { $0 + $1.effectiveSkill(.combat) } / 50
                    
                    activeEnemies[nearestIndex].health -= damage * (1 + skillBonus)
                    
                    if activeEnemies[nearestIndex].health <= 0 {
                        activeEnemies[nearestIndex].isAlive = false
                        scene.removeEnemyNode(activeEnemies[nearestIndex].id)
                        
                        // Ödüller
                        let stats = EnemyStats.stats(for: activeEnemies[nearestIndex].type)
                        for (resource, amount) in stats.reward {
                            gameState.addResource(resource, amount: amount)
                        }
                    }
                }
            }
        }
        
        // Savaşçı kolonistler de saldırsın
        let fighters = gameState.colonists.filter { $0.state == .fighting && $0.isAlive }
        for fighter in fighters {
            if let nearestIndex = activeEnemies.indices.filter({ activeEnemies[$0].isAlive }).first {
                let combatPower = fighter.effectiveSkill(.combat) / 10
                activeEnemies[nearestIndex].health -= combatPower
            }
        }
        
        // Düşmanlar odalara saldırsın
        for i in activeEnemies.indices where activeEnemies[i].isAlive {
            // Hedef odaya doğru ilerle
            if let targetID = activeEnemies[i].targetRoomID,
               let roomIdx = gameState.rooms.firstIndex(where: { $0.id == targetID }) {
                gameState.rooms[roomIdx].hitPoints -= activeEnemies[i].damage * 0.01
                
                if gameState.rooms[roomIdx].hitPoints <= 0 {
                    // Oda yıkıldı
                    gameState.rooms[roomIdx].hitPoints = 0
                }
            }
        }
        
        // Ölü düşmanları temizle
        activeEnemies.removeAll { !$0.isAlive }
        gameState.waveEnemiesRemaining = activeEnemies.count
        
        // Dalga bitti mi?
        if activeEnemies.isEmpty {
            gameState.isUnderAttack = false
            gameState.totalWavesSurvived += 1
        }
    }
    
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
    }
}

// MARK: - WaveSystem
class WaveSystem {
    private var timeSinceLastWave: TimeInterval = 0
    
    func update(gameState: inout GameState, manager: GameManager) {
        guard !gameState.isUnderAttack else { return }
        
        timeSinceLastWave += GameConstants.tickInterval
        
        if timeSinceLastWave >= GameBalance.baseWaveInterval {
            timeSinceLastWave = 0
            spawnWave(gameState: &gameState, manager: manager)
        }
    }
    
    func spawnWave(gameState: inout GameState, manager: GameManager) {
        gameState.wave += 1
        gameState.isUnderAttack = true
        
        let waveMultiplier = pow(GameBalance.waveScalingFactor, Double(gameState.wave - 1))
        let enemyCount = min(20, 2 + gameState.wave)
        
        var enemies: [Enemy] = []
        
        // Boss her 10. dalga
        if gameState.wave % 10 == 0 {
            let bossType: EnemyType = gameState.wave % 20 == 0 ? .bossQueen : .bossGolem
            let boss = Enemy.create(type: bossType, waveMultiplier: waveMultiplier)
            enemies.append(boss)
        }
        
        for _ in 0..<enemyCount {
            let type: EnemyType
            let roll = Double.random(in: 0...1)
            if gameState.wave < 5 {
                type = .mutantRat
            } else if roll < 0.4 {
                type = .mutantRat
            } else if roll < 0.7 {
                type = .raider
            } else if roll < 0.9 {
                type = .mechDrone
            } else {
                type = .tunnelWorm
            }
            
            var enemy = Enemy.create(type: type, waveMultiplier: waveMultiplier)
            
            // Hedef oda seç
            if let target = gameState.rooms.filter({ $0.isBuilt }).randomElement() {
                enemy.targetRoomID = target.id
            }
            
            enemies.append(enemy)
        }
        
        manager.combatSystem.activeEnemies = enemies
        gameState.waveEnemiesRemaining = enemies.count
        
        // Düşmanları scene'e ekle
        for enemy in enemies {
            let spawnX = CGFloat.random(in: -300 ... -200)
            let spawnY = CGFloat.random(in: -200...100)
            manager.colonyScene.spawnEnemyNode(enemy, at: CGPoint(x: spawnX, y: spawnY))
        }
        
        manager.showToast("⚠️ Dalga \(gameState.wave) geliyor! \(enemies.count) düşman!", type: .warning)
        manager.haptics.notification(.warning)
        
        // Battle Pass XP
        manager.addBattlePassXP(gameState.wave * 5)
    }
}

// MARK: - ColonistAI
class ColonistAI {
    func update(gameState: inout GameState) {
        for i in gameState.colonists.indices where gameState.colonists[i].isAlive {
            var colonist = gameState.colonists[i]
            
            // Açlık/susuzluk azalsın
            colonist.hunger = max(0, colonist.hunger - 0.02)
            colonist.thirst = max(0, colonist.thirst - 0.03)
            
            // Yemek ye (yemekhane varsa)
            if colonist.hunger < 30 && gameState.resource(.food) > 5 {
                colonist.hunger = min(100, colonist.hunger + 20)
                _ = gameState.spendResource(.food, amount: 2)
                colonist.state = .eating
            }
            
            // Su iç
            if colonist.thirst < 30 && gameState.resource(.water) > 3 {
                colonist.thirst = min(100, colonist.thirst + 25)
                _ = gameState.spendResource(.water, amount: 1.5)
            }
            
            // Sağlık
            if colonist.hunger <= 0 || colonist.thirst <= 0 {
                colonist.health -= 0.5
                colonist.happiness = max(0, colonist.happiness - 1)
            } else if colonist.health < 100 {
                let hasMedbay = gameState.rooms.contains { $0.type == .medbay && $0.isBuilt }
                colonist.health = min(100, colonist.health + (hasMedbay ? 0.5 : 0.1))
            }
            
            // Mutluluk
            if colonist.hunger > 50 && colonist.thirst > 50 && colonist.health > 50 {
                colonist.happiness = min(100, colonist.happiness + 0.01)
            } else {
                colonist.happiness = max(0, colonist.happiness - 0.02)
            }
            
            // Savaş durumu
            if gameState.isUnderAttack && colonist.primarySkill == .combat {
                colonist.state = .fighting
            } else if colonist.assignedRoomID != nil && colonist.state != .eating {
                colonist.state = .working
            }
            
            // Deneyim kazanma
            if colonist.state == .working {
                colonist.experience += 0.1 * colonist.rarity.statMultiplier
                if colonist.experience >= colonist.xpToNextLevel {
                    colonist.experience = 0
                    colonist.level += 1
                }
            }
            
            // Ölüm
            if colonist.health <= 0 {
                colonist.isAlive = false
                colonist.state = .dead
            }
            
            gameState.colonists[i] = colonist
        }
    }
}