//
//  IdDetector.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 17/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation
import Vision
import UIKit


class IdDetector{
    
    private var documentCode = "IDMEX-INEG"
    private var coumentClass = "IDMEX"
    var area : CGRect
    
    init(area: CGRect){
        self.area = area
    }
    
    func identify(data: [(String, VNConfidence, CGRect)], image: UIImage) -> IdDetail? {
        return identifyIne(data: data, image: image)
    }
    
    func process(request : VNRequest, image: UIImage) -> IdDetail? {
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return nil
        }
        let boundingRects: [(String, VNConfidence, CGRect)] = observations.compactMap { observation in

            // Find the top observation.
            guard let candidate = observation.topCandidates(1).first else { return ("",0, CGRect()) }
            
            // Find the bounding-box observation for the string range.
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            
            // Get the normalized CGRect value.
            let boundingBox = boxObservation?.boundingBox ?? .zero
            
            let boundingRects: CGRect = VNImageRectForNormalizedRect(boundingBox,
                                                                     Int(image.size.width),
                                                                     Int(image.size.height))
            
            // Convert the rectangle from normalized coordinates to image coordinates.
            return (candidate.string ,candidate.confidence , boundingRects)
        }
        if( boundingRects.count > 0){
            
            let idDetail : IdDetail? = identify(data: boundingRects, image: image)
            // 3. Display or update UI
            return idDetail
            
        }else{
            return nil
        }
    }
    
    
    func identifyIne(data: [(String, VNConfidence, CGRect)], image: UIImage) -> IdDetail? {
        
        var ine =  Ine()
        for line in data {
            var txt = line.0
            let bounds = line.2
            
            txt = txt.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if ((txt.contains("IDMEX")) && (txt.count >= 28 && txt.count <= 31) ) {
                ine.attemptSide = "BACK";
            }
            if ( txt.distance(from: "INSTITUTO NACIONAL ELECTORAL") <= 5 ) {
                ine.attemptSide = "FRONT";
                ine.P_INE.x = bounds.minX
                ine.P_INE.y = bounds.minY
                ine.isINE = true;
                ine.isIFE = false;
            }
            if ( txt.distance(from: "INSTITUTO FEDERAL ELECTORAL") <= 5 ) {
                ine.attemptSide = "FRONT";
                ine.P_INE.x = bounds.minX
                ine.P_INE.y = bounds.minY
                ine.isINE = false;
                ine.isIFE = true;
            }
            if ((txt.contains("SEX") || (txt.distance(from: "SEXH") <= 2  || txt.distance(from: "SEXM") <= 2) ) && ine.P_SEXO.x == 0) {
                ine.P_SEXO.x = bounds.minX
                ine.P_SEXO.y = bounds.minY
            }
            if (  (txt.contains("EDAD") || (txt.distance( from:"EDAD")<=2  || txt.distance( from:"EDAD")<=2) )   && ine.P_EDAD.x==0) {
                ine.P_EDAD.x = bounds.minX
                ine.P_EDAD.y = bounds.minY
            }
            if (   (txt.contains("NOMBR") || (txt.distance( from:"NOMBRE")<=3  || txt.distance( from:"NOMBRE")<=3)    ) && ine.P_NOMBRE.x == 0) {
                ine.attemptSide = "FRONT";
                ine.P_NOMBRE.x = bounds.minX
                ine.P_NOMBRE.y = bounds.minY
            }
            if (txt.contains("FECHA") || txt.contains("FECH") || txt.contains("NACMENT") || txt.contains("CMENTO")  ) {
                ine.P_FECHA_NACIMIENTO.x = bounds.minX
                ine.P_FECHA_NACIMIENTO.y = bounds.minY
            }
            if (txt.contains("EXTRAN")) {
                ine.isForeign = false
            }
            /*
            if ((txt.contains("NACIONA") || txt.contains("TITUIONAC") ||  txt.contains("TITUTONAC") ||  txt.contains("TUTONAC") ) && !ine.isINE) {
                ine.isINE = true;
                ine.isIFE = false;
            }
            if ((txt.contains("FEDERA") || txt.contains("TITUIOFED") ||  txt.contains("TITUTOFED") ||  txt.contains("TUTOFED") ) && !ine.isINE && !ine.isIFE) {
                ine.isIFE = true;
                ine.isINE = false;
            }*/
            
            if (ine.P_NOMBRE.x > 5 && (ine.P_SEXO.x > 5 || ine.P_FECHA_NACIMIENTO.x > 5)) {
                
                
                if (abs(ine.P_FECHA_NACIMIENTO.y - ine.P_NOMBRE.y) <= 100 && ine.P_FECHA_NACIMIENTO.y>0 && ine.P_NOMBRE.y>0) {
                    ine.isFechaAlignedNombre = true
                }
                if (abs(ine.P_SEXO.y - ine.P_NOMBRE.y) <= 30 && ine.P_SEXO.y>0 && ine.P_NOMBRE.y>0) {
                    ine.isSexoAlignedNombre = true
                }
                if (abs(ine.P_EDAD.y - ine.P_NOMBRE.y) <= 100 && ine.P_EDAD.y>0 && ine.P_NOMBRE.y>0) {
                    ine.isEdadAlignedNombre = true
                }
                
                if(!ine.isFechaAlignedNombre && !ine.isSexoAlignedNombre && !ine.isEdadAlignedNombre){
                    //return
                }
                
            }
            
            if (ine.isINE) {
                if (ine.isFechaAlignedNombre) {
                    ine.family = "EF"
                    if (ine.isForeign) {
                        ine.type = "F"
                    } else {
                        ine.type = "E"
                    }
                } else {
                    if (ine.isSexoAlignedNombre) {
                        ine.family = "HG"
                        if (ine.isForeign) {
                            ine.type = "H"
                        } else {
                            ine.type = "G"
                        }
                    } else {
                        ine.type = ""
                        ine.family = ""
                    }
                }
            } else {
                if (ine.isFechaAlignedNombre) {
                    ine.family = "D";
                    ine.type = "D";
                } else {
                    if (ine.isEdadAlignedNombre) {
                        ine.family = "C";
                        ine.type = "C";
                    } else {
                        ine.type = ""
                        ine.family = ""
                    }
                }
            }
            /*if (ine.type == "") {
                ine.isINE = false;
                ine.isIFE = false;
                ine.isForeign = false;
                //return;
            }*/
            
            var ORIGINAL_NOMBRE_X = 340, ORIGINAL_NOMBRE_Y = 180
            var ORIGINAL_WIDTH = 1000, ORIGINAL_HEIGHT = 630
            
            var ORIGINAL_REFERENCE_X = 880, ORIGINAL_REFERENCE_Y = 180
            
            var P_REF : CGPoint = ine.P_SEXO
            if (ine.family == "EF") {
                ORIGINAL_NOMBRE_X = 324
                ORIGINAL_NOMBRE_Y = 164
                
                ORIGINAL_REFERENCE_X = 784
                ORIGINAL_REFERENCE_Y = 167
                P_REF = ine.P_FECHA_NACIMIENTO
            }
            if (ine.family == "D") {
                ORIGINAL_NOMBRE_X = 312
                ORIGINAL_NOMBRE_Y = 164
                
                ORIGINAL_REFERENCE_X = 773
                ORIGINAL_REFERENCE_Y = 168
                P_REF = ine.P_FECHA_NACIMIENTO
            }
            if (ine.family == "C") {
                ORIGINAL_NOMBRE_X = 57
                ORIGINAL_NOMBRE_Y = 181
                
                ORIGINAL_REFERENCE_X = 551
                ORIGINAL_REFERENCE_Y = 210
                P_REF = ine.P_EDAD
            }
            let ratiowidthSexNombre = CGFloat(ORIGINAL_REFERENCE_X - ORIGINAL_NOMBRE_X) / CGFloat(ORIGINAL_WIDTH)
            let heightRatio = CGFloat( ORIGINAL_NOMBRE_Y) / CGFloat(ORIGINAL_HEIGHT)
            ine.WIDTH_SEX_NOMBRE = Int(P_REF.x - ine.P_NOMBRE.x);
            ine.WIDTH_ID = Int( CGFloat( ine.WIDTH_SEX_NOMBRE) / ratiowidthSexNombre);
            ine.HEIGHT_ID = Int( CGFloat(ORIGINAL_HEIGHT) / CGFloat((ORIGINAL_WIDTH)) * CGFloat(ine.WIDTH_ID) )
            
            ine.P_ID.x = CGFloat( Int((ine.P_NOMBRE.x - (  CGFloat(ine.WIDTH_ID) *  ( CGFloat(ORIGINAL_NOMBRE_X) / 1000.0)))))
            ine.P_ID.y = CGFloat(Int( ine.P_NOMBRE.y - (  CGFloat(ine.HEIGHT_ID) * heightRatio ) ))
            ine.bounds = CGRect(x: Int(ine.P_ID.x), y: Int(ine.P_ID.y), width: Int(ine.WIDTH_ID), height: Int(ine.HEIGHT_ID))
        }
        if(ine.bounds != nil){
            let fr = ine.bounds!
            let idDetail =  IdDetail(bounds: fr, image: image, area: self.area)
            //idDetail.isInside()
            if( idDetail.isInside() ){
                if(idDetail.isValid()){
                    print("Esta dentro")
                    print(fr.minX, fr.minY, fr.width, fr.height)
                    return idDetail
                }else{
                    print("No Es Valido")
                }
            }else{
                print("Esta fuera")
            }
        }
        return nil
    }
 
    
    struct Ine{
        var P_SEXO = CGPoint()
        var P_EDAD = CGPoint()
        var P_NOMBRE = CGPoint()
        var P_FECHA_NACIMIENTO = CGPoint()
        var P_ID = CGPoint()
        var WIDTH_ID = 0, HEIGHT_ID = 0;
        var WIDTH_SEX_NOMBRE = 0;
        
        var P_INE = CGPoint();
        var P_IDMEX = CGPoint();
        var P_MEX = CGPoint();
        
        var P_LARGE = CGRect();
        
        var family = "", type = ""
        
        var attemptSide = ""
        var isForeign = false, isINE = false, isIFE = false
        var isFechaAlignedNombre = false, isSexoAlignedNombre = false, isEdadAlignedNombre = false
        
        var bounds : CGRect?
    }
    
}
