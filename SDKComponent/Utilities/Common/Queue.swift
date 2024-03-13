//
//  Queue.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 26/01/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//

import Foundation

struct Queue<T> {
    private var elements: [T] = []
    var maxSize : Int = -1
    
    init() {
        
    }
    
    init(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    func all() -> [T] {
        return elements
    }
    
    mutating func enqueue(_ value: T) {
        if(maxSize>0){
            if(elements.count < maxSize){
                elements.append(value)
            }else{
                elements.removeFirst()
                elements.append(value)
            }
        }else{
            elements.append(value)
        }
    }
    
    mutating func enqueue(_ value: [T]) {
        elements.append(contentsOf: value)
    }
    
    mutating func dequeue() -> T? {
        guard !elements.isEmpty else {
            return nil
        }
        return elements.removeFirst()
    }
    
    var head: T? {
        return elements.first
    }
    
    var tail: T? {
        return elements.last
    }
    
    mutating func clear(){
        elements.removeAll()
    }
    
    var isEmpty: Bool{
        return elements.isEmpty
    }
    
}
