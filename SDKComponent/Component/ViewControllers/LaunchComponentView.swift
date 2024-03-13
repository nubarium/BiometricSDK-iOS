//
//  LaunchComponentView.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 10/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie


public class LaunchComponentView: UIView {
    
    private var fn:(()->Void)?
    
    @IBOutlet weak var animationView: LottieAnimationView!
    @IBAction func action(_ sender: Any) {
        hideView()
        fn!()
    }

    public func onClose( fn:(()->Void)? ){
        self.fn = fn
    }
    
    public func showView(){
        if (self.isHidden){
            var rect = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
            rect.origin.x = rect.origin.x + 440;
            self.isHidden = false
            //options: .transitionCrossDissolve,
            UIView.transition(with: self, duration: 0.4,  animations: {
                self.frame = rect;
            }, completion: { _ in  });
        }
    }
    
    private func hideView(){
        if (!self.isHidden){
            var rect = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
            rect.origin.x = rect.origin.x - 440;
            //options: .transitionCrossDissolve,
            UIView.transition(with: self, duration: 0.5,  animations: {
                self.frame = rect;
            }, completion: { _ in self.isHidden = true });
        }
    }

    public override init(frame: CGRect) {
        print("uno")
        super.init(frame: frame)
        viewInit()
    }
    
    public required init?(coder: NSCoder) {
        print("dos")
        super.init(coder: coder)
        viewInit()
    }
    
    func viewInit(){
        let xibView = Bundle.main.loadNibNamed("LaunchComponentView", owner: self, options: nil)![0] as! UIView
        xibView.frame = self.bounds
        self.addSubview(xibView)
        animateLottie()
    }
    
    func animateLottie(){
        // 1. Set animation content mode
        animationView.contentMode = .scaleAspectFit
        // 2. Set animation loop mode
        animationView.loopMode = .loop
        // 3. Adjust animation speed
        animationView.animationSpeed = 0.6
        // 4. Play animation
        animationView.play()
    }
}
