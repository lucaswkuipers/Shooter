import SpriteKit

final class GameScene: SKScene {
    private let player = SKSpriteNode(imageNamed: "player")
    private let waves = Bundle.main.decode([Wave].self, from: "waves.json")
    private let enemyTypes = Bundle.main.decode([EnemyType].self, from: "enemy-types.json")
    private var isPlayerAlive = true
    private var levelNumber = 0
    private var waveNumber = 0
    
    override func didMove(to view: SKView) {
        guard let particles = SKEmitterNode(fileNamed: "Starfield") else { return }
        particles.position = CGPoint(x: frame.maxX, y: 0)
        particles.advanceSimulationTime(5)
        particles.zPosition = -1
        addChild(particles)

        player.name = "player"
        player.position.x = frame.midX
        player.position.y = frame.midY
        player.zPosition = 1
        addChild(player)

        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody!.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody!.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.isDynamic = false
    }
}
