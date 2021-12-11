import SpriteKit
import GameController

final class GameScene: SKScene, SKPhysicsContactDelegate, HapticsManagerDelegate {
    func didConnect(controller: GCController) {
        didConnectController()
    }

    let ahapFiles = [
        "Hit",
        "Hit",
        "Hit",
        "Hit",
        "Triple",
        "Rumble",
        "Recharge",
        "Heartbeats"
    ]

    let ahapLocalities = [
        GCHapticsLocality.default,
        GCHapticsLocality.all,
        GCHapticsLocality.leftHandle,
        GCHapticsLocality.rightHandle,
        GCHapticsLocality.default,
        GCHapticsLocality.default,
        GCHapticsLocality.default,
        GCHapticsLocality.default
    ]

    private let manager = HapticsManager()
    private let player = SKSpriteNode(imageNamed: "player")
    private let waves = Bundle.main.decode([Wave].self, from: "waves.json")
    private let enemyTypes = Bundle.main.decode([EnemyType].self, from: "enemy-types.json")
    private let positions = Array(stride(from: -320, through: 320, by: 80))
    private let playerSpeed: Float = 10
    private var isPlayerAlive = true
    private var levelNumber = 0
    private var waveNumber = 0
    private var playerShields = 100000
    private var canShoot = true

    override func didMove(to view: SKView) {
        setupPhysics()
        setupBackground()
        setupPlayer()
        addObservers()
        manager.delegate = self
    }

    override func update(_ currentTime: TimeInterval) {
        removeOutOfBoundsEntities()
        createWaveIfNeeded()
        makeEnemyShootIfNeeded(for: currentTime)
        movePlayerIfNeeded()
        constraintPlayerToScreen()
    }

    private func constraintPlayerToScreen() {
        if player.position.x > frame.maxX {
            player.position.x = frame.minX
        } else if player.position.x < frame.minX {
            player.position.x = frame.maxX
        }

        if player.position.y > frame.maxY {
            player.position.y = frame.minY
        } else if player.position.y < frame.minY {
            player.position.y = frame.maxY
        }
    }

    private func movePlayerIfNeeded() {
        for controller in GCController.controllers() {
            guard let gamepad = controller.extendedGamepad else { return }
            let amountVertically = gamepad.leftThumbstick.yAxis.value
            let amountHorizontally = gamepad.leftThumbstick.xAxis.value

            movePlayer(dx: CGFloat(amountHorizontally), dy: CGFloat(amountVertically))

            var rotationY = gamepad.rightThumbstick.yAxis.value
            print("Rotation Y: \(rotationY)")
            var rotationX = gamepad.rightThumbstick.xAxis.value
            print("Rotation X: \(rotationX)")

            if abs(rotationY) <= 0.1 {
                rotationY = 0
            }

            if abs(rotationX) <= 0.1 {
                rotationX = 0
            }

            let rotationAngle = atan(rotationY / rotationX)

            if rotationX < 0 {
                rotatePlayer(to: .pi + CGFloat(rotationAngle))
                return
            }

            if rotationX == 0 {
                if rotationY > 0 {
                    print("Angle is 90?")
                    rotatePlayer(to: .pi/2)
                } else if rotationY < 0 {
                    print("angle is -90?")
                    rotatePlayer(to: -.pi/2)
                } else { return }
            } else {
                print("angle is \(rotationAngle)")
                rotatePlayer(to: CGFloat(rotationAngle))

            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        shootIfPossible()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node,
              let nodeB = contact.bodyB.node else { return }

        let sortedNodes = [nodeA, nodeB].sorted { $0.name ?? "" < $1.name ?? "" }
        let firstNode = sortedNodes[0]
        let secondNode = sortedNodes[1]

        // Player got hit by enemy weapon
        if secondNode.name == "player" {
            hitPlayer(at: secondNode)
            createExplosion(at: firstNode)

        // Player hit the enemy (with itself or weapon)
        } else if let enemy = firstNode as? EnemyNode {
            hitEnemy(enemy)
            secondNode.removeFromParent()

        // Bullet hit bullet
        } else {
            createExplosion(at: secondNode)
            firstNode.removeFromParent()
            secondNode.removeFromParent()
        }
    }

    private func updateAdaptiveTriggers() {
        for controller in GCController.controllers() {
            guard let rightTrigger = controller.extendedGamepad?.rightTrigger as? GCDualSenseAdaptiveTrigger else { return }
            rightTrigger.setModeWeaponWithStartPosition(0.4, endPosition: 0.6, resistiveStrength: 1)
        }
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didConnectController), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnectController), name: .GCControllerDidDisconnect, object: nil)
    }

    @objc private func didConnectController() {
        print("Controller connected!")
        updateAdaptiveTriggers()
        var indexNumber = 0
        for controller in GCController.controllers() {
            if controller.extendedGamepad == nil { return }

            controller.playerIndex = GCControllerPlayerIndex.init(rawValue: indexNumber)!
            indexNumber += 1

            setupControllerControls(controller: controller)
        }
    }

    @objc func didDisconnectController() {
        print("Controller disconnected :(")
    }

    private func setupControllerControls(controller: GCController) {
        controller.extendedGamepad?.valueChangedHandler = {
            (gamepad: GCExtendedGamepad, element: GCControllerElement) in
            self.controllerInputDetected(gamepad: gamepad, element: element, index: controller.playerIndex.rawValue)
        }
    }

    private func controllerInputDetected(gamepad: GCExtendedGamepad, element: GCControllerElement, index: Int) {
        if gamepad.rightTrigger.value <= 0.4 {
            canShoot = true
        } else if gamepad.rightTrigger.value >= 0.7 && canShoot {
            shootIfPossible()
            manager.playHapticsFile(named: ahapFiles[0], locality: ahapLocalities[3])
        }
    }

    private func movePlayer(dx: CGFloat, dy: CGFloat) {
        player.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
    }

    private func movePlayerVertically(by amount: Float) {
        player.position.y += CGFloat(amount)
    }

    private func movePlayerHorizontally(by amount: Float) {
        player.position.x += CGFloat(amount)
    }

    private func rotatePlayer(to radians: CGFloat) {
        player.zRotation = radians
    }

    private func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }

    private func setupBackground() {
        guard let particles = SKEmitterNode(fileNamed: "Starfield") else { return }
        particles.position = CGPoint(x: frame.maxY * 1.5, y: 0)
        particles.advanceSimulationTime(15)
        particles.zPosition = -1
        addChild(particles)
    }

    private func setupPlayer() {
        player.name = "player"
        player.position.x = max(frame.minX, frame.minY) + player.frame.width
        player.position.y = frame.midY
        player.zPosition = 1
        addChild(player)

        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody!.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody!.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.isDynamic = true
        player.physicsBody?.linearDamping = 0.95
        player.physicsBody?.angularDamping = 0.95
        player.setScale(0.5)
    }

    private func shootIfPossible() {
        canShoot = false
        guard isPlayerAlive else { return }
        let shot = SKSpriteNode(imageNamed: "playerWeapon")
        shot.name = "playerWeapon"
        shot.position = player.position
        shot.zRotation = player.zRotation

        shot.physicsBody = SKPhysicsBody(rectangleOf: shot.size)
        shot.physicsBody?.categoryBitMask = CollisionType.playerWeapon.rawValue
        shot.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        shot.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        shot.setScale(0.5)
        addChild(shot)

        let speed: CGFloat = 20
        let adjustedRotation = player.zRotation

        let dx = speed * cos(adjustedRotation)
        let dy = speed * sin(adjustedRotation)

        shot.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
    }

    private func removeOutOfBoundsEntities() {
        for child in children {
            if child.frame.maxX < 0 {
                if !frame.intersects(child.frame) {
                    child.removeFromParent()
                }
            }
        }
    }

    private func createWaveIfNeeded() {
        let activeEnemies = children.compactMap { $0 as? EnemyNode}
        if activeEnemies.isEmpty {
            createWave()
        }
    }

    private func makeEnemyShootIfNeeded(for currentTime: TimeInterval) {
        let activeEnemies = children.compactMap { $0 as? EnemyNode}
        for enemy in activeEnemies {
            guard frame.intersects(enemy.frame) else { continue }

            if enemy.lastFireTime + 1 < currentTime && Int.random(in: enemy.type.shootingChance...10) == 10 {
                enemy.lastFireTime = currentTime
                enemy.fire()
            }
        }
    }

    private func createExplosion(at node: SKNode) {
        if let explosion = SKEmitterNode(fileNamed: "Explosion") {
            explosion.position = node.position
            addChild(explosion)
            node.removeFromParent()
        }
    }

    private func hitPlayer(at node: SKNode) {
        guard isPlayerAlive else { return }
        playerShields -= 1

        if playerShields <= 0 {
            createExplosion(at: player)
            gameOver()
        }
    }

    private func hitEnemy(_ enemy: EnemyNode) {
        enemy.shields -= 1
        createExplosion(at: enemy)
        if enemy.shields <= 0 {
            enemy.removeFromParent()
        }
    }

    private func createWave() {
        guard isPlayerAlive else { return }

        if waveNumber == waves.count {
            levelNumber += 1
            waveNumber = 0
        }
        let currentWave = waves[waveNumber]
        waveNumber += 1

        let maximumEnemyType = min(enemyTypes.count, levelNumber + 1)
        let enemyType = Int.random(in: 0..<maximumEnemyType)
        let enemyOffsetX: CGFloat = 300
        let enemyStartX = Int(frame.maxX) * 2

        if currentWave.enemies.isEmpty {
            for (index, position) in positions.shuffled().enumerated() {
                let enemy = EnemyNode(type: enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: position), xOffset: enemyOffsetX * CGFloat(index * 3), moveStraight: true)
                addChild(enemy)
            }
        } else {
            for enemy in currentWave.enemies {
                let node = EnemyNode(type: enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: positions[enemy.position]), xOffset: enemyOffsetX * enemy.xOffset, moveStraight: enemy.moveStraight)
                addChild(node)
            }
        }
    }

    private func gameOver() {
        print("Game over")
        isPlayerAlive = false
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        addChild(gameOver)
    }
}
