//
//  HtmlAttributedString.swift
//  MLKit-codelab
//
//  Created by Amilcar Flores on 24/01/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func htmlAttributedString(style: String) -> NSAttributedString? {
        let htmlTemplate = """
        <!doctype html>
        <html>
          <head>
            <style>
              body {
                \(style)
              }
            </style>
          </head>
          <body>
            \(self)
          </body>
        </html>
        """

        guard let data = htmlTemplate.data(using: .utf8) else {
            return nil
        }

        guard let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
            ) else {
            return nil
        }

        return attributedString
    }
}

extension UIColor {
    var hexString:String? {
        if let components = self.cgColor.components {
            let r = components[0]
            let g = components[1]
            let b = components[2]
            return  String(format: "#%02x%02x%02x", (Int)(r * 255), (Int)(g * 255), (Int)(b * 255))
        }
        return nil
    }
}


func makeClearHole(rect: CGRect, sel: UIView) {
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.fillColor = UIColor.black.cgColor
        
        let pathToOverlay = UIBezierPath(rect: sel.bounds)
        pathToOverlay.append(UIBezierPath(rect: rect))
        pathToOverlay.usesEvenOddFillRule = true
        maskLayer.path = pathToOverlay.cgPath
        
        //layer.mask = maskLayer
    }

extension String {
    
    func splitSpace(every: Int, sep: String) -> [String] {
        var result = [String]()
    
        let fullName : String = self
        let words : [String] = fullName.components(separatedBy: " ")
        
        //let words = self.split(separator: sep)
        var line = String(words.first!)

        words.dropFirst().forEach { word in
            let word = " " + String(word)
            if line.count + word.count <= every {
                line.append(word)
            } else {
                result.append(line)
                line = word
            }
        }
        result.append(line)
        return result
    }

    func splitHtml(every: Int, sep: String) -> String {
        var result : String = ""
    
        let fullName : String = self
        let words : [String] = fullName.components(separatedBy: " ")
        
        //let words = self.split(separator: sep)
        var line = String(words.first!)

        words.dropFirst().forEach { word in
            let word = " " + String(word)
            if line.count + word.count <= every {
            
                line.append(word)
            } else {
                result = result + sep + line
                line = word
            }
        }
        result = result + sep + line
        return result
    }


    
}
