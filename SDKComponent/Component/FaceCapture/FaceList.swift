//
//  FaceList.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 05/02/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//
import Foundation

struct FaceList {
    private var elements: [FaceDetail] = []
    private var elementsFace: [FaceDetail] = []
    
    func listWithfaces() -> [FaceDetail] {
        return elementsFace
    }
    
    func all() -> [FaceDetail] {
        var out:[FaceDetail] = []
        out.append(contentsOf: elementsFace)
        out.append(contentsOf: elements)
        return out
    }
    
    mutating func add(_ value: FaceDetail) {
        if(elementsFace.count < 5){
            elementsFace.append(value)
        }else{
            var e: FaceDetail = elementsFace.removeFirst()
            e.release()
            elements.append(e)
            //elementsFace.append(value)
        }
    }
    
    func count() -> Int {
        return (elements.count + elementsFace.count)
    }
    
    mutating func clear(){
        elementsFace.removeAll()
        elements.removeAll()
    }
    
}
