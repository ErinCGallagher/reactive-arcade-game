//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameScene: SKScene {
    let kBoardCategory: UInt32 = 0x1 << 0
    
    // Control buttons
    var leftButtonTapped: Int = 0
    var rightButtonTapped: Int = 0
    
    override func didMove(to view: SKView) {
        setupBoard()
        setupArrowButtons()
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }


    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
}

// MARK: - Setup functions

extension GameScene: SKPhysicsContactDelegate {

    private func setupBoard() {
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody!.categoryBitMask = kBoardCategory
        self.backgroundColor = SKColor.black
    }

    private func setupArrowButtons() {
        let buttonWidth = Int(size.width/2)
        let buttonHeight = 76
        let leftButton = Button(texture: nil, color: .clear, size: CGSize(width: buttonWidth, height: buttonHeight))
        leftButton.name = ControlButton.left.rawValue
        leftButton.position = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
        leftButton.delegate = self
        addChild(leftButton)

        let rightButton = Button(texture: nil, color: .clear, size: CGSize(width: buttonWidth, height: buttonHeight))
        rightButton.name = ControlButton.right.rawValue
        rightButton.position = CGPoint(x: buttonWidth/2 + buttonWidth + 1, y: buttonHeight/2)
        rightButton.delegate = self
        addChild(rightButton)
    }
}

// MARK: - ButtonDelegate

extension GameScene: ButtonDelegate {
    enum ControlButton: String {
        case left = "LeftButton"
        case right = "RightButton"
    }

    func buttonClicked(sender: Button) {
        switch sender.name {
        case ControlButton.left.rawValue:
            print("left button ")
            leftButtonTapped += 1
        case ControlButton.right.rawValue:
            print("right button ")
            rightButtonTapped += 1
        default: break
        }
    }
}
    }
}

// Load GameScene into playground's live view
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 480, height: 640))
if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill
    sceneView.presentScene(scene)
}
PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
