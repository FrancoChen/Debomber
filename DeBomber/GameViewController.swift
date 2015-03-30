//
//  GameViewController.swift
//  DeBomber
//
//  Created by Linda on 2/23/15.
//  Copyright (c) 2015 MatchStick. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController, PlayViewControllerDelegate{

    @IBOutlet weak var segment: UISegmentedControl!

    var backgroundPlayer = AVAudioPlayer()
    var backgroundURL: NSURL!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //background Music
        backgroundURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("gameView", ofType: "mp3")!)
        backgroundPlayer = AVAudioPlayer(contentsOfURL: backgroundURL, error: nil)
        backgroundPlayer.numberOfLoops = -1
        backgroundPlayer.volume = 0.5
        backgroundPlayer.enableRate = true
        backgroundPlayer.rate = 1.0
        backgroundPlayer.play()

    }
    
    //send data from 1st view(GameViewController) to 2nd view(PlayViewController)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
       
        var secondVC: PlayViewController = segue.destinationViewController as PlayViewController;
        
        backgroundPlayer.stop()
        secondVC.delegate = self
      
        if segment.selectedSegmentIndex == 0
        {
            secondVC.difficulty = 0
        }
        else if segment.selectedSegmentIndex == 1
        {
            secondVC.difficulty = 1
        }

    }
    
    //replay background Music when back to the 1st View
    func replayBackgroundMusic(controller: PlayViewController){
        
        backgroundPlayer.play()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}
