//
//  GameScene.swift
//  DeBomber
//
//  Created by Linda on 2/23/15.
//  Copyright (c) 2015 MatchStick. All rights reserved.
//

import SpriteKit
import AVFoundation

var scoreLabel = SKLabelNode(fontNamed:"Futura-Medium")

var score: Int = 0{
    didSet {
        scoreLabel.text = String(format: "%05d", score)
    }
}

/*
  comboString: 
    to record the last bomb that the player touches in order to identify whether the touched bomb is same as previous one or not
*/
var comboString = String()
var comboRate: Double = 1.0

let explosionSound = SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
let matchSound = SKAction.playSoundFileNamed("match.mp3", waitForCompletion: false)

let hahaSound = SKAction.playSoundFileNamed("haha.mp3", waitForCompletion: false)
let yahooSound = SKAction.playSoundFileNamed("yahoo.mp3", waitForCompletion: false)
let YAYSound = SKAction.playSoundFileNamed("YAY.mp3", waitForCompletion: false)
let EvilSound = SKAction.playSoundFileNamed("EvilLaugh.mp3", waitForCompletion: false)

var specialNodeResult = String()
var showTimeAdded: Bool = false
var showAllClear: Bool = false

class GameScene: SKScene {
    
    //Timer, controled by PlayViewCOntroller
    var time = NSTimer()
    var second = 60
    
    let floor_y = CGFloat(80)
    var timeBetweenShips : Double?
    var moverSpeed = 5.0
    let moveFactor = 1.05
    var now : NSDate?
    var nextTime : NSDate?
    var nextGen: NSDate?
    var gameOver : Bool?
    var bombsEachTime = 1
    var mean = 1.0
    let maxNumOfBombs = 10
    var numOfBombs = 0
    var onTrail = [0.0,0.0,0.0,0.0,0.0,0.0,0.0]
    var counter:Int = 0
    
    var pause = false
    var restart = false
    var hiddenNodes:[bombNode] = []
    
    //used for "increaseSpeed" Special Node, to record the time interval that bombNodes should increase speed
    var increaseSpeedTimeInterval: Int = 0
    
    override func didMoveToView(view: SKView) {
        backgroundColor = (UIColor.lightGrayColor())
        initializeValues()

    }
    
    func expRV(lambda: Float) -> Float {
        var u: Float
        do {
            u = Float(arc4random())/Float(UINT32_MAX)
        } while u == 1.0
        var x = log(1.0-u)/(-lambda)
        return x
    }
    
    /*
    Sets the initial values for our variables.
    */
    func initializeValues(){
        //NSLog("%@", "initial")
        self.removeAllChildren()
               
        timeBetweenShips = 1.0
        moverSpeed = 4.0
        nextTime = NSDate()
        nextGen = NSDate()
        now = NSDate()
        bombsEachTime = 3
        mean = 1.0
        numOfBombs = 0
        
        /* Set score display */
        scoreLabel = SKLabelNode(fontNamed:"Futura-Medium")
        scoreLabel.text = String(format: "%05d", score)
        score = 0
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = SKColor.blueColor()
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        scoreLabel.position = CGPoint(x:CGRectGetMaxX(self.frame) - 4, y:(CGRectGetMaxY(self.frame) - 40));
        //scoreLabel.position = CGPoint(x:CGRectGetMaxX(self.frame) - 8, y:(CGRectGetMaxY(self.frame) - 30));
        scoreLabel.zPosition = 3
        
        self.addChild(scoreLabel)
        /* End of set score display */
        
        /* Add the bottom line */
        var bottomLine = SKShapeNode()
        let lineToDraw = CGPathCreateMutable()
        CGPathMoveToPoint(lineToDraw, nil, CGRectGetMinX(self.frame), floor_y)
        CGPathAddLineToPoint(lineToDraw, nil, CGRectGetMaxX(self.frame), floor_y)
        bottomLine.path = lineToDraw
        bottomLine.strokeColor = SKColor.redColor()
        bottomLine.lineWidth = 4
        bottomLine.name = "bottomLine"
        self.addChild(bottomLine)
        /* End of add the bottom line */
        
        pause = false
        restart = false
        hiddenNodes.removeAll()
        
        /* Combo */
        comboString = String()
        comboRate = 1.0
        
        /* used for "increaseSpeed" Special Node */
        var increaseSpeedTimeInterval = 0
    }
    
    func increaseSpeed() {
        moverSpeed = moverSpeed - (0.001*(Double(score)))
        //timeBetweenShips = timeBetweenShips!/moveFactor
        /*
        if bombsEachTime <= 6 {
        bombsEachTime++
        }
        */
    }
    
    override func update(currentTime: CFTimeInterval) {
        
       if (!self.pause){

            if(self.restart)
            {
                
                for child in self.hiddenNodes{
                    child.hidden = false
                }
                self.hiddenNodes.removeAll()
                self.restart = false
                
            }

            self.paused = false
        
            now = NSDate()
        
            //NSInteger temp = int(now?.timeIntervalSince1970)
        
        
            if (now?.timeIntervalSince1970 > nextTime?.timeIntervalSince1970){
                
                nextTime = now?.dateByAddingTimeInterval(NSTimeInterval(0.1))
                
                for i in 0...onTrail.count-1 {
                    if (onTrail[i] > 0){
                        onTrail[i] = onTrail[i] - 0.1
                    }
                    else if(onTrail[i] < 0){
                        onTrail[i] = 0
                    }

                }

                if Int(arc4random_uniform(10))+1 < 6{
                        generateBomb()
                }
                
            }
        }
        
        if(specialNodeResult == "removeAllBombs"){
            
            /* if "removeAllBombs" is touched, remove all bombs and add score for all matched bombs */
            
            showAllClear = true
            for child in self.children{
                
                if child is bombNode{
                    
                    if(child.matched == true){
                        child.scoring(child.matched)
                    }
                    
                    child.runAction(SKAction.removeFromParent())
                }
            }
            
            //remove previous "All Clear" image and generate the new one
            for child in self.children{
                
                if child is specialNode{
                    
                    if(child.specialNode == "allClear"){
                        
                        child.runAction(SKAction.removeFromParent())
                    }
                }
            }
            generateBomb()
            
            if(showAllClear){
                showAllClear = false
            }
            
            specialNodeResult = String()
            
        }
        else if(specialNodeResult == "addTime"){
            
            /* if "addTime" is touched, add timer and show the image */
            
            showTimeAdded = true
            
            if(second+5 > 60){
                second = 60
            }
            else{
                second += 5
            }
            
            //remove previous "Time++" image and generate the new one
            for child in self.children{
                
                if child is specialNode{
                    
                    if(child.specialNode == "showTimeAdded"){
                        child.runAction(SKAction.removeFromParent())
                    }
                }
            }
            generateBomb()
            
            if(showTimeAdded){
                showTimeAdded = false
            }
            
            specialNodeResult = String()
        }
            
        else if(specialNodeResult == "increaseSpeed"){
            
            /* if "increaseSpeed" is touched, record time interval(5 seconds),
            change the speed for exsited bombs and generate the faster bombs during the time interval */
            
            increaseSpeedTimeInterval = second
            
            let duration = NSTimeInterval(0.8)
            
            let explode = SKAction.setTexture(SKTexture(imageNamed: "BOOM.png"))
            let explodeDuration = SKAction.waitForDuration(0.5)
            let hide = SKAction.hide()
            let childHide = SKAction.runAction(hide, onChildWithName: "colorName")
            
            for child in self.children{
                
                if child is bombNode{
                    let falling = SKAction.moveTo(child.bombDestination, duration: duration)
                    
                    
                    if child.matched == true {
                        child.runAction(SKAction.sequence([falling, childHide, explode, explodeDuration, SKAction.removeFromParent()]))
                    }
                    else {
                        child.runAction(SKAction.sequence([falling, hide, SKAction.removeFromParent()]))
                    }
                    
                }
            }
            
            specialNodeResult = String()
        }
        
        //initialize increaseSpeedTimeInterval
        if(second == increaseSpeedTimeInterval-5){
            increaseSpeedTimeInterval = 0
        }

    }
    
    func pauseGame(){

        self.pause = true
        
        for child in self.children{
            
            if child is bombNode{
                
                let hide = SKAction.hide()
                child.runAction(SKAction.sequence([hide, SKAction.runBlock(self.pauseAction)]))
                
                //NSLog("%@", "hidden")
                if let node=child as?bombNode
                {
                    self.hiddenNodes.append(node)
                }
            }
        }
    }
 
    func pauseAction(){
        self.paused = true
    }
    
    func generateBomb(){
        
        if(showTimeAdded){
            /* generate TimeAdded image */
            
            let start = CGPoint(x: 4*Int(self.frame.width)/5, y:Int(self.frame.height) - 65)
            let end =  CGPoint(x: 3*Int(self.frame.width)/5, y: Int(self.frame.height) - 65)
            addItem(start, destination: end)
        }
        else if(showAllClear){
            /* generate allClear image */
            
            let start =  CGPoint(x: 3*Int(self.frame.width)/5, y: Int(self.frame.height) - 65)
            let end = CGPoint(x: 4*Int(self.frame.width)/5, y:Int(self.frame.height) - 65)
            addItem(start, destination: end)
        }
        else{

            let width = Int(self.frame.width) - 80
        
            var newX = 40 + ((arc4random()%7) * UInt32(40))
        
            //var newX = 40 + (arc4random() %  UInt32(width))
        
            var newY = Int(self.frame.height) + 10
        
            var pp = CGPoint(x:Int(newX), y:newY)
            var destinationp = CGPoint(x:Int(newX), y:80)
        
            addItem(pp, destination: destinationp)
        }
    }
    
    
    func addItem(p:CGPoint, destination:CGPoint){
        
        let nodeChoose = Int(arc4random_uniform(10)) + 1
        
        if nodeChoose <= (Int)(0.1*10) || showTimeAdded || showAllClear{
            
            /* generate showTimeAdd image or 10% chance to peoduce Special Node */
            var trailNum = (Int(p.x)/40)-1
            
            var item:specialNode = specialNode()
            
            item.xScale = 0.4
            item.yScale = 0.4
            item.position = p
            
            var duration = NSTimeInterval()
            
            if(item.specialNode == "removeAllBombs" || item.specialNode == "addTime"){
                duration = NSTimeInterval(1.5)
            }
            else if(item.specialNode == "showTimeAdded" || item.specialNode == "allClear" ){
                duration = NSTimeInterval(1)
            }
            else{
                duration = NSTimeInterval(4)
            }
            
            let falling = SKAction.moveTo(destination, duration: duration)
            
            let hide = SKAction.hide()
            
            item.runAction(SKAction.sequence([falling, hide, SKAction.removeFromParent()]))
            
            if(item.specialNode == "showTimeAdded" || item.specialNode == "allClear" ){
                self.addChild(item)
            }

            let durInt:Double = Double(duration)
            
            /*avoid overlap from current and nearby trails*/
            if (trailNum == 0){
                if (onTrail[trailNum]+1 < durInt && onTrail[trailNum+1]+1 < durInt){
                    onTrail[trailNum] = durInt
                    self.addChild(item)
                }
            }
            else if (trailNum == onTrail.count-1){
                if (onTrail[trailNum]+1 < durInt && onTrail[trailNum-1]+1 < durInt){
                    onTrail[trailNum] = durInt
                    self.addChild(item)
                }
            }
            else{
                if ((onTrail[trailNum]+1 < durInt) && (onTrail[trailNum+1]+1 < durInt) && (onTrail[trailNum-1]+1 < durInt)){
                    onTrail[trailNum] = durInt
                    self.addChild(item)
                }
            }
            /*end of avoiding overlap*/
            
        }
        else{

            var trailNum = (Int(p.x)/40)-1
            //println(trailNum)
        
            var item:bombNode = bombNode()
        
            item.name = "Destroyable"
            item.xScale = 0.4
            item.yScale = 0.4
            item.position = p
        
            item.bombDestination = destination
            
            var duration = NSTimeInterval()
            if((increaseSpeedTimeInterval>0) && (second<increaseSpeedTimeInterval && second>=increaseSpeedTimeInterval-5)){
                duration = NSTimeInterval(1)
            }
            else{
                duration = NSTimeInterval(moverSpeed*item.mySpeedFactor)
            }

            let falling = SKAction.moveTo(destination, duration: duration)
        
            let durInt:Double = Double(duration)
        
        
            let explode = SKAction.setTexture(SKTexture(imageNamed: "BOOM.png"))
            let explodeDuration = SKAction.waitForDuration(0.5)
            let hide = SKAction.hide()
            let childHide = SKAction.runAction(hide, onChildWithName: "colorName")
        
            if item.matched == true {
                item.runAction(SKAction.sequence([falling, childHide, explode, explodeDuration, SKAction.removeFromParent()]))
            }
            else {
                item.runAction(SKAction.sequence([falling, hide, SKAction.removeFromParent()]))
            }
        
            /*avoid overlap from current and nearby trails*/
            if (trailNum == 0){
                if (onTrail[trailNum]+1 < durInt && onTrail[trailNum+1]+1 < durInt){
                    onTrail[trailNum] = durInt
                    self.addChild(item)
                }
            }
            else if (trailNum == onTrail.count-1){
                if (onTrail[trailNum]+1 < durInt && onTrail[trailNum-1]+1 < durInt){
                    onTrail[trailNum] = durInt
                    self.addChild(item)
                }
            }
            else{
                if ((onTrail[trailNum]+1 < durInt) && (onTrail[trailNum+1]+1 < durInt) && (onTrail[trailNum-1]+1 < durInt)){
                    onTrail[trailNum] = durInt
                    self.addChild(item)
                }
            }
            /*end of avoiding overlap*/
        }
    }
    
    func getScore() -> Int{
        
        return score
    }
    
    class specialNode: SKSpriteNode{
        
        let specialNodeOptions = ["addTime", "removeAllBombs", "increaseSpeed"]
        var specialNode = String()
        
        override init() {
            
            if(showTimeAdded){
                specialNode = "showTimeAdded"
            }
            else if(showAllClear){
                specialNode = "allClear"
            }
            else{
                
                //randomly choose special event
                specialNode = specialNodeOptions[Int(arc4random_uniform(3))]
            }
            
            let texture = SKTexture(imageNamed: specialNode)
            
            //set the size for each specialNode, and make it touchable(only "showTimeAdded" & "allClear" canNot be touched)
            switch(specialNode){
            case "addTime":
                super.init(texture: texture, color: UIColor.clearColor(), size: CGSize(width: 120, height: 110))
                super.userInteractionEnabled = true
            case "removeAllBombs":
                super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
                super.userInteractionEnabled = true
            case "increaseSpeed":
                super.init(texture: texture, color: UIColor.clearColor(), size: CGSize(width: 220, height: 250))
                super.userInteractionEnabled = true
            case "showTimeAdded":
                super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
            case "allClear":
                super.init(texture: texture, color: UIColor.clearColor(), size:  CGSize(width: 150, height: 150))
            default:
                super.init(texture: texture, color: UIColor.clearColor(), size: CGSize(width: 120, height: 110))
                super.userInteractionEnabled = true
            }
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
            
            userInteractionEnabled = false
            let hide = SKAction.hide()
            
            switch(specialNode){
            case "addTime":
                //NSLog("%@", "addTime")
                specialNodeResult = "addTime"
                let addTimePic = SKAction.setTexture(SKTexture(imageNamed: "addTime.png"))
                let hideDuration = SKAction.waitForDuration(0.5)
                self.runAction(SKAction.sequence([YAYSound, hide, addTimePic, hideDuration, SKAction.removeFromParent()]))
                
            case "removeAllBombs":
                //NSLog("%@", "removeAllBombs")
                specialNodeResult = "removeAllBombs"
                self.runAction(SKAction.sequence([yahooSound, hide, SKAction.removeFromParent()]))
                
                //initialize comboString & comboRate
                comboString = String()
                comboRate = 1.0
                
            case "increaseSpeed":
                //NSLog("%@", "increaseSpeed")
                specialNodeResult = "increaseSpeed"
                self.runAction(SKAction.sequence([EvilSound, hide, SKAction.removeFromParent()]))
                
            default:
                //NSLog("%@", "error")
                specialNodeResult = "removeAllBombs"
            }
            
            
        }
        
    }

    class bombNode: SKSpriteNode{
        
        let colorOptions = ["blue", "brown", "gray", "green", "orange", "pink", "red", "purple", "yellow"]
        var myColor:String
        var myText:String
        var matched:Bool
        var mySpeedFactor: Double
        var myScore: Double
        
        var bombDestination:CGPoint
        
        override init() {
            myColor = colorOptions[Int(arc4random_uniform(9))]      //randomly choose color
            myText = colorOptions[Int(arc4random_uniform(9))]       //randomly choose color text
            
            matched = (myColor == myText)
            mySpeedFactor = Double(4+Float(arc4random_uniform(7)))/Double(10) //choose a random number between 0.4~1
            
            myScore = Double(10)/mySpeedFactor    //myscore = 10/speedfactor (10~40)
            
            bombDestination = CGPoint(x:40, y:80)
            
            let texture = SKTexture(imageNamed: myColor)
            super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
            
            decideText(0.6)     //60% chance the text and color will match.
            var textLabel = SKLabelNode()
            textLabel.name = "colorName"
            textLabel.text = randomCapitalize(myText)
            textLabel.fontName = "System-Bold"
            textLabel.fontSize = 45
            textLabel.fontColor = SKColor.blackColor()
            textLabel.position = CGPoint(x: 0, y: -50)
            super.addChild(textLabel)
            super.userInteractionEnabled = true
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
            
            //No bombs can be touches more than 1 time
            userInteractionEnabled = false
            
            let explode = SKAction.setTexture(SKTexture(imageNamed: "BOOM.png"))
            let explodeDuration = SKAction.waitForDuration(0.5)
            let hide = SKAction.hide()
            let childHide = SKAction.runAction(hide, onChildWithName: "colorName")
            
            if matched == false {
                
                //initialize comboString & comboRate
                comboString = String()
                comboRate = 1.0
                
                 self.runAction(SKAction.sequence([explosionSound, childHide, explode, explodeDuration, SKAction.removeFromParent()]))
                
            }
            else{
                
                if (comboString.isEmpty){
                    
                    /* If the comboString is empty, this is the 1st bomb that the player touches.
                          Record this bomb, initilize the comboRate, show match sound */
                    
                    comboString = myColor + "," + myText
                    comboRate = 1.0
                    self.runAction(SKAction.sequence([matchSound, hide, SKAction.removeFromParent()]))
                }
                else{
                    
                    /* If the comboString is NOT empty, this is NOT the 1st bomb that the player touches.
                          Identify whether there is Combo(current bomb that the player touches is same as the previous one) or not. */

                    if(comboString == myColor + "," + myText){
                        
                        /* If Combo happens, compute the comboRate, show Combo image, Combo sound, and match sound */
                        
                        comboRate += 0.1
                        
                        //create new combo image(to combine original combo image and comboRate text)
                        let comboImage = UIImage(named: "Combo.png")
                        var comboText = "x" + String(format:"%.1f", comboRate)
                        var newComboImage = drawText(comboImage!, text: comboText)
                        var combo = SKAction.setTexture(SKTexture(image: newComboImage))
                        
                        let comboDuration = SKAction.waitForDuration(0.5)
                        
                        let comboSoundOption = Int(arc4random_uniform(3))
                        
                        var comboSound: SKAction
                        switch(comboSoundOption)
                        {
                        case 0: comboSound = hahaSound
                        case 1: comboSound = yahooSound
                        case 2: comboSound = YAYSound
                        default: comboSound = hahaSound
                        }
                        
                        self.runAction(SKAction.sequence([comboSound, childHide, combo,  comboDuration, SKAction.removeFromParent()]))
                    }
                    else{
                        
                        /* If Combo does NOT happen, initialize comboRate, record this bomb, show match sound */
                        
                        comboRate = 1.0
                        comboString = myColor + "," + myText
                        self.runAction(SKAction.sequence([matchSound, hide, SKAction.removeFromParent()]))
                    }
                }
            }
            scoring(matched)
        }
        
        func scoring(add: Bool) {
            if add == true {
                myScore *= comboRate
                score += Int(round(myScore))
            }
            else {
                if score < Int(round(myScore)) {
                    score = 0
                }
                else{
                    score -= Int(round(myScore))
                }
            }
        }
        
        /* Add text to combo image and return this new image */
        func drawText(image :UIImage, text:String) ->UIImage
        {
            UIGraphicsBeginImageContext(image.size);
            
            //draw 1st image
            let imageRect = CGRectMake(0,0,image.size.width,image.size.height)
            image.drawInRect(imageRect)
            
            //draw 2nd image(text part)
            let textRect  = CGRectMake(5, -1, image.size.width-20, image.size.height - 20)
            let font = UIFont.boldSystemFontOfSize(28)
            
            let textFontAttributes = [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: UIColor.redColor(),
            ]
            text.drawInRect(textRect, withAttributes: textFontAttributes)
            
            //get the screen shot for current image context
            let newImage = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext()
            
            return newImage
        }

        func decideText(factor: Double) {
            let choose = Int(arc4random_uniform(10)) + 1
            if choose <= (Int)(factor*10)  {
                matched = true
                myText = myColor
            }
            
        }
        
        func randomCapitalize(input: String) -> String {
            var output = ""
            for character in input {
                let pick = Int(arc4random_uniform(2))
                if pick == 1 {
                    output += String(character).uppercaseString
                }
                else {
                    output += String(character)
                }
            }
            return output
        }
        
        func explode(){
            self.removeAllChildren()
        }
    }
}
