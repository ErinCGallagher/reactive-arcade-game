//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameScene: SKScene {
    
    var playerPos: (String, Int) = ("e", 0)
    var gamePiece: SKSpriteNode = SKSpriteNode(imageNamed: "circle")
    
    override func didMove(to view: SKView) {
        drawBoard()
        
        drawArrowKeys()
        
        if let square = updatePlayerPosWith(name: "e0") {
//            gamePiece = SKSpriteNode(imageNamed: "circle")
            gamePiece.size = CGSize(width: 24, height: 24)
            gamePiece.color = SKColor.red
            square.addChild(gamePiece)
        }
    }
    
    private func updatePlayerPosWith(name:String) -> SKSpriteNode? {
        let playerSquare:SKSpriteNode? = self.childNode(withName: name) as! SKSpriteNode?
        return playerSquare
    }
    
    private func drawArrowKeys() {
        let numRows = 2
        let numCols = 3
        let squareSize = CGSize(width: 50, height: 50)
        let xOffset:CGFloat = 50
        let yOffset:CGFloat = -100
        var toggle:Bool = false
        for row in 0...numRows-1 {
            for col in 0...numCols-1 {
                let color = toggle ? SKColor.red : SKColor.blue
                let square = SKSpriteNode(color: color, size: squareSize)
                square.position = CGPoint(x: CGFloat(col) * squareSize.width + xOffset, y: CGFloat(row) * squareSize.height + yOffset)
                self.addChild(square)
            }
            toggle = !toggle
        }
    }
    
    private func drawBoard() {
        let numRows = 10
        let numCols = 10
        let squareSize = CGSize(width: 40, height: 40)
        let xOffset:CGFloat = -100
        let yOffset:CGFloat = 10
        var toggle:Bool = false
        for row in 0...numRows-1 {
            for col in 0...numCols-1 {
                let alphas:String = "abcdefghij"
                let colChar = Array(alphas)[col]
                let color = toggle ? SKColor.white : SKColor.black
                let square = SKSpriteNode(color: color, size: squareSize)
                square.position = CGPoint(x: CGFloat(col) * squareSize.width + xOffset, y: CGFloat(row) * squareSize.height + yOffset)
                square.name = "\(colChar)\(row)"
                self.addChild(square)
            }
            toggle = !toggle
        }
    }
    
    @objc static override var supportsSecureCoding: Bool {
        // SKNode conforms to NSSecureCoding, so any subclass going
        // through the decoding process must support secure coding
        get {
            return true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touch")
        playerPos.1 += 1
        let newPos: String = playerPos.0 + String(playerPos.1)
        updatePlayerPosWith(name: newPos)
        gamePiece.anchorPoint = 
    }


    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))
if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill
    
    // Present the scene
    sceneView.presentScene(scene)
}

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
