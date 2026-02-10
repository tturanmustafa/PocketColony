//
//  ColonyScene.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// ColonyScene.swift
// Ana SpriteKit oyun sahnesi

import SpriteKit
import SwiftUI

class ColonyScene: SKScene {
    
    weak var gameManager: GameManager?
    
    // Katmanlar
    private let worldNode = SKNode()
    private let backgroundLayer = SKNode()
    private let roomLayer = SKNode()
    private let colonistLayer = SKNode()
    private let effectsLayer = SKNode()
    private let enemyLayer = SKNode()
    
    // Kamera
    private var cameraNode: SKCameraNode!
    private var lastPanPosition: CGPoint?
    private var currentZoom: CGFloat = 1.0
    
    // Seçim
    var selectedGridPosition: (x: Int, y: Int)?
    var onGridSelected: ((Int, Int) -> Void)?
    var onRoomTapped: ((Room) -> Void)?
    
    let tileSize = GameConstants.tileSize
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 1)
        
        addChild(worldNode)
        worldNode.addChild(backgroundLayer)
        worldNode.addChild(roomLayer)
        worldNode.addChild(colonistLayer)
        worldNode.addChild(enemyLayer)
        worldNode.addChild(effectsLayer)
        
        backgroundLayer.zPosition = 0
        roomLayer.zPosition = 10
        colonistLayer.zPosition = 20
        enemyLayer.zPosition = 30
        effectsLayer.zPosition = 40
        
        setupCamera()
        setupBackground()
        setupGestures(in: view)
        startAmbientEffects()
    }
    
    // MARK: - Camera
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = gridToWorld(x: 2, y: 0)
    }
    
    private func setupGestures(in view: SKView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(tap)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = self.view else { return }
        let translation = gesture.translation(in: view)
        cameraNode.position.x -= translation.x * currentZoom * GameConstants.cameraPanSpeed
        cameraNode.position.y += translation.y * currentZoom * GameConstants.cameraPanSpeed
        gesture.setTranslation(.zero, in: view)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            currentZoom = max(GameConstants.cameraMinZoom,
                           min(GameConstants.cameraMaxZoom, currentZoom / gesture.scale))
            cameraNode.setScale(currentZoom)
            gesture.scale = 1.0
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = self.view else { return }
        let viewPoint = gesture.location(in: view)
        let scenePoint = convertPoint(fromView: viewPoint)
        let worldPoint = worldNode.convert(scenePoint, from: self)
        
        // Grid pozisyonunu hesapla
        let gridX = Int(round(worldPoint.x / (tileSize * CGFloat(GameConstants.roomWidth))))
        let gridY = Int(round(-worldPoint.y / (tileSize * CGFloat(GameConstants.roomHeight))))
        
        // Mevcut oda var mı kontrol et
        if let room = gameManager?.gameState.rooms.first(where: { $0.gridX == gridX && $0.gridY == gridY }) {
            onRoomTapped?(room)
            highlightRoom(at: gridX, y: gridY, color: .cyan)
        } else if gridX >= 0 && gridX < GameConstants.columnsCount && gridY >= 0 {
            selectedGridPosition = (gridX, gridY)
            onGridSelected?(gridX, gridY)
            highlightRoom(at: gridX, y: gridY, color: .yellow)
        }
    }
    
    private func highlightRoom(at x: Int, y: Int, color: SKColor) {
        effectsLayer.childNode(withName: "highlight")?.removeFromParent()
        
        let width = tileSize * CGFloat(GameConstants.roomWidth)
        let height = tileSize * CGFloat(GameConstants.roomHeight)
        let highlight = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 8)
        highlight.strokeColor = color
        highlight.fillColor = color.withAlphaComponent(0.1)
        highlight.lineWidth = 2
        highlight.name = "highlight"
        highlight.position = gridToWorld(x: x, y: y)
        effectsLayer.addChild(highlight)
        
        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.3, duration: 0.5),
            .fadeAlpha(to: 1.0, duration: 0.5)
        ])
        highlight.run(.repeatForever(pulse))
        
        // 3 saniye sonra kaldır
        highlight.run(.sequence([.wait(forDuration: 3), .fadeOut(withDuration: 0.3), .removeFromParent()]))
    }
    
    // MARK: - Background
    private func setupBackground() {
        for depth in 0..<30 {
            let width = CGFloat(GameConstants.columnsCount + 2) * tileSize * CGFloat(GameConstants.roomWidth)
            let height = tileSize * CGFloat(GameConstants.roomHeight)
            let layerNode = SKShapeNode(rectOf: CGSize(width: width, height: height))
            
            let darkness = min(1.0, CGFloat(depth) * 0.03)
            layerNode.fillColor = SKColor(
                red: max(0, 0.12 - darkness * 0.1),
                green: max(0, 0.08 - darkness * 0.06),
                blue: max(0, 0.15 - darkness * 0.08),
                alpha: 1
            )
            layerNode.strokeColor = SKColor(white: 0.15, alpha: 0.3)
            layerNode.lineWidth = 0.5
            layerNode.position = CGPoint(
                x: CGFloat(2) * tileSize * CGFloat(GameConstants.roomWidth),
                y: -CGFloat(depth) * height
            )
            backgroundLayer.addChild(layerNode)
            
            // Toprak dokusu
            for _ in 0..<(8 + depth) {
                let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
                dot.fillColor = SKColor(white: CGFloat.random(in: 0.1...0.2), alpha: 0.3)
                dot.strokeColor = .clear
                dot.position = CGPoint(
                    x: CGFloat.random(in: -width/2...width/2),
                    y: CGFloat.random(in: -height/2...height/2)
                )
                layerNode.addChild(dot)
            }
        }
        
        // Yüzey çizgisi
        let surfaceLine = SKShapeNode(rectOf: CGSize(
            width: 2000, height: 3
        ))
        surfaceLine.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.2, alpha: 0.9)
        surfaceLine.strokeColor = .clear
        surfaceLine.position = CGPoint(x: tileSize * 6, y: tileSize + 10)
        backgroundLayer.addChild(surfaceLine)
    }
    
    // MARK: - Room Management
    func addRoomNode(_ room: Room) {
        let node = createRoomNode(room)
        node.name = "room_\(room.id.uuidString)"
        node.position = gridToWorld(x: room.gridX, y: room.gridY)
        roomLayer.addChild(node)
        
        if !room.isBuilt {
            node.alpha = 0.5
            addBuildSparks(to: node)
        } else {
            // Pop-in animasyonu
            node.setScale(0.01)
            node.run(.scale(to: 1.0, duration: 0.3))
        }
    }
    
    private func createRoomNode(_ room: Room) -> SKNode {
        let container = SKNode()
        let w = tileSize * CGFloat(GameConstants.roomWidth) - 4
        let h = tileSize * CGFloat(GameConstants.roomHeight) - 4
        
        // Oda arka planı
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 8)
        bg.fillColor = roomColor(for: room.type)
        bg.strokeColor = roomBorder(for: room.type)
        bg.lineWidth = 2
        bg.name = "bg"
        container.addChild(bg)
        
        // İkon
        let icon = SKLabelNode(text: room.type.icon)
        icon.fontSize = 28
        icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: 8)
        container.addChild(icon)
        
        // İsim
        let name = SKLabelNode(text: room.type.displayName)
        name.fontName = "AvenirNext-Bold"
        name.fontSize = 10
        name.fontColor = .white
        name.verticalAlignmentMode = .center
        name.position = CGPoint(x: 0, y: -18)
        container.addChild(name)
        
        // Seviye
        if room.level > 1 {
            let lvl = SKLabelNode(text: "⭐\(room.level)")
            lvl.fontName = "AvenirNext-Bold"
            lvl.fontSize = 9
            lvl.fontColor = .yellow
            lvl.horizontalAlignmentMode = .right
            lvl.position = CGPoint(x: w/2 - 6, y: h/2 - 14)
            container.addChild(lvl)
        }
        
        return container
    }
    
    private func roomColor(for type: RoomType) -> SKColor {
        switch type.category {
        case .production: return SKColor(red: 0.08, green: 0.18, blue: 0.08, alpha: 0.95)
        case .living:     return SKColor(red: 0.08, green: 0.12, blue: 0.22, alpha: 0.95)
        case .defense:    return SKColor(red: 0.22, green: 0.08, blue: 0.08, alpha: 0.95)
        case .special:    return SKColor(red: 0.15, green: 0.08, blue: 0.22, alpha: 0.95)
        }
    }
    
    private func roomBorder(for type: RoomType) -> SKColor {
        switch type.category {
        case .production: return SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 0.7)
        case .living:     return SKColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 0.7)
        case .defense:    return SKColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 0.7)
        case .special:    return SKColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 0.7)
        }
    }
    
    func completeRoomBuild(_ roomID: UUID) {
        guard let node = roomLayer.childNode(withName: "room_\(roomID.uuidString)") else { return }
        node.childNode(withName: "buildSparks")?.removeFromParent()
        node.alpha = 1.0
        node.run(.sequence([.scale(to: 1.15, duration: 0.15), .scale(to: 1.0, duration: 0.15)]))
        addBurstEffect(at: node.position, color: .yellow, count: 12)
    }
    
    // MARK: - Colonist Nodes
    func addColonistNode(_ colonist: Colonist) {
        let node = createMiniColonist(colonist)
        node.name = "colonist_\(colonist.id.uuidString)"
        
        if let roomID = colonist.assignedRoomID,
           let roomNode = roomLayer.childNode(withName: "room_\(roomID.uuidString)") {
            node.position = roomNode.position + CGPoint(
                x: CGFloat.random(in: -25...25), y: CGFloat.random(in: -8...8))
        } else {
            node.position = gridToWorld(x: 2, y: 0) + CGPoint(
                x: CGFloat.random(in: -40...40), y: CGFloat.random(in: -15...15))
        }
        colonistLayer.addChild(node)
        addIdleAnimation(to: node)
    }
    
    private func createMiniColonist(_ colonist: Colonist) -> SKNode {
        let container = SKNode()
        
        // Gövde
        let body = SKShapeNode(rectOf: CGSize(width: 8, height: 14), cornerRadius: 2)
        let skinColors: [SKColor] = [
            .init(red: 0.96, green: 0.87, blue: 0.7, alpha: 1),
            .init(red: 0.87, green: 0.72, blue: 0.53, alpha: 1),
            .init(red: 0.76, green: 0.6, blue: 0.42, alpha: 1),
            .init(red: 0.55, green: 0.38, blue: 0.25, alpha: 1),
            .init(red: 0.4, green: 0.26, blue: 0.15, alpha: 1),
            .init(red: 0.3, green: 0.2, blue: 0.12, alpha: 1),
        ]
        body.fillColor = skinColors[min(colonist.skinTone, 5)]
        body.strokeColor = .clear
        container.addChild(body)
        
        // Kafa
        let head = SKShapeNode(circleOfRadius: 5)
        head.fillColor = body.fillColor
        head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 12)
        container.addChild(head)
        
        // Gözler
        for dx: CGFloat in [-2, 2] {
            let eye = SKShapeNode(circleOfRadius: 1)
            eye.fillColor = .white
            eye.strokeColor = .clear
            eye.position = CGPoint(x: dx, y: 13)
            container.addChild(eye)
        }
        
        // Nadirlik glow
        if colonist.rarity != .common {
            let glow = SKShapeNode(circleOfRadius: 14)
            let c: SKColor = {
                switch colonist.rarity {
                case .uncommon:  return .green
                case .rare:      return .cyan
                case .epic:      return .purple
                case .legendary: return .orange
                default:         return .clear
                }
            }()
            glow.fillColor = c.withAlphaComponent(0.15)
            glow.strokeColor = c.withAlphaComponent(0.4)
            glow.lineWidth = 1
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.3, duration: 1), .fadeAlpha(to: 0.8, duration: 1)
            ])))
            container.addChild(glow)
        }
        
        return container
    }
    
    private func addIdleAnimation(to node: SKNode) {
        let bob = SKAction.sequence([
            .moveBy(x: 0, y: 2, duration: 0.8),
            .moveBy(x: 0, y: -2, duration: 0.8)
        ])
        let wander = SKAction.sequence([
            .moveBy(x: CGFloat.random(in: -10...10), y: 0, duration: 2),
            .wait(forDuration: Double.random(in: 1...3)),
            .moveBy(x: CGFloat.random(in: -10...10), y: 0, duration: 2)
        ])
        node.run(.repeatForever(bob), withKey: "bob")
        node.run(.repeatForever(wander), withKey: "wander")
    }
    
    // MARK: - Enemy Nodes
    func spawnEnemyNode(_ enemy: Enemy, at position: CGPoint) {
        let node = SKNode()
        node.name = "enemy_\(enemy.id.uuidString)"
        node.position = position
        
        let body = SKShapeNode(rectOf: CGSize(width: 14, height: 14), cornerRadius: 3)
        body.fillColor = .red
        body.strokeColor = SKColor(red: 1, green: 0.3, blue: 0.3, alpha: 0.8)
        body.lineWidth = 1
        node.addChild(body)
        
        let icon = SKLabelNode(text: enemy.type == .mutantRat ? "🐀" : enemy.type == .raider ? "💀" : "🤖")
        icon.fontSize = 16
        icon.verticalAlignmentMode = .center
        node.addChild(icon)
        
        // HP bar
        let hpBg = SKShapeNode(rectOf: CGSize(width: 20, height: 3), cornerRadius: 1)
        hpBg.fillColor = SKColor(red: 0.3, green: 0, blue: 0, alpha: 0.8)
        hpBg.strokeColor = .clear
        hpBg.position = CGPoint(x: 0, y: 14)
        hpBg.name = "hpBg"
        node.addChild(hpBg)
        
        let hpFill = SKShapeNode(rectOf: CGSize(width: 20, height: 3), cornerRadius: 1)
        hpFill.fillColor = .red
        hpFill.strokeColor = .clear
        hpFill.position = CGPoint(x: 0, y: 14)
        hpFill.name = "hpFill"
        node.addChild(hpFill)
        
        enemyLayer.addChild(node)
    }
    
    func removeEnemyNode(_ enemyID: UUID) {
        guard let node = enemyLayer.childNode(withName: "enemy_\(enemyID.uuidString)") else { return }
        addBurstEffect(at: node.position, color: .red, count: 8)
        node.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
    }
    
    // MARK: - Effects
    private func addBuildSparks(to node: SKNode) {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 3
        emitter.particleLifetime = 1
        emitter.particleSize = CGSize(width: 2, height: 2)
        emitter.particleColor = .orange
        emitter.particleColorBlendFactor = 1
        emitter.particleAlphaSpeed = -1
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        emitter.particleSpeed = 20
        emitter.name = "buildSparks"
        node.addChild(emitter)
    }
    
    private func addBurstEffect(at position: CGPoint, color: SKColor, count: Int) {
        for _ in 0..<count {
            let p = SKShapeNode(circleOfRadius: 2)
            p.fillColor = color
            p.strokeColor = .clear
            p.position = position
            p.zPosition = 50
            effectsLayer.addChild(p)
            
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 30...80)
            p.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.4),
                    .fadeOut(withDuration: 0.4)
                ]),
                .removeFromParent()
            ]))
        }
    }
    
    private func startAmbientEffects() {
        // Parçacık efektleri - toz zerreleri
        run(.repeatForever(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in
                guard let self else { return }
                let dust = SKShapeNode(circleOfRadius: 1)
                dust.fillColor = SKColor(white: 0.5, alpha: 0.3)
                dust.strokeColor = .clear
                let camPos = self.cameraNode.position
                dust.position = CGPoint(
                    x: camPos.x + CGFloat.random(in: -200...200),
                    y: camPos.y + CGFloat.random(in: -300...300)
                )
                dust.zPosition = 5
                self.effectsLayer.addChild(dust)
                dust.run(.sequence([
                    .group([
                        .moveBy(x: CGFloat.random(in: -20...20), y: -30, duration: 3),
                        .fadeOut(withDuration: 3)
                    ]),
                    .removeFromParent()
                ]))
            }
        ])))
    }
    
    // MARK: - Visual Updates
    func updateVisuals(with state: GameState) {
        // İnşaat ilerlemesi güncelle
        for room in state.rooms where !room.isBuilt {
            if room.buildProgress >= 1.0 {
                completeRoomBuild(room.id)
            }
        }
    }
    
    // MARK: - Helpers
    func gridToWorld(x: Int, y: Int) -> CGPoint {
        CGPoint(
            x: CGFloat(x) * tileSize * CGFloat(GameConstants.roomWidth),
            y: -CGFloat(y) * tileSize * CGFloat(GameConstants.roomHeight)
        )
    }
}

// CGPoint extension
func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}