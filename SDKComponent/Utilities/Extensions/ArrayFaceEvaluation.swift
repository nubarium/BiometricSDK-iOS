//
//  QueueFaceEvaluationExt.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 26/01/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//

import Foundation

extension Array where Element == Int {
    
    var median: Double {
        let sorted = self.sorted()
        let length = self.count
        
        if (length % 2 == 0) {
            return (Double(sorted[length / 2 - 1]) + Double(sorted[length / 2])) / 2.0
        }
        
        return Double(sorted[length / 2])
    }
}

extension Array where Element == Double {
    
    var median: Double {
        let sorted = self.sorted()
        let length = self.count
        
        if (length % 2 == 0) {
            return (Double(sorted[length / 2 - 1]) + Double(sorted[length / 2])) / 2.0
        }
        
        return Double(sorted[length / 2])
    }
}

extension Array where Element == CGFloat {
    
    var median: CGFloat {
        let sorted = self.sorted()
        let length = self.count
        
        if (length % 2 == 0) {
            return (CGFloat(sorted[length / 2 - 1]) + CGFloat(sorted[length / 2])) / 2.0
        }
        
        return CGFloat(sorted[length / 2])
    }
    
    func sum() -> Element {
        return self.reduce(0, +)
    }
    
    func avg() -> Element {
        return self.sum() / Element(self.count)
    }
    
    func std() -> Element {
        let mean = self.avg()
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / (Element(self.count) - 1))
    }
    
}








