//
//  LottieOverlay.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 09/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie

public class LottieOverlay{

    var animationView: LottieAnimationView?
    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var orientation : UIDeviceOrientation = UIDeviceOrientation.portrait
    
    init(name: String){
        animationView = LottieAnimationView(name: name)
    }
    
    
    
    class var shared: LoadingOverlay {
        struct Static {
            static let instance: LoadingOverlay = LoadingOverlay()
        }
        return Static.instance
    }
    
    public func show() {
        if  let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window {

            let width = Int((window.frame.size.width)/2.5)

            // 1. Set animation content mode
            //animationView!.contentMode = .scaleAspectFit
            // 2. Set animation loop mode
            //animationView.loopMode = .loop
            // 3. Adjust animation speed
            animationView!.animationSpeed = 0.5
            // 4. Play animation

            
            //animationView!.s setScale(3.0);
            animationView!.frame = CGRect(x: 0, y: 0, width: width, height: width)
            animationView!.center = CGPoint(x: window.frame.width / 2.0, y: window.frame.height / 2.0)
            animationView!.contentMode = .scaleAspectFit
            if(orientation == .landscapeLeft){
                animationView!.transform = CGAffineTransformMakeRotation(90 * Double.pi/180);
            }
            
            animationView!.translatesAutoresizingMaskIntoConstraints = false
            animationView!.play()
            window.addSubview(animationView!)

            animationView!.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
            animationView!.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
            animationView!.heightAnchor.constraint(equalToConstant: CGFloat(width)).isActive = true
            animationView!.widthAnchor.constraint(equalToConstant: CGFloat(width)).isActive = true

        }
    }
    public func hide() {
        animationView?.removeFromSuperview()
        
        //activityIndicator.stopAnimating()
        //overlayView.removeFromSuperview()
    }
    
    public func stop() {
        animationView?.stop()
    }
    
}
