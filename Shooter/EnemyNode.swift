//
//  EnemyNode.swift
//  Shooter
//
//  Created by Lucas Kuipers on 08/12/21.
//

import SpriteKit

class EnemyNode: SKSpriteNode {
    var type: EnemyType
    var lastFireTime: Double = 0
    var shields: Int

    init(type: EnemyType, startPosition: CGPoint, xOffset: CGFloat, moveStraight: Bool) {
        self.type = type
        shields = type.shields

        let texture = SKTexture(imageNamed: type.name)
        super.init(texture: texture, color: .white, size: texture.size())
        physicsBody = SKPhysicsBody(texture: texture, size: texture.size())
        physicsBody?.categoryBitMask = CollisionType.enemy.rawValue
        physicsBody?.collisionBitMask = CollisionType.player.rawValue | CollisionType.playerWeapon.rawValue
        name = "enemy"
        position = CGPoint(x: startPosition.x, y: startPosition.y)

        configureMovement(moveStraight)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureMovement(_ moveStraight: Bool) {
        let path = UIBezierPath()
        path.move(to: .zero)

        if moveStraight {
            path.addLine(to: CGPoint(x: -10000, y: 0))
        } else {
            path.addCurve(to: CGPoint(x: -3500, y: 0), controlPoint1: CGPoint(x: 0, y: -position.y * 4), controlPoint2: CGPoint(x: -1000, y: -position.y))
        }
        let movement = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: type.speed)
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        run(sequence)

    }
}