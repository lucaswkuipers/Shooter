import UIKit
import SpriteKit
import GameplayKit

final class GameViewController: UIViewController {
    private var scene: GameScene!

    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameScene(size: view.bounds.size)
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "GameScene") {
                scene.scaleMode = .resizeFill
                view.presentScene(scene)
            }

            view.preferredFramesPerSecond = 120
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
