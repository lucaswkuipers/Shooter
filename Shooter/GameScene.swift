import SpriteKit

final class GameScene: SKScene {
    private let player = SKSpriteNode(imageNamed: "player")
    private let waves = Bundle.main.decode([Wave].self, from: "waves.json")
    private let enemyTypes = Bundle.main.decode([EnemyType].self, from: "enemy-types.json")
    private let positions = Array(stride(from: -320, through: 320, by: 80))
    private var isPlayerAlive = true
    private var levelNumber = 0
    private var waveNumber = 0
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero

        guard let particles = SKEmitterNode(fileNamed: "Starfield") else { return }
        particles.position = CGPoint(x: frame.maxX, y: 0)
        particles.advanceSimulationTime(5)
        particles.zPosition = -1
        addChild(particles)

        player.name = "player"
        player.position.x = frame.minX + player.frame.width
        player.position.y = frame.midY
        player.zPosition = 1
        addChild(player)

        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody!.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody!.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.isDynamic = false
        player.setScale(0.5)
    }

    override func update(_ currentTime: TimeInterval) {
        for child in children {
            if child.frame.maxX < 0 {
                if !frame.intersects(child.frame) {
                    child.removeFromParent()
                }
            }
        }
        let activeEnemies = children.compactMap { $0 as? EnemyNode}

        if activeEnemies.isEmpty {
            createWave()
        }

        for enemy in activeEnemies {
            guard frame.intersects(enemy.frame) else { continue }

            if enemy.lastFireTime + 1 < currentTime {
                enemy.lastFireTime = currentTime
                enemy.fire()
            }

            if enemy.frame.intersects(player.frame) {
                enemy.removeFromParent()
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlayerAlive else { return }

        let shot = SKSpriteNode(imageNamed: "playerWeapon")
        shot.name = "playerWeapon"
        shot.position = player.position

        shot.physicsBody = SKPhysicsBody(rectangleOf: shot.size)
        shot.physicsBody?.categoryBitMask = CollisionType.playerWeapon.rawValue
        shot.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        shot.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        addChild(shot)

        let movement = SKAction.move(to: CGPoint(x: 2000, y: shot.position.y), duration: 10)
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        shot.run(sequence)
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
        let enemyOffsetX: CGFloat = 100
        let enemyStartX = 600

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
}
