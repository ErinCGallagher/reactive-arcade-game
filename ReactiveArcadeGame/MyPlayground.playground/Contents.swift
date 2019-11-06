//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit
import RxSwift
import RxCocoa

class GameScene: SKScene {
    var enemyDirection: EnemyDirection = .right
    let kMinEnemyBottomHeight: Float = 300.0
    
    // Observables
    let disposeBag = DisposeBag()
    let playerHealthSubject = PublishSubject<Float>()
    let allEnemies = BehaviorRelay<[SKNode]>(value: [])
    let enemyLowestPosition = BehaviorRelay<Float>(value: 640)
    let userClickSubject = PublishSubject<UITouch>()
}

/*:
 # Observable functions
 * Workshop Task #1: setUpFireBulletsObserver()
 * Workshop Task #2: setUpGameOverObserver()
 * Workshop Task #3: setUpPlayerWinsObserver()
*/
extension GameScene {
    
    // Helper function that returns a [SKNode] given a [UITouch] object.
    private func getNodeAtTouchLocation(_ touch: UITouch) -> SKNode {
        let location = touch.location(in: self)
        let node: SKNode = atPoint(location)
        return node
    }
    
    // TASK #1
    // Set up an observer which reacts to player click events using [userClickSubject] PublishSubject
    // Filter for click events which were made on the board, not the left or right buttons
    // Peform the [firePlayerBullets] action whena click is emitted.
    // Hint: [self.getNodeAtTouchLocation()] returns the location of a touch as a [SKNode]
    // Hint: [ChildNodeName.board.rawValue] is the name of the board node
    private func setUpFireBulletsObserver() {
        userClickSubject
            .asObservable()
            .filter { self.getNodeAtTouchLocation($0).name == ChildNodeName.board.rawValue }
            .subscribe(onNext: { _ in
                self.firePlayerBullets()
            })
            .disposed(by: disposeBag)
    }
    
    
    
    // TASK #2
    // Sets up the required Observables and Observers to detect when the game is over.
    private func setUpGameOverObserver() {
        // emits true when the enemies hve reached the bottom of the screen
        // This indicates that the enemies have "Invaded"
        var enemiesInvaded: Observable<Bool> {
            return enemyLowestPosition
                .asObservable()
                .map { [weak self] position in
                    guard let this = self else { return false }
                    return position < this.kMinEnemyBottomHeight
                }
                .distinctUntilChanged()
        }
        
        // TASK #2 A
        // Set up an observable which emits True when the player's health is above 0
        // and otherwise emits false
        var playerStatus: Observable<Bool> {
            return playerHealthSubject
                .map { $0 > 0 }
        }
        
        // TASK #2 B
        // Set up an observer which detects when the game is over.
        // The game is over if either:
        //   1) The player has died
        //   2) The enemies have invaded
        // Hint: Should react to the following observables [playerStatus] and [alienInvasion]
        Observable.combineLatest(playerStatus, enemiesInvaded)
            .skip(1)
            .subscribe(onNext: { [weak self] playerStatus, enemiesInvaded in
                guard let this = self else { return }
                print("Player won \(playerStatus), Enemies Won \(enemiesInvaded)")
                if !playerStatus || enemiesInvaded {
                    this.gameOver()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // Task # 3
    // Set up an observer which detects and reacts when the player wins the game.
    // The player wins when there are no enemies remaining
    // Perform the [playerWins()] action when the observable emits
    // Hint: Use [allEnemies] Subject to detect when no enemies are remaining
    // Hint: Chain the [map] and [filter] operators
    private func setUpPlayerWinsObserver() {
        allEnemies
            .skip(1)
            .asObservable()
            .map { $0.isEmpty }
            .filter { $0 == true }
            .subscribe(onNext: { [weak self] _ in
                self?.playerWins()
            })
            .disposed(by: disposeBag)
    }
    
    // Logs player Health and number of enemies to the console while the game is running.
    private func setupConsoleLoggingObservables() {
        playerHealthSubject
            .subscribe { playerHealth in
                print("playerHealth \(playerHealth)")
            }
            .disposed(by: disposeBag)
        
        allEnemies.asObservable()
            .subscribe(onNext: { enemies in
                print("enemies \(enemies.count)")
            })
            .disposed(by: disposeBag)
    }
}

/*:
 ## Game SKScene
 * didMove()
 * touchesBegan()
 * update()
*/
extension GameScene {
    // Method called by the system when the scene is presented.
    // overrides this method by setting up the board, arrow button, player, enemies and player HUD.
    override public func didMove(to view: SKView) {
        super.didMove(to: view)
        setupConsoleLoggingObservables()
        setUpFireBulletsObserver()
        setUpGameOverObserver()
        setUpPlayerWinsObserver()
        setupBoard()
        setupArrowButtons()
        setupPlayer()
        setupEnemies()
        setupHud()
    }
    
    // Method called by the system when a touch within the UiView is detected.
    // Overrides how touches are handled in the game.
    // If the touch is on the board above the right and left buttons, it fires a player bullet.
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        for touch in touches {
            userClickSubject.onNext(touch)
        }
    }
    
    // Method called by the system once per frame.
    // overrides how to handle the enemy, player and bullet nodes in the scene.
    override public func update(_ currentTime: TimeInterval) {
        if gameEnded {
            return
        }
        
        // Called before each frame is rendered
        processEnemiesBullets()
        processPlayerMovement()
        processEnemiesMovement(for: currentTime)
    }
}

/*:
 ## Game Setup
 * setupBoard()
 * setupArrowButtons()
 * setupPlayer()
 * setupEnemies()
 * makeEnemy()
 * makeBullet()
 * setupHud()
*/
extension GameScene {
    // The different Node entities and their associates names.
    enum ChildNodeName: String {
        case board = "board"
        case player = "player"
        case enemiesBoard = "enemiesBoard"
        case enemy = "enemy"
        case playerBullet = "playerBullet"
        case enemyBullet = "enemyBullet"
    }
    
    // Sets up the aracde board, physics, background colour, size and position.
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
    
    // Sets up the right and left arrow buttons at the bottom of the screen.
    // Delegates the left and right button click handling to [ButtonDelegate].
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
    
    // Creates the player nodeand places it at's it's starting position.
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
        playerHealthSubject.onNext(playerHealth)
    }
    
    // Creates a number of enemy nodes ([numberOfRows] * [numberOfColumns]) and sets their starting positions.
    private func setupEnemies() {
        let numberOfColumns = 4
        let numberOfRows = 4
        let rowHeight: CGFloat = 32.0
        let columnWidth: CGFloat = 36.0

        let enemiesBoardSize = CGSize(
            width: CGFloat(numberOfColumns) * columnWidth,
            height: CGFloat(numberOfRows) * rowHeight
        )
        let enemiesBoard = SKSpriteNode(color: SKColor.clear, size: enemiesBoardSize)
        enemiesBoard.position = CGPoint(x: size.width / 3, y: size.height / 2)
        enemiesBoard.name = ChildNodeName.enemiesBoard.rawValue
        let baseOrigin = CGPoint(x: enemiesBoardSize.width / 2, y: enemiesBoardSize.height / 2)
        
        // loops through the [numberOfColumns] and [numberOfRows] to add enemies at their correct position
        for row in 0..<numberOfRows {
            for col in 0..<numberOfColumns {
                let enemy = makeEnemy(for: row)
                enemy.position = CGPoint(x: CGFloat(col) * columnWidth - baseOrigin.x,
                                         y: CGFloat(row) * rowHeight - baseOrigin.y)
                
                // adds the enemy to the scene
                enemiesBoard.addChild(enemy)
                var enemies = allEnemies.value
                enemies.append(enemy)
                allEnemies.accept(enemies)
            }
        }
        
        addChild(enemiesBoard)
    }
    
    // Creates and returns  an eneymy node [SKNode] with its associated [physicsBody].
    private func makeEnemy(for row: Int) -> SKNode {
        let enemy = SKSpriteNode(imageNamed: "Invader\(row%3)_00.png")
        enemy.name = ChildNodeName.enemy.rawValue
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
    
    // Creates and returns a [SKNode] bullet of a given type [bulletType].
    private func makeBullet(ofType bulletType: ChildNodeName) -> SKNode {
        //creates the SKSpriteNode
        let bulletSize = CGSize(width:4, height: 8)
        let bullet = SKSpriteNode(color: SKColor.green, size: bulletSize)
        bullet.name = bulletType.rawValue
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
        
        // assigns physics and a type to the bullet
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
            case .board, .player, .enemy, .enemiesBoard:
                break
            }
        }
        return bullet
    }
    
    // Sets up the [scoreLabel] and[healthLabel] with their default state and adds them to the scene.
    private func setupHud() {
        scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = SKColor.green
        scoreLabel.text = String(format: "Score: %04u", 0)
        scoreLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (40 + scoreLabel.frame.size.height/2)
        )
        addChild(scoreLabel)
        
        healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.fontSize = 25
        healthLabel.fontColor = SKColor.red
        healthLabel.text = String(format: "Health: %.1f%%", playerHealth * 100.0)
        healthLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (80 + healthLabel.frame.size.height/2)
        )
        addChild(healthLabel)
    }
}

/*:
 ## Game Physic - SKPhysicsContactDelegate
 * killedEnemy()
 * enemyHitPlayer()
*/
extension GameScene: SKPhysicsContactDelegate {
    
    // overriding how the collision between 2 physics entities is handled by the game.
    public func didBegin(_ contact: SKPhysicsContact) {
        handle(contact)
    }
    
    // Adjusts the players score or health depending on the type of bullet collision.
    // If an enemy bullet collides with a player, the player's health is decreased.
    // If a player bullet collides with an enemy, the player's score is increased.
    private func handle(_ contact: SKPhysicsContact) {
        // seperates each attribute of [contact] into easy to access variables
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
            enemyHitPlayer(contact)
        } else if nodeNames.contains(ChildNodeName.enemy.rawValue) && nodeNames.contains(ChildNodeName.playerBullet.rawValue) {
            // Player hit an enemy
            killedEnemy(contact)
        }
    }
    
    // Update score and Observable allEnemies
    private func killedEnemy(_ contact: SKPhysicsContact) {
        score += 100
        scoreLabel.text = String(format: "Score: %04u", score)
        
        guard let bodyANode = contact.bodyA.node,
              let bodyBNode = contact.bodyB.node
        else {
            return
        }
        
        bodyANode.removeFromParent()
        bodyBNode.removeFromParent()
        guard let index = allEnemies.value.firstIndex(of: bodyANode)
        else {
            return
        }
        var enemies = allEnemies.value
        enemies.remove(at: index)
        allEnemies.accept(enemies)
    }
    
    // Adjusts the player's health by [healthAdjustment] and updates the [healthLabel].
    // if the resulting health is less than 0, sets the healthLabel to 0.
    private func enemyHitPlayer(_ contact: SKPhysicsContact) {
        playerHealth = max(playerHealth - 0.334, 0)
        healthLabel.text = String(format: "Health: %.1f%%", playerHealth * 100.0)
        
        guard let _ = contact.bodyA.node,
              let bulletNode = contact.bodyB.node
        else {
            return
        }
        
        // Player's health is below min 0
        playerHealthSubject.onNext(playerHealth)
        bulletNode.removeFromParent()
        
        if let player = childNode(withName: ChildNodeName.player.rawValue) {
            player.alpha = CGFloat(playerHealth)
        }
    }
}

/*:
 ## Update functions
 * processPlayerMovement()
 * processEnemiesMovement()
 * updateEnemyDirection()
 * processEnemiesBullets()
 * fireBullet()
 * firePlayerBullets()
 * gameOver()
 * playerWins()
*/
extension GameScene {
    // Enemies moves left, then down, then right then down the repeat.
    enum EnemyDirection {
        case right
        case left
        case downThenRight
        case downThenLeft
        
        // specifies the direction that proceeds the current one
        var nextDirection: EnemyDirection {
            switch self {
            case .right: return .downThenLeft
            case .left: return .downThenRight
            case .downThenRight: return .right
            case .downThenLeft: return .left
            }
        }
    }
    
    // Moves the player [playerJumpPerClick] spaces left or right depending on which button was tapped.
    private func processPlayerMovement() {
        // only updates the players position if there is a player node and the left or right buttons have been tapped.
        if let player = childNode(withName: ChildNodeName.player.rawValue) as? SKSpriteNode,
            (leftButtonTapped > 0 || rightButtonTapped > 0) {
            let playerJumpPerClick = 7 // moves 7 spaces per click
            let playerXPosition: CGFloat = player.position.x - CGFloat(leftButtonTapped * playerJumpPerClick) + CGFloat(rightButtonTapped * playerJumpPerClick)
            player.position = CGPoint(
                x: playerXPosition,
                y: player.position.y
            )
            // resets the tap to count
            leftButtonTapped = 0
            rightButtonTapped = 0
        }
    }
    
    // Moves the enemy nodes [jumpPerFrame] spaces in the current [enemyDirection].
    // Only updates the enemy position [enemyTimePerFrame] times per frame.
    private func processEnemiesMovement(for currentTime: CFTimeInterval) {
        // only updates the position if times passed since last update is greater than [enemyTimePerFrame].
        if (currentTime - enemyTimeLastFrame < enemyTimePerFrame) {
            return
        }
        
        //updates time and direction of the current enemy move
        enemyTimeLastFrame = currentTime
        updateEnemyDirection()
        
        enumerateChildNodes(withName: ChildNodeName.enemiesBoard.rawValue) { [weak self] node, stop in
            guard let this = self else { return }
            let jumpPerFrame: CGFloat = 10.0 // position moved per update
            // updates the enemy node's position in the correct direction
            switch this.enemyDirection {
            case .right:
                node.position = CGPoint(x: node.position.x + jumpPerFrame, y: node.position.y)
            case .left:
                node.position = CGPoint(x: node.position.x - jumpPerFrame, y: node.position.y)
            case .downThenLeft, .downThenRight:
                let newYPosition = node.position.y - jumpPerFrame
                node.position = CGPoint(x: node.position.x, y: newYPosition)
                this.enemyLowestPosition.accept(Float(newYPosition + node.frame.minY))
            }
        }
    }
    
    // Updates the direction the enemy nodes should be travelling.
    // [enemyDirection.nextDirection] indicates what the next direction will be.
    private func updateEnemyDirection() {
        // after a [downThenLeft] or [downThenRight] movement the direction can be immeditely updated to next.
        if [.downThenLeft, .downThenRight].contains(enemyDirection) {
            enemyDirection = enemyDirection.nextDirection
            return
        }
        
        enumerateChildNodes(withName: ChildNodeName.enemiesBoard.rawValue) { [weak self] node, stop in
            guard let this = self else { return }
            // only update to the next direction when the enemies have reached the end of the screen.
            if (node.frame.minX <= 30.0 ||
                node.frame.maxX >= node.scene!.size.width - 1.0) {
                this.enemyDirection = this.enemyDirection.nextDirection
                stop.initialize(to: true)
            }
        }
    }
    
    // Selects an enemy at random and fires the bullet towards a final destination directly below it.
    // Only fires a new enemy bullet if an existing one is not on the screen.
    private func processEnemiesBullets() {
        // If there is an existing enemy bullet currently on screen, do not fire a new one
        let existingBullet = childNode(withName: ChildNodeName.enemyBullet.rawValue)
        if existingBullet != nil {
            return
        }
        
        // If there are no enemies, there are no bullets to be processed
        let enemiesBoard = self[ChildNodeName.enemiesBoard.rawValue][0]
        let allEnemies = enemiesBoard[ChildNodeName.enemy.rawValue]
        if allEnemies.isEmpty {
            return
        }
        
        // selects a random enemy to shoot a bullet from
        let randomEnemyIndex = Int(arc4random_uniform(UInt32(allEnemies.count)))
        let randomEnemy = allEnemies[randomEnemyIndex]
        
        // creates an enemy bullet
        let bullet = makeBullet(ofType: .enemyBullet)
        bullet.position = CGPoint(
            x: enemiesBoard.position.x + randomEnemy.position.x,
            y: enemiesBoard.position.y + randomEnemy.position.y - randomEnemy.frame.size.height / 2 + bullet.frame.size.height / 2
        )
        
        // sets the bullet destnation
        let bulletDestination = CGPoint(
            x: enemiesBoard.position.x + randomEnemy.position.x,
            y: -(bullet.frame.size.height / 2)
        )
        
        // launches the bullet from the enemy itself towards the final destination
        fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: 1.5)
    }
    
    // Adds the bullet to the scene and starts the action which moves it towards its given final destination [toDestination].
    private func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval) {
        let bulletAction = SKAction.sequence([
            SKAction.move(to: destination, duration: duration),
            SKAction.wait(forDuration: 3.0 / 60.0),
            SKAction.removeFromParent()
        ])
        bullet.run(bulletAction)
        addChild(bullet)
    }
    
    // Fires a bullet from the player's current position towards a final destination directly below it.
    // Only fires a new player bullet if an existing one is not on the screen.
    private func firePlayerBullets() {
        // if there is an existing player bullet currently on the screen, do not fire a new one
        let existingBullet = childNode(withName: ChildNodeName.playerBullet.rawValue)
        if existingBullet != nil {
            return
        }
        
        if let player = childNode(withName: ChildNodeName.player.rawValue) {
            // creates a player bullet
            let bullet = makeBullet(ofType: .playerBullet)
            bullet.position = CGPoint(
                x: player.position.x,
                y: player.position.y - player.frame.size.height / 2 + bullet.frame.size.height / 2
            )
            // sets the bullet destnation
            let bulletDestination = CGPoint(
                x: player.position.x,
                y: frame.size.height + bullet.frame.size.height / 2
            )
            // launches the bullet from the player itself towards the final destination
            fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: 1.5)
        }
    }
    
    // Changes the [scoreLabel] and [healthLabel] to indicate the game is over.
    func gameOver() {
        gameEnded = true
        scoreLabel.text = ""
        healthLabel.text = "Game Over"
        
        if let player = childNode(withName: ChildNodeName.player.rawValue) {
            player.removeFromParent()
        }
    }
    
    func playerWins() {
        gameEnded = true
        scoreLabel.text = "You win"
        healthLabel.text = ""
    }
}

/*:
 ## Game Buttons - ButtonDelegate
*/
extension GameScene: ButtonDelegate {
    enum ControlButton: String {
        case left = "LeftButton"
        case right = "RightButton"
    }
    
    public func buttonClicked(sender: Button) {
        switch sender.name {
        case ControlButton.left.rawValue:
            leftButtonTapped += 1
        case ControlButton.right.rawValue:
            rightButtonTapped += 1
        default: break
        }
    }
}

/*:
 ## Game Constants
*/
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

// HUD: Heads Up Display (player's vitals and stats)
var score: Int = 0
var playerHealth: Float = 1.0
var scoreLabel: SKLabelNode!
var healthLabel: SKLabelNode!
var gameEnded: Bool = false

// Load GameScene into playground's live view
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 480, height: 640))
if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill
    sceneView.presentScene(scene)
}
PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
