//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameScene: SKScene {
    let kBoardCategory: UInt32 = 0x1 << 0
    let kPlayerCategory: UInt32 = 0x1 << 1
    let kEnemyCategory: UInt32 = 0x1 << 2
    let kPlayerBulletCategory: UInt32 = 0x1 << 3
    let kEnemyBulletCategory: UInt32 = 0x1 << 4
    
    // Control buttons
    var leftButtonTapped: Int = 0
    var rightButtonTapped: Int = 0
    
    // Enemies
    var enemyTimeLastFrame: CFTimeInterval = 0.0
    let enemyTimePerFrame: CFTimeInterval = 1.0
    var enemyDirection: EnemyDirection = .right
    
    // HUD
    var score: Int = 0
    var playerHealth: Float = 1.0
    var scoreLabel: SKLabelNode!
    var healthLabel: SKLabelNode!
    override func didMove(to view: SKView) {
        setupBoard()
        setupArrowButtons()
        setupPlayer()
        setupEnemies()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            let location = touch.location(in: self)
            let node: SKNode = atPoint(location)
            if(node.name == ChildNodeName.board.rawValue) {
               firePlayerBullets()
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        processEnemiesBullets()
        processPlayerMovement()
        processEnemiesMovement(for: currentTime)
    }
}

// MARK: - Setup functions

extension GameScene {
    enum ChildNodeName: String {
        case board = "board"
        case player = "player"
        case enemy = "enemy"
        case playerBullet = "playerBullet"
        case enemyBullet = "enemyBullet"
    }
    
    private func setupBoard() {
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        if let physicsBody = physicsBody {
            physicsBody.isDynamic = false
            physicsBody.categoryBitMask = kBoardCategory
        }
        
        self.backgroundColor = SKColor.darkGray
        let boardSize = CGSize(width: size.width-4, height: size.height-4)
        let board = SKSpriteNode(color: SKColor.black, size: boardSize)
        board.name = ChildNodeName.board.rawValue
        board.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(board)
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
        if let playerBody = player.physicsBody {
            playerBody.isDynamic = true
            playerBody.affectedByGravity = false
            playerBody.categoryBitMask = kPlayerCategory
            playerBody.contactTestBitMask = 0x0
            playerBody.collisionBitMask = kBoardCategory
        }
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
            SKTexture(imageNamed: "Invader\(row%3)_01.png")
        ]
        
//        let enemy = SKSpriteNode(texture: enemyTextures[0])
        let enemy = SKSpriteNode(imageNamed: "Invader\(row%3)_00.png")
        enemy.name = ChildNodeName.enemy.rawValue
//        enemy.run(SKAction.repeatForever(SKAction.animate(with: enemyTextures, timePerFrame: enemyTimePerFrame)))
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.frame.size)
        if let enemyBody = enemy.physicsBody {
            enemyBody.isDynamic = true
            enemyBody.affectedByGravity = false
            enemyBody.categoryBitMask = kEnemyCategory
            enemyBody.contactTestBitMask = 0x0
            enemyBody.collisionBitMask = 0x0
        }
        
        return enemy
    }
    
    private func makeBullet(ofType bulletType: ChildNodeName) -> SKNode {
        let bulletSize = CGSize(width:4, height: 8)
        let bullet = SKSpriteNode(color: SKColor.green, size: bulletSize)
        bullet.name = bulletType.rawValue
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
        if let bulletBody = bullet.physicsBody {
            bulletBody.isDynamic = true
            bulletBody.affectedByGravity = false
            bulletBody.collisionBitMask = 0x0
            
            switch bulletType {
            case .playerBullet:
                bullet.color = SKColor.green
                bulletBody.categoryBitMask = kPlayerBulletCategory
                bulletBody.contactTestBitMask = kEnemyCategory
            case .enemyBullet:
                bullet.color = SKColor.magenta
                bulletBody.categoryBitMask = kEnemyBulletCategory
                bulletBody.contactTestBitMask = kPlayerCategory
            case .board, .player, .enemy:
                break
            }
        }
        return bullet
    }
}

// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        handle(contact)
    }
    
    private func handle(_ contact: SKPhysicsContact) {
        guard let bodyANode = contact.bodyA.node,
              let bodyANodeName = bodyANode.name,
              let bodyBNode = contact.bodyB.node,
              let bodyBNodeName = bodyBNode.name
        else {
            return
        }
        
        // Ensure you haven't already handled this contact and removed its nodes
        if bodyANode.parent == nil || bodyBNode.parent == nil {
            return
        }

        let nodeNames = [bodyANodeName, bodyBNodeName]
        if nodeNames.contains(ChildNodeName.player.rawValue) && nodeNames.contains(ChildNodeName.enemyBullet.rawValue) {
            // Enemy bullet hit player
            adjustPlayerHealth(by: -0.334)
            
            if playerHealth <= 0.0 {
                bodyANode.removeFromParent()
                bodyBNode.removeFromParent()
            } else {
                // 3
                if let player = childNode(withName: ChildNodeName.player.rawValue) {
                    player.alpha = CGFloat(playerHealth)
                    if bodyANode == player {
                        bodyBNode.removeFromParent()
                    } else {
                        bodyANode.removeFromParent()
                    }
                }
            }
            
        } else if nodeNames.contains(ChildNodeName.enemy.rawValue) && nodeNames.contains(ChildNodeName.playerBullet.rawValue) {
            // Player hit an enemy
//            run(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            bodyANode.removeFromParent()
            bodyBNode.removeFromParent()
            adjustScore(by: 100)
        }
    }
    
    private func adjustScore(by points: Int) {
        score += points
        print("enemy hit player")
    }
    
    private func adjustPlayerHealth(by healthAdjustment: Float) {
        playerHealth = max(playerHealth + healthAdjustment, 0)
        print("player hit enemy")
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
    
    private func processEnemiesBullets() {
        let existingBullet = childNode(withName: ChildNodeName.enemyBullet.rawValue)
        if existingBullet != nil {
            return
        }

        let allEnemies = self[ChildNodeName.enemy.rawValue]
        if allEnemies.isEmpty {
            return
        }

        let randomEnemyIndex = Int(arc4random_uniform(UInt32(allEnemies.count)))
        let randomEnemy = allEnemies[randomEnemyIndex]
        
        let bullet = makeBullet(ofType: .enemyBullet)
        bullet.position = CGPoint(
            x: randomEnemy.position.x,
            y: randomEnemy.position.y - randomEnemy.frame.size.height / 2 + bullet.frame.size.height / 2
        )
        let bulletDestination = CGPoint(
            x: randomEnemy.position.x,
            y: -(bullet.frame.size.height / 2)
        )
        
        fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: 1.0)
    }
    
    private func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval) {
        let bulletAction = SKAction.sequence([
            SKAction.move(to: destination, duration: duration),
            SKAction.wait(forDuration: 3.0 / 60.0),
            SKAction.removeFromParent()
        ])
        bullet.run(bulletAction)
        addChild(bullet)
    }
    
    private func firePlayerBullets() {
        let existingBullet = childNode(withName: ChildNodeName.playerBullet.rawValue)
        if existingBullet != nil {
            return
        }

        if let player = childNode(withName: ChildNodeName.player.rawValue) {
            let bullet = makeBullet(ofType: .playerBullet)
            bullet.position = CGPoint(
                x: player.position.x,
                y: player.position.y - player.frame.size.height / 2 + bullet.frame.size.height / 2
            )
            let bulletDestination = CGPoint(
                x: player.position.x,
                y: frame.size.height + bullet.frame.size.height / 2
            )
            fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: 1.0)
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
