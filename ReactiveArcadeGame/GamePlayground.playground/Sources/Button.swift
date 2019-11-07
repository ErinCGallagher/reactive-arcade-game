import Foundation
import SpriteKit

public protocol ButtonDelegate: class {
    func buttonClicked(sender: Button)
}

public class Button: SKSpriteNode {
    
    //weak so that you don't create a strong circular reference with the parent
    public weak var delegate: ButtonDelegate!
    
    override public init(texture: SKTexture?, color: SKColor, size: CGSize) {
        
        super.init(texture: texture, color: color, size: size)
        
        let shapeNode = SKShapeNode(rect: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size))
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = SKColor.white
        shapeNode.lineWidth = 2
        addChild(shapeNode)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    func setup() {
        isUserInteractionEnabled = true
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        setScale(0.9)
        self.delegate.buttonClicked(sender: self)
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        setScale(1.0)
    }
}
