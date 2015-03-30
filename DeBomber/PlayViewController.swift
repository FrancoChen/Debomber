//
//  PlayViewController.swift
//  DeBomber
//
//  Created by Linda on 2/23/15.
//  Copyright (c) 2015 MatchStick. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

//When back to the 1st View(the 2nd View is dismissed), replay the background music of the 1st view
//Since 1st view is the root, which must not be removed when calling the 2nd view. It only can be covered by the 2nd view
protocol PlayViewControllerDelegate{

    
    func replayBackgroundMusic(controller: PlayViewController)
}

class PlayViewController: UIViewController {
    
    var difficulty:Int = 0
    var scene: GameScene!
    
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var progressTime: UIProgressView!
    
    //Used for 10s left
    @IBOutlet weak var clockImageView: UIImageView!
    @IBOutlet weak var HurryUpImageView: UIImageView!
    
    //var time = NSTimer()
    //var second = 60
    
    //background music
    var backgroundPlayer = AVAudioPlayer()
    var backgroundURL: NSURL!
    
    //10s Left sound
    var tenSecPlayer = AVAudioPlayer()
    var tenSecURL: NSURL!
    var tenSecSoundPlaying = Bool()
    
    //Time's Up sound
    var ohohPlayer = AVAudioPlayer()
    var ohohURL: NSURL!
    
    var delegate:PlayViewControllerDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
        
        // Do any additional setup after loading the view.
    }
    
    func setupGame()  {
        /*
        second = 60
        progressTime.progress = Float(second) / 60.0
        time = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateTime"), userInfo: nil, repeats: true)
        */
        
        // Configure the view.
        let skView = view as SKView
        skView.multipleTouchEnabled = false
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        // Present the scene.
        skView.presentScene(scene)
        
        scene.second = 60
        progressTime.progress = Float(scene.second) / 60.0
        scene.time = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateTime"), userInfo: nil, repeats: true)

        //background Music
        backgroundURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("playView", ofType: "mp3")!)
        backgroundPlayer = AVAudioPlayer(contentsOfURL: backgroundURL, error: nil)
        backgroundPlayer.numberOfLoops = -1
        backgroundPlayer.volume = 0.5
        backgroundPlayer.enableRate = true
        backgroundPlayer.rate = 1.0
        backgroundPlayer.play()
        
        /*
        In some cases, when the "addTime" specialNode is touched, and timer is added from less than 10s to more than 10s,
        we have to initialize all events that occur when the timer is less than 10s. "tenSecSoundPlaying" is to indicate whether those related variables occurs or not.
        */
        tenSecSoundPlaying = false
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTime(){
        
        scene.second--
        //NSLog("%d", scene.second)
        //second-=10
        
        progressTime.progress = Float(scene.second) / 60.0
        
        if (scene.second == 0){
            
            scene.time.invalidate()
            self.scene.pause = true
            
            let alert = UIAlertController(title: "Time's up!",
                message: String(scene.getScore()),
                preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                action in
                self.dismissViewControllerAnimated(true, completion:nil)
                
                if (self.delegate != nil){
                    self.delegate!.replayBackgroundMusic(self)
                }

            }))
            
            presentViewController(alert, animated: true, completion:nil)
            
            //"OhOh~" Time's Up Sound
            ohohURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("ohoh", ofType: "mp3")!)
            ohohPlayer = AVAudioPlayer(contentsOfURL: ohohURL, error: nil)
            ohohPlayer.volume = 1.0
            ohohPlayer.play()
            
            /*
            //"Time's Up" Sound
            let synth = AVSpeechSynthesizer()
            var myUtterance = AVSpeechUtterance(string: "Time's Up")
            myUtterance.rate = 0.1
            myUtterance.volume = 1.5
            myUtterance.pitchMultiplier = 2.0
            myUtterance.preUtteranceDelay = 0.3
            synth.speakUtterance(myUtterance)
            */
            
            backgroundPlayer.stop()
            
            clockImageView.stopAnimating()
            clockImageView.image = UIImage(named: "clock1.png")
            
            HurryUpImageView.stopAnimating()
            HurryUpImageView.image = UIImage()
        }
        else if(scene.second <= 10){
            
            if(scene.second == 10){
                
                //Ten Second Music
                tenSecURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("BeeDo", ofType: "mp3")!)
                tenSecPlayer = AVAudioPlayer(contentsOfURL: tenSecURL, error: nil)
                tenSecPlayer.volume = 2.0
                tenSecPlayer.play()
                
                //increase the speed of background music
                backgroundPlayer.enableRate = true
                backgroundPlayer.rate = 1.5
                
                //show "Hurry Up!!!" label
                HurryUpImageView.stopAnimating()
                HurryUpImageView.image = UIImage(named: "HurryUp1.png")
                
            }
            
            //make clock image flush
            var clockList = [UIImage]()
            clockList += [UIImage(named: "clock1")!, UIImage(named: "clock2")!, UIImage(named: "clock3")!]
            clockImageView.animationImages = clockList
            clockImageView.startAnimating()
            
            //"Hurry Up!!!" flush
            var hurryUpList = [UIImage]()
            hurryUpList += [UIImage(named: "HurryUp1")!, UIImage(named: "HurryUp2")!, UIImage(named: "HurryUp3")!]
            HurryUpImageView.animationImages = hurryUpList
            HurryUpImageView.startAnimating()
            
        }
        else{///////////////
            if(tenSecSoundPlaying){
                
                //initialize all events that occur when the timer is less than 10s
                tenSecPlayer.pause()
                
                backgroundPlayer.rate = 1.0
                
                clockImageView.stopAnimating()
                clockImageView.image = UIImage(named: "clock1.png")
                
                HurryUpImageView.stopAnimating()
                HurryUpImageView.image = UIImage()
                
                tenSecSoundPlaying = false
            }
        }
        
    }
    
    @IBAction func stopButtonPressed(){
        
        scene.time.invalidate()
        scene.pauseGame()
        
        let alert = UIAlertController(title: "*Pause*",
            message: nil,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Default, handler: {
            action in
            self.scene.time = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateTime"), userInfo: nil, repeats: true)
           
            self.scene.restart = true
            self.scene.pause = false
        }))
        
        alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default, handler: {
            action in
            
            if(self.tenSecSoundPlaying){
                self.clockImageView.stopAnimating()
                self.clockImageView.image = UIImage(named: "clock1.png")
                
                self.HurryUpImageView.stopAnimating()
                self.HurryUpImageView.image = UIImage()
            }
            
            self.setupGame()
        }))
        
        alert.addAction(UIAlertAction(title: "Main", style: UIAlertActionStyle.Default, handler: {
            action in
            
                self.dismissViewControllerAnimated(true, completion: nil)
            
                if (self.delegate != nil){
                    self.delegate!.replayBackgroundMusic(self)
                }
            
        }))
        presentViewController(alert, animated: true, completion:nil)
        
    }
}
