//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameScene: SKScene {
    let kBoardCategory: UInt32 = 0x1 << 0
    let kPlayerCategory: UInt32 = 0x1 << 1
    
    // Control buttons
    var leftButtonTapped: Int = 0
    var rightButtonTapped: Int = 0
    
    override func didMove(to view: SKView) {
        setupBoard()
        setupArrowButtons()
        setupPlayer()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        processPlayerMovement()
    }
}

// MARK: - Setup functions

extension GameScene: SKPhysicsContactDelegate {
    enum ChildNodeName: String {
        case player = "player"
    }
    
    private func setupBoard() {
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody!.categoryBitMask = kBoardCategory
        self.backgroundColor = SKColor.black
    }
    
    private func setupArrowButtons() {
        let buttonWidth = Int(size.width/2)
        let buttonHeight = 76
        let leftButton = Button(texture: nil, color: .lightGray, size: CGSize(width: buttonWidth, height: buttonHeight))
        leftButton.name = ControlButton.left.rawValue
        leftButton.position = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
        leftButton.delegate = self
        addChild(leftButton)
        
        let rightButton = Button(texture: nil, color: .lightGray, size: CGSize(width: buttonWidth, height: buttonHeight))
        rightButton.name = ControlButton.right.rawValue
        rightButton.position = CGPoint(x: buttonWidth/2 + buttonWidth + 1, y: buttonHeight/2)
        rightButton.delegate = self
        addChild(rightButton)
    }
    
    private func setupPlayer() {
        let player = SKSpriteNode(imageNamed: "Player.png")
        player.name = ChildNodeName.player.rawValue
        let playerSize = player.frame.size
        player.physicsBody = SKPhysicsBody(rectangleOf: playerSize)
        player.physicsBody!.isDynamic = true
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.mass = 0.02
        player.physicsBody!.categoryBitMask = kPlayerCategory
        player.physicsBody!.contactTestBitMask = 0x0
        player.physicsBody!.collisionBitMask = kBoardCategory
        player.position = CGPoint(x: size.width / 2.0, y: playerSize.height / 2.0)
        addChild(player)
    }
}

// MARK: - Update functions

extension GameScene {
    private func processPlayerMovement() {
        if let player = childNode(withName: ChildNodeName.player.rawValue) as? SKSpriteNode,
            (leftButtonTapped > 0 || rightButtonTapped > 0) {
            let playerJumpPerClick = 7
            let playerXPosition: CGFloat = player.position.x - CGFloat(leftButtonTapped * playerJumpPerClick) + CGFloat(rightButtonTapped * playerJumpPerClick)
            player.position = CGPoint(
                x: playerXPosition,
                y: player.position.y
            )
            leftButtonTapped = 0
            rightButtonTapped = 0
        }
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

// Load GameScene into playground's live view
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 480, height: 640))
if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill
    sceneView.presentScene(scene)
}
PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
