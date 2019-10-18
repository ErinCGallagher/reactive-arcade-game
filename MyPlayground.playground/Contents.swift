//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameScene: SKScene {
    
    
    override func didMove(to view: SKView) {
        drawBoard()
        
        drawArrowKeys()
    }
    
    
    private func drawArrowKeys() {
        let numRows = 2
        let numCols = 3
        let squareSize = CGSize(width: 50, height: 50)
        let xOffset:CGFloat = 50
        let yOffset:CGFloat = -100
        for row in 0...numRows-1 {
            for col in 0...numCols-1 {
                if row == 1 && (col == 0 || col == 2) {

                } else {
                    let square = SKSpriteNode(color: SKColor.blue, size: squareSize)
                    square.position = CGPoint(x: CGFloat(col) * squareSize.width + xOffset, y: CGFloat(row) * squareSize.height + yOffset)
                    self.addChild(square)
                }
                
            }
        }
    }
    
    private func drawBoard() {
        let numRows = 10
        let numCols = 10
        let squareSize = CGSize(width: 40, height: 40)
        let xOffset:CGFloat = -100
        let yOffset:CGFloat = 10
        for row in 0...numRows-1 {
            for col in 0...numCols-1 {
                let colNames:String = "abcdefghij"
                let colChar = Array(colNames)[col]
                let square = SKSpriteNode(color: SKColor.white, size: squareSize)
                square.position = CGPoint(x: CGFloat(col) * squareSize.width + xOffset, y: CGFloat(row) * squareSize.height + yOffset)
                square.name = "\(colChar)\(row)"
                self.addChild(square)
            }
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }


    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
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
