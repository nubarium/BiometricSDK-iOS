//
//  FaceEvaluation.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 26/01/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//

import Foundation
import MLKitFaceDetection

class FaceEvaluation {
    
    // Private properties
    private var bestFaceIndex = -1
    private var maxOpenEyesProbability: CGFloat = 0.0
    private var status:ResultStatus = .wait
    private var faceList = FaceList()
    private var queueEyesOpen:[CGFloat] = []
        
    func bestFace() -> FaceDetail{
        //self.faceList.add(faceDetail)
        let list = self.faceList.listWithfaces()
        print("bestIndex ("+String(list.count)+")", bestFaceIndex)
        
        return list[bestFaceIndex]   //queue.getAll()[bestFaceIndex]
    }
    
    func resultStatus() -> ResultStatus{
        return status
    }
    
    func reset(){
        status = .wait
        maxOpenEyesProbability = 0.0
        queueEyesOpen = []
        self.faceList = FaceList()
        self.bestFaceIndex = -1
    }
    
    private func getMaxEyesOpenIndex() -> Int{
        var eyes : [CGFloat] = []
        let lista = faceList.listWithfaces()
        //print("listWithfaces count", lista.count)
        let l = (lista.count-1)
        for i in 0...l {
            let probability = (lista[i].leftEyeOpenProbability + lista[i].rightEyeOpenProbability)/2.0
            eyes.append(probability)
        }
        let m = eyes.count - 1
        let maxProb: CGFloat = 0.0
        var max = 0
        for i in 0...m {
            let eye = eyes[i]
            if(eye > maxProb){
                max = i
            }
        }
        return max
    }
    
    func addFace(face: FaceDetail){
        faceList.add(face)
        bestFaceIndex = getMaxEyesOpenIndex()
    }
    
    func count() -> Int{
        return faceList.count()
    }
   
    func isBlinking() -> Bool{
        let elements: [FaceDetail] = faceList.all()
        var bestProbablity: CGFloat = 0
        var elementsEyeLeft: [CGFloat] = []
        var elementsEyeRight: [CGFloat] = []
        var elementsEulerZ: [CGFloat] = []
        
        var i = -1
        //self.bestFaceIndex = 0
        elements.forEach{ e in
            i = i + 1
            if(e.hasHeadEulerAngleZ){
                elementsEulerZ.append(e.headEulerAngleZ)
            }
            if (e.hasLeftEyeOpenProbability) {
                if(e.leftEyeOpenProbability > bestProbablity){
                    //self.bestFaceIndex = i
                    bestProbablity = e.leftEyeOpenProbability
                }
                elementsEyeLeft.append(e.leftEyeOpenProbability)
                
            }
            if (e.hasRightEyeOpenProbability) {
                elementsEyeRight.append(e.rightEyeOpenProbability)
            }
            print("Left: ",e.leftEyeOpenProbability, "Right", e.rightEyeOpenProbability)
        }
        
        var medianLeftEye: CGFloat = 0, medianRightEye: CGFloat = 0
        if(elementsEyeLeft.count>5){
            medianLeftEye = elementsEyeLeft.median
        }
        if(elementsEyeRight.count>5){
            medianRightEye = elementsEyeRight.median
        }
        
        let avg = elementsEyeLeft.avg()
        let devstdLeft = elementsEyeLeft.std()
        let devstdRight = elementsEyeRight.std()
        let devstdZ = elementsEulerZ.std()
        
        print("medianLeftEye", medianLeftEye)
        print("medianRightEye", medianRightEye)
        print("avg", avg)
        print("devstdRight", devstdRight)
        print("devstdLeft", devstdLeft)
        print("devstdZ", devstdZ)
        
        if( (devstdRight < 0.12 && devstdLeft < 0.12) || (devstdRight < 0.12 && devstdLeft < 0.12) ) {
            return false
        }
        return true
    }
    
}

enum ResultStatus{
    case pass, fail, warning, wait
}
