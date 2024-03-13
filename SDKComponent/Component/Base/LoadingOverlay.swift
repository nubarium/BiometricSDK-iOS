//
//  LoadingOverlay.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 08/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation
import UIKit

public class LoadingOverlay{

    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()

    class var shared: LoadingOverlay {
        struct Static {
            static let instance: LoadingOverlay = LoadingOverlay()
        }
        return Static.instance
    }
    
    public func showOverlay() {
        if  let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window {
            overlayView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            overlayView.center = CGPoint(x: window.frame.width / 2.0, y: window.frame.height / 2.0)
            overlayView.backgroundColor = .systemGray6
            overlayView.clipsToBounds = true
            overlayView.layer.cornerRadius = 10
            //activityIndicator.backgroundColor = .systemTeal
            //activityIndicator.backgroundColor = UIColor(cgColor: CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 0.5])! )
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            activityIndicator.style = UIActivityIndicatorView.Style.large
            activityIndicator.center = CGPoint(x: overlayView.bounds.width / 2, y: overlayView.bounds.height / 2)
            if #available(iOS 15.0, *) {
                activityIndicator.color = .systemCyan
                activityIndicator.color = .systemBlue
            }else{
                activityIndicator.color = .systemBlue
            }
            
            overlayView.addSubview(activityIndicator)
            window.addSubview(overlayView)

            activityIndicator.startAnimating()
        }
    }
    public func hideOverlayView() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
    }
}
