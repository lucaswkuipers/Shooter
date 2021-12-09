import SpriteKit

final class GameScene: SKScene {
    let player = SKSpriteNode(imageNamed: "player")
    
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
    }
}
