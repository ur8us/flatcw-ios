//
//  ViewController.swift
//  FlatCW
//
//  Created by Mini2012 on 12.03.2020.
//  Copyright © 2020 Denis Nechitailov. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    // Touch
    
//    var touchNumbersDit = [UITouch:Int]()
//    var touchNumbersDah = [UITouch:Int]()
    var touchNumbersDit = Set<UITouch>()
    var touchNumbersDah = Set<UITouch>()

//    var touchDit:UITouch?
//    var touchDah:UITouch?

    // CW Keyer
    
    var speedWpm: Float = 20.0
    var keyerInverse: Bool = false
    var useTorch: Bool = false

    enum CWSTATES {
        case CW_NONE
        case CW_SENDING_DIT
        case CW_SENDING_DAH
        case CW_PAUSE_AFTER_DIT
        case CW_PAUSE_AFTER_DAH
    }
    
    var cwState = CWSTATES.CW_NONE
    
    var memDit = false
    var memDah = false
    
    // Controls
    
    @IBOutlet weak var keyerSpeed: UILabel!
    @IBOutlet weak var keyerDirection: UILabel!
    @IBOutlet weak var sliderSpeed: UISlider!
    @IBOutlet weak var switchInverse: UISwitch!
    @IBOutlet weak var switchTorch: UISwitch!
    
    // Audio
    
    var engine: AVAudioEngine!
    var tone: AVTonePlayerUnit!
    
    // Timer
    
    var cwTimer: Timer?
    var endTime = CACurrentMediaTime()
    
    // Timer functions
    
    func setupTimer() {
        cwTimer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    
    @objc func fireTimer() {
        //print("ft")
        
        //timer?.invalidate()
        
        //print("tol: \(timer?.tolerance)")
        
        let curTime = CACurrentMediaTime()
  //      var newEnd = endTime
//        let interval = newTime - oldTime
//        oldTime = newTime
//        print("interval: \(interval)")
        
        switch cwState {
            case CWSTATES.CW_NONE:
                if isDitPressed() {
                    endTime = curTime + getDitTime()
                    soundOn()
                    memDit = false
                    cwState = CWSTATES.CW_SENDING_DIT
                }
                else
                if isDahPressed() {
                    endTime = curTime + getDahTime()
                    soundOn()
                    memDah = false
                    cwState = CWSTATES.CW_SENDING_DAH
                }
            case CWSTATES.CW_SENDING_DIT:
                if curTime >= endTime {
                    endTime += getPauseTime()
                    soundOff()
                    cwState = CWSTATES.CW_PAUSE_AFTER_DIT
                }
                
            case CWSTATES.CW_SENDING_DAH:
                if curTime >= endTime {
                    endTime += getPauseTime()
                    soundOff()
                    cwState = CWSTATES.CW_PAUSE_AFTER_DAH
                }
        
            case CWSTATES.CW_PAUSE_AFTER_DIT:
                if curTime >= endTime {
                    if isDahPressed() || memDah {
                        endTime += getDahTime()
                        soundOn()
                        memDah = false
                        cwState = CWSTATES.CW_SENDING_DAH
                    }
                    else
                    if isDitPressed() || memDit {
                        endTime += getDitTime()
                        soundOn()
                        memDit = false
                        cwState = CWSTATES.CW_SENDING_DIT
                    }
                    else {
                        cwState = CWSTATES.CW_NONE
                    }
                }

            
              case CWSTATES.CW_PAUSE_AFTER_DAH:
                if curTime >= endTime {
                    if isDitPressed() || memDit {
                        endTime += getDitTime()
                        soundOn()
                        memDit = false
                        cwState = CWSTATES.CW_SENDING_DIT
                    }
                    else
                    if isDahPressed() || memDah {
                        endTime += getDahTime()
                        soundOn()
                        memDah = false
                        cwState = CWSTATES.CW_SENDING_DAH
                    }
                    else {
                        cwState = CWSTATES.CW_NONE
                    }
                }
        }
    }
    
    // Audio functions
    
    func prepareAudio() {
        // Do any additional setup after loading the view, typically from a nib.
        tone = AVTonePlayerUnit()

        let format = AVAudioFormat(standardFormatWithSampleRate: tone.sampleRate, channels: 1)
        print(format?.sampleRate ?? "format nil")
        engine = AVAudioEngine()
        engine.attach(tone)
        let mixer = engine.mainMixerNode
        engine.connect(tone, to: mixer, format: format)
        
        soundOff()
        
        do {
            try engine.start()
        } catch let error as NSError {
            print(error)
        }
        
       
        tone.preparePlaying()
        tone.play()
        
    }
    
    func soundOn() {
        engine.mainMixerNode.outputVolume = 1.0
        if useTorch {
            setTorch(true)
        }
    }
    
    func soundOff() {
        engine.mainMixerNode.outputVolume = 0.0
        if useTorch {
            setTorch(false)
        }
    }
    
    // Control functions
    
    func updateLabels() {
        if (keyerInverse) {
            keyerDirection.text = "Left: DAH             Right: DIT"
        }
        else {
            keyerDirection.text = "Left: DIT             Right: DAH"
        }
        
        keyerSpeed.text = "Speed: " + String(Int(speedWpm)) + " WPM"
        
        switchInverse?.setOn(keyerInverse, animated:false)
        switchTorch?.setOn(useTorch, animated:false)
        
//        let context = UIGraphicsGetCurrentContext()
//        if context != nil {
//            context!.setLineWidth(2.0)
//            context!.setStrokeColor(UIColor.red.cgColor)
//            context!.move(to:CGPoint(x:0, y: self.view.frame.size.height))
//            context!.addLine(to:CGPoint(x:self.view.frame.size.width, y: 0))
//        }
    }
    


    @IBAction func sliderValueChanged (_ sender: UISlider) {
        
        speedWpm = sliderSpeed.value
        
        // Defaults
        let defaults = UserDefaults.standard
        defaults.set(speedWpm, forKey: "speedWpm")
        
        updateLabels()
    }
    
    @IBAction func switchInverseChanged(_ sender: UISwitch) {
        
        if switchInverse != nil {
            keyerInverse = switchInverse.isOn
            
            // Defaults
            let defaults = UserDefaults.standard
            defaults.set(keyerInverse, forKey: "keyerInverse")
        }
        
        updateLabels()
    }
    
    @IBAction func switchTorchChanged(_ sender: Any) {
        if switchTorch != nil {
            useTorch = switchTorch.isOn
            
            // Defaults
            let defaults = UserDefaults.standard
            defaults.set(useTorch, forKey: "useTorch")
        }
        
        updateLabels()}
    
  // Functions
    
    func getDitTime() -> Double {
        return Double(1.2000/speedWpm)
    }
    
    func getDahTime() -> Double {
        return Double(3.0*1.2000/speedWpm)
    }
    
    func getPauseTime() -> Double {
        return Double(1.2000/speedWpm)
    }
    
    func isDitPressed() -> Bool {
        return touchNumbersDit.count > 0;
    }
    
    func isDahPressed() -> Bool {
        return touchNumbersDah.count > 0;
    }
    

    // User interface
    
    override func viewDidLoad() {
       super.viewDidLoad()
    
        // Defaults
        let defaults = UserDefaults.standard
        
        speedWpm = defaults.float(forKey: "speedWpm")
        if speedWpm < 1 {
            speedWpm = 20.0
        }
        keyerInverse = defaults.bool(forKey: "keyerInverse")
        useTorch = defaults.bool(forKey: "useTorch")

        
       // Controls
        
       self.view.isMultipleTouchEnabled = true
       
       sliderSpeed.value = speedWpm
       updateLabels()
    
       prepareAudio()
       setupTimer()
        
       // Events
        
       let notificationCenter = NotificationCenter.default
       notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

      // Line
        
//        let aPath = UIBezierPath()
//        UIColor.red.set()
//        aPath.move(to:CGPoint(x:10,y:10))
//        aPath.move(to:CGPoint(x:400,y:400))
//        aPath.close()
        

//        let line = LineView
   }
    
   // Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
         
         
 //        let touchCount = touches.count
 //        let touch = touches.first
 //        let tapCount = touch!.tapCount
        
         
//         methodStatus.text = "touchesBegan"
//         touchStatus.text = "\(touchCount) touches"
//         tapStatus.text = "\(tapCount) taps"
         
         
         
         // https://stackoverflow.com/questions/28696500/get-coordinates-of-multiple-touches-in-swift
         
//         print("------")
//         for touch2 in touches {
//             let location = touch2.location(in: self.view)
//             print(location)
//
//             touchNumbers[touch2] = touch2.hash;
//             print("touch add: \(String(touch2.hash, radix: 16))")
//
//         }
         

        for touch in touches {
            //print("------")
            let locationX = touch.location(in: self.view).x
            let sizeX = self.view.bounds.width
            
            if (!keyerInverse && (locationX <= sizeX/2)) ||
               (keyerInverse && (locationX > sizeX/2)) {
 //               print(".")
//                touchNumbersDit[touch] = touch.hash;
                touchNumbersDit.insert(touch)
            } else {
 //               print("-")
//                touchNumbersDah[touch] = touch.hash;
                touchNumbersDah.insert(touch)
            }
            //print(location)
            
            //print(self.view.bounds.width, " ", self.view.bounds.height)
        }
        
     }
     
     override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//         let touchCount = touches.count
//         let touch = touches.first
//         let tapCount = touch!.tapCount

//         methodStatus.text = "touchesMoved";
//         touchStatus.text = "\(touchCount) touches"
//         tapStatus.text = "\(tapCount) taps"
     }
     
     override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//         let touchCount = touches.count
//         let touch = touches.first
//         let tapCount = touch!.tapCount

//         methodStatus.text = "touchesEnded";
//         touchStatus.text = "\(touchCount) touches"
//         tapStatus.text = "\(tapCount) taps"
//

//         for touch2 in touches {
//
//             touchNumbers.removeValue(forKey: touch2    )
//
//             print("touch remove: \(String(touch2.hash, radix: 16))")
//         }

            for touch in touches {
        
//                touchNumbersDit.removeValue(forKey: touch)
//                 touchNumbersDah.removeValue(forKey: touch)
                touchNumbersDit.remove(touch)
                touchNumbersDah.remove(touch)

            }
        
     }

    // User interface

    @objc func appMovedToBackground() {
        print("App moved to background!")
        
        touchNumbersDit.removeAll()
        touchNumbersDah.removeAll()
        
        soundOff()
    }

    // Torch
    
    func hasTorch() -> Bool {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return false}
        
        guard device.hasTorch else { return false}
        
        return true
    }
    // https://stackoverflow.com/questions/27207278/how-to-turn-flashlight-on-and-off-in-swift
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func setTorch(_ state: Bool) {
        
         guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
         
         guard device.hasTorch else { return }

         do {
             try device.lockForConfiguration()

             if (!state /*device.torchMode == AVCaptureDevice.TorchMode.on*/) {
                 device.torchMode = AVCaptureDevice.TorchMode.off
             } else {
                 do {
                     try device.setTorchModeOn(level: 1.0)
                 } catch {
                     print(error)
                 }
             }

             device.unlockForConfiguration()
         } catch {
             print(error)
         }
     }

}

