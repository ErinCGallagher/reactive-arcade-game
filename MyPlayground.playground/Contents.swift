//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameScene: SKScene {
    let kBoardCategory: UInt32 = 0x1 << 0
    let kPlayerCategory: UInt32 = 0x1 << 1
    let kEnemyCategory: UInt32 = 0x1 << 2
    
    // Control buttons
    var leftButtonTapped: Int = 0
    var rightButtonTapped: Int = 0
    
    // Enemies
    var enemyTimeLastFrame: CFTimeInterval = 0.0
    let enemyTimePerFrame: CFTimeInterval = 1.0
    var enemyDirection: EnemyDirection = .right
    
    override func didMove(to view: SKView) {
        setupBoard()
        setupArrowButtons()
        setupPlayer()
        setupEnemies()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        processPlayerMovement()
        processEnemiesMovement(for: currentTime)
    }
}

// MARK: - Setup functions

extension GameScene: SKPhysicsContactDelegate {
    enum ChildNodeName: String {
        case player = "player"
        case enemy = "enemy"
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
    
    private func setupEnemies() {
        let enemiesPerRow = 6
        let enemiesPerColumn = 6
        let rowHeight: CGFloat = 32.0
        let columnWidth: CGFloat = 36.0
        let baseOrigin = CGPoint(x: size.width / 3, y: size.height / 2)
        
        for row in 0..<enemiesPerRow {
            let enemyPositionY = CGFloat(row) * rowHeight + baseOrigin.y
            
            for col in 0..<enemiesPerColumn {
                let enemy = makeEnemy(for: row)
                enemy.position = CGPoint(x: CGFloat(col) * columnWidth + baseOrigin.x, y: enemyPositionY)
                addChild(enemy)
            }
        }
    }
    
    private func makeEnemy(for row: Int) -> SKNode {
        let enemyTextures = [
            SKTexture(imageNamed: "Invader\(row%3)_00.png"),
            SKTexture(imageNamed: "Invader\(row%3)_00.png")
        ]
        
        let enemy = SKSpriteNode(texture: enemyTextures[0])
        enemy.name = ChildNodeName.enemy.rawValue
        enemy.run(SKAction.repeatForever(SKAction.animate(with: enemyTextures, timePerFrame: enemyTimePerFrame)))
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.frame.size)
        enemy.physicsBody!.isDynamic = false
        enemy.physicsBody!.categoryBitMask = kEnemyCategory
        enemy.physicsBody!.contactTestBitMask = 0x0
        enemy.physicsBody!.collisionBitMask = 0x0
        return enemy
    }
}

// MARK: - Update functions

extension GameScene {
    enum EnemyDirection {
        case right
        case left
        case downThenRight
        case downThenLeft
        
        var nextDirection: EnemyDirection {
            switch self {
            case .right: return .downThenLeft
            case .left: return .downThenRight
            case .downThenRight: return .right
            case .downThenLeft: return .left
            }
        }
    }
    
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
    
    private func processEnemiesMovement(for currentTime: CFTimeInterval) {
        if (currentTime - enemyTimeLastFrame < enemyTimePerFrame) {
            return
        }
        
        enemyTimeLastFrame = currentTime
        updateEnemyDirection()

        enumerateChildNodes(withName: ChildNodeName.enemy.rawValue) { [weak self] node, stop in
            guard let this = self else { return }
            let jumpPerFrame: CGFloat = 10.0
            switch this.enemyDirection {
            case .right:
                node.position = CGPoint(x: node.position.x + jumpPerFrame, y: node.position.y)
            case .left:
                node.position = CGPoint(x: node.position.x - jumpPerFrame, y: node.position.y)
            case .downThenLeft, .downThenRight:
                node.position = CGPoint(x: node.position.x, y: node.position.y - jumpPerFrame)
            }
        }
    }
    
    private func updateEnemyDirection() {
        if [.downThenLeft, .downThenRight].contains(enemyDirection) {
            enemyDirection = enemyDirection.nextDirection
            return
        }

        enumerateChildNodes(withName: ChildNodeName.enemy.rawValue) { [weak self] node, stop in
            guard let this = self else { return }
            if (node.frame.minX <= 1.0 ||
                node.frame.maxX >= node.scene!.size.width - 1.0) {
                this.enemyDirection = this.enemyDirection.nextDirection
                stop.initialize(to: true)
            }
        }
    }
}

// MARK: - ButtonDelegate

extension GameScene: ButtonDelegate {
    enum ControlButton: String {
        case left = "LeftButton"
        case right = "RightButton"
    }
    
    internal func buttonClicked(sender: Button) {
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
