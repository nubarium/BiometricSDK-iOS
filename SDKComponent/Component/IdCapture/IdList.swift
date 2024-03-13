//
//  IdList.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 22/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//
import Foundation

struct IdList {
    private var elements: [IdDetail] = []
    private var elementsId: [IdDetail] = []
    
    func listWithfaces() -> [IdDetail] {
        return elementsId
    }
    
    func all() -> [IdDetail] {
        var out:[IdDetail] = []
        out.append(contentsOf: elementsId)
        out.append(contentsOf: elements)
        return out
    }
    
    mutating func add(_ value: IdDetail) {
        if(elementsId.count < 5){
            elementsId.append(value)
        }else{
            var e: IdDetail = elementsId.removeFirst()
            e.release()
            elements.append(e)
        }
    }
    
    func count() -> Int {
        return (elements.count + elementsId.count)
    }
    
    mutating func clear(){
        elementsId.removeAll()
        elements.removeAll()
    }
    
}
