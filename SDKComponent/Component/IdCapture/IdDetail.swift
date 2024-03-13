//
//  IdDetail.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 17/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import MLKitFaceDetection
import UIKit
import CoreMedia

struct IdDetail {
    
    private var frameSnapshot : UIImage
    private var isInsideProp = false
    private var tooCloseProp = false
    private var tooFarProp = false
    private var ts = Date()
    
    // Properties
    var area : CGRect
    
    // Original Properties
    //var text: String
    //var confidence: VNConfidence
    var labels: [(String, String, distance : Int, confidence : Double)] = []
    var frame : CGRect
    var inclination : Double = 0

    init(bounds: CGRect, image: UIImage, area: CGRect) {
        
        self.frame = bounds
        self.area = CGRect(x: area.minY, y: area.width - area.maxY, width: area.height, height: area.width)
        self.isInsideProp = CGRectContainsRect(area, bounds)
        if(self.isInsideProp){
            //print("Esta dentro")
            //print("Area", area.minX, area.minY)
            //print("Bounds", bounds.minX, bounds.minY)
        }else{
            
        }
        self.frameSnapshot = image
        
        
        if(self.frame.height/area.height>1.10){
            self.tooCloseProp =  true
        }else{
            if(self.frame.height/area.height<0.85){
                self.tooFarProp =  true
            }
        }
        if(self.isInsideProp && !self.tooFarProp && !self.tooCloseProp){
            // If face is valid then store image and crop
            /*guard let pixelBuffer = CMSampleBufferGetImageBuffer(image) else {
                return
            }
            guard let image = UIImage(pixelBuffer: pixelBuffer) else {return}*/
            self.frameSnapshot = image
        }
    }

    public mutating func release() {
        frameSnapshot = UIImage()
    }
    
    private func analyze() {
    }

    func create() -> Date {
        return ts
    }
    
    func isInside() -> Bool{
        return isInsideProp
    }

    func tooFar() -> Bool{
        return tooFarProp
    }
    
    func tooClose() -> Bool{
        return tooCloseProp
    }
        
    func isValid() -> Bool{
        return (self.isInsideProp)
    }
    
    func frameImage() -> UIImage{
        return frameSnapshot
    }
    
    func documentImage() -> UIImage{
        //CGRect(x: area.minY, y: area.width - area.maxY, width: area.height, height: area.width)
        
        //return frameSnapshot.imageRotatedByDegrees(degrees: 90, flip: false).crop(rect: frame)
        //var rotframe = CGRect(x: <#T##Int#>, y: <#T##Int#>, width: frame.height, height: frame.width)
        return frameSnapshot.crop(rect: frame)
    }
    
    func areaImage() -> UIImage{
        //CGRect(x: area.minY, y: area.width - area.maxY, width: area.height, height: area.width)
        
        //return frameSnapshot.imageRotatedByDegrees(degrees: 90, flip: false).crop(rect: frame)
        //var rotframe = CGRect(x: T##Int, y: <#T##Int#>, width: frame.height, height: frame.width)
        return frameSnapshot.crop(rect: area)
    }
}

