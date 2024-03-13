//
//  FaceDetail.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 26/01/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//

import Foundation
import MLKitFaceDetection
import UIKit
import CoreMedia

struct FaceDetail {
    
    private var frameSnapshot : UIImage
    private var isInsideProp = false
    private var tooCloseProp = false
    private var tooFarProp = false
    private var ts = Date()
    
    // Properties
    var area : CGRect
    
    // Original Properties
    var frame : CGRect
    var hasHeadEulerAngleX : Bool
    var headEulerAngleX : CGFloat
    var hasHeadEulerAngleY : Bool
    var headEulerAngleY : CGFloat
    var hasHeadEulerAngleZ : Bool
    var headEulerAngleZ : CGFloat
    var hasSmilingProbability : Bool
    var smilingProbability : CGFloat
    var hasLeftEyeOpenProbability : Bool
    var leftEyeOpenProbability : CGFloat
    var hasRightEyeOpenProbability : Bool
    var rightEyeOpenProbability : CGFloat

    init(face: Face, containerArea: CGRect, snapshot: CMSampleBuffer) {
        self.hasHeadEulerAngleX = face.hasHeadEulerAngleX
        self.headEulerAngleX = face.headEulerAngleX
        self.hasHeadEulerAngleY = face.hasHeadEulerAngleY
        self.headEulerAngleY = face.headEulerAngleY
        self.hasHeadEulerAngleZ = face.hasHeadEulerAngleZ
        self.headEulerAngleZ = face.headEulerAngleZ
        self.hasSmilingProbability = face.hasSmilingProbability
        self.smilingProbability = face.smilingProbability
        self.hasLeftEyeOpenProbability = face.hasLeftEyeOpenProbability
        self.leftEyeOpenProbability = face.leftEyeOpenProbability
        self.hasRightEyeOpenProbability = face.hasRightEyeOpenProbability
        self.rightEyeOpenProbability = face.rightEyeOpenProbability
        self.frame = face.frame

        self.area = containerArea
        self.isInsideProp = CGRectContainsRect(containerArea, face.frame)
        self.frameSnapshot = UIImage()
        
        if(self.frame.height/containerArea.height>0.74){
            self.tooCloseProp =  true
        }else{
            if(self.frame.height/containerArea.height<0.55){
                self.tooFarProp =  true
            }
        }
        if(self.isInsideProp && !self.tooFarProp && !self.tooCloseProp){
            // If face is valid then store image and crop
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(snapshot) else {
                return
            }
            guard let image = UIImage(pixelBuffer: pixelBuffer) else {return}
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
    
    func hasEyesOpen() -> Bool{
        return true
    }

    func pose() -> Pose{
        if self.headEulerAngleY > 19 {
            //print("Volteo a la izquierda  ", self.headEulerAngleY)
            return .left
        }
        else if self.headEulerAngleY < -19 {
            //print("Volteo a la derecha ", self.headEulerAngleY)
            return .right
        }else{
            return .front
        }
    }
    
    func isValid() -> Bool{
        return (self.isInsideProp && !self.tooFarProp && !self.tooCloseProp  && self.pose() == .front )
    }
    
    func frameImage() -> UIImage{
        return frameSnapshot
    }

    func areaImage() -> UIImage{
        return frameSnapshot.crop(rect: area)
    }
    
    func faceImage() -> UIImage{
        return frameSnapshot.crop(rect: frame)
    }
    
}

enum Pose {
    case front, up, down, left, right
}
