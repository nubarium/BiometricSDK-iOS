//
//  FaceDetector.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 24/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation
import Vision
import UIKit
import MLKitFaceDetection
import MLKitVision

class FaceProcessor{
    
    let faceDetectorOptions = FaceDetectorOptions()
    var faceDetector = FaceDetector.faceDetector()
    
    var area : CGRect
    
    init(area: CGRect){
        self.area = area
        faceDetectorOptions.landmarkMode = .none
        faceDetectorOptions.classificationMode = .all
        faceDetectorOptions.performanceMode = .fast
        faceDetectorOptions.contourMode = .none
        //options.minFaceSize
        faceDetectorOptions.minFaceSize = CGFloat(0.45)
        // [END config_face]
        faceDetector = FaceDetector.faceDetector(options: faceDetectorOptions)
    }
        
    func processAsync(sampleBuffer: CMSampleBuffer?, _ function: @escaping ( [FaceDetail], CMSampleBuffer, Error? ) -> Void ) {
        //guard let image = image else { return }
        let visionImage = VisionImage(buffer: sampleBuffer!)
        visionImage.orientation = .up
        // [START detect_faces]
        weak var weakSelf = self
        faceDetector.process(visionImage) { faces, error in
            guard weakSelf != nil else {
                return
            }
            if(error == nil){
                var ret : [FaceDetail] = []
                // Faces detected
                //print("xx")
                faces!.forEach { face in
                    let faceDetail = FaceDetail(face: face, containerArea: self.area, snapshot: sampleBuffer!)
                    ret.append(faceDetail)
                }
                function(ret, sampleBuffer!, nil)
            }else{
                function([], sampleBuffer!,  error)
            }
        }
    }
    
    
}

