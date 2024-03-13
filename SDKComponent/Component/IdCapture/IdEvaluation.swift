//
//  IdEvaluation.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 17/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation
import MLKitFaceDetection

class IdEvaluation {
    
    // Private properties
    private var bestIdIndex = -1
    //private var maxOpenEyesProbability: CGFloat = 0.0
    private var status:ResultStatus = .wait
    private var idList = IdList()
    private var queueEyesOpen:[CGFloat] = []
        
    func bestFace() -> IdDetail{
        //self.faceList.add(faceDetail)
        let list = self.idList.listWithfaces()
        //print("bestIndex ("+String(list.count)+")", bestIdIndex)
        
        return list[bestIdIndex]
    }
    
    func resultStatus() -> ResultStatus{
        return status
    }
    
    func reset(){
        status = .wait
        //maxOpenEyesProbability = 0.0
        queueEyesOpen = []
        self.idList = IdList()
        self.bestIdIndex = -1
    }
    
    private func getMaxLabelIndex() -> Int{
        //var eyes : [CGFloat] = []
        let lista = idList.listWithfaces()
        //print("listWithfaces count", lista.count)
        return lista.count-1
    }
    
    func addId(id: IdDetail){
        idList.add(id)
        bestIdIndex = getMaxLabelIndex()
    }
    
    func count() -> Int{
        return idList.count()
    }
   
}

