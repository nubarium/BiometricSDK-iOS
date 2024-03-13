//
//  TasksCommon.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 13/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation
import UIKit

enum TaskStatus {
    case notStarted, started, inProgress, completed, cancelled
}

enum Orientation: Decodable, Equatable  {
    case portrait, landscape
    case unknown(value: String)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try? container.decode(String.self)
        switch status {
            case "Portrait": self = .portrait
            case "Landscape": self = .landscape
            default:
                self = .unknown(value: status ?? "unknown")
        }
    }
}

enum ShapeType: Decodable, Equatable  {
    case rectangle, roundedRectangle, oval
    case unknown(value: String)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try? container.decode(String.self)
        switch status {
            case "Rectangle": self = .rectangle
            case "RoundedRectangle": self = .roundedRectangle
            case "Oval": self = .oval
            default:
                self = .unknown(value: status ?? "unknown")
        }
    }
}

enum SDKComponent: Decodable, Equatable {
    case faceCapture, idCapture, documentCapture, videoRecorder
    case unknown(value: String)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try? container.decode(String.self)
        switch status {
            case "FaceCapture": self = .faceCapture
            case "IdCapture": self = .idCapture
            case "DocumentCapture": self = .documentCapture
            case "VideoRecorder": self = .videoRecorder
            default:
                self = .unknown(value: status ?? "unknown")
        }
    }
}

enum TaskType: Decodable, Equatable  {
    case faceCapture, idCapture, documentCapture, signatureCapture, transcribeAudio
    case unknown(value: String)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try? container.decode(String.self)
        switch status {
            case "FaceCapture": self = .faceCapture
            case "IdCapture": self = .idCapture
            case "DocumentCapture": self = .documentCapture
            case "SignatureCapture": self = .signatureCapture
            case "TranscribeAudio": self = .transcribeAudio
            default:
                self = .unknown(value: status ?? "unknown")
        }
    }
}

enum MaskFill: Decodable, Equatable  {
    case defaultBackground, transparent, transparency
    case unknown(value: String)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try? container.decode(String.self)
        switch status {
            case "DefaultBackground": self = .defaultBackground
            case "Transparent": self = .transparent
            case "Transparency": self = .transparency
            default:
                self = .unknown(value: status ?? "unknown")
        }
    }
}

struct Configuration : Decodable{
    var version : String
    var components: [Components]
}

struct Components : Decodable{
    var type: SDKComponent?
    var tasks : [Task]
}

struct Task : Decodable {
    var name : String
    var area :  AreaConfiguration
    var orientation: Orientation?
    var shape: ShapeType?
    var type: TaskType?
    var timeout: Int
    var messages: [Message]
}

/*
"id":"keep":
    "msg": ".nbm_facial_msg_keep",
    "textColor": ".modeTextColor",
    "borderColor"*/

struct Message: Decodable {
    var id : String
    var msg : String
    var textColor : String?
    var borderColor : String?
}

struct AreaConfiguration : Decodable {
    var show: Bool
    var ratio: Double?
    var maskFill: MaskFill?
    var fillColor: String?
}



struct TaskConfiguration2 {
    
    private var prName : String?
    private var prComponentType: SDKComponent?
    private var prRatioCaptureArea: Double = 0
    private var prCompOrientation: UIInterfaceOrientation = .portrait
    private var prShapeType: ShapeType?
    private var prType: TaskType?
    private var prMaskFill: MaskFill?
    
    var name : String {
        prName!
    }
   
    var maskFill : MaskFill {
        prMaskFill!
    }
    
    var shapeType : ShapeType {
        prShapeType!
    }
    
    var orientation: UIInterfaceOrientation {
        prCompOrientation
    }
    
    var ratioArea : Double {
        prRatioCaptureArea
    }
    
    mutating func load(type: TaskType?, componentType: SDKComponent){
        switch(type){
        case .faceCapture:
            prRatioCaptureArea = 100/63  //4/3
            prCompOrientation = .portrait
            prShapeType = .rectangle
            
            
            if(componentType == .faceCapture){
                prMaskFill = .defaultBackground
            }
            if(componentType == SDKComponent.videoRecorder){
                prMaskFill = .transparency
            }
            
        case .idCapture:
            prRatioCaptureArea = 5/3
            prCompOrientation = .landscapeLeft
            prShapeType = .rectangle
            if(componentType == .idCapture){
                prMaskFill = .defaultBackground
            }
            if(componentType == .videoRecorder){
                prMaskFill = .transparency
            }
            
        case .documentCapture:
            prRatioCaptureArea = 5/3
            prCompOrientation = .landscapeLeft
            prShapeType = .rectangle
            if(componentType == .documentCapture){
                prMaskFill = .defaultBackground
            }
            if(componentType == .videoRecorder){
                prMaskFill = .transparency
            }
        case .transcribeAudio:
            prRatioCaptureArea = 5/3
            prCompOrientation = .landscapeLeft
            prShapeType = .rectangle
            if(componentType == .idCapture){
                prMaskFill = .defaultBackground
            }
            if(componentType == .videoRecorder){
                prMaskFill = .transparency
            }
        case .signatureCapture:
            prRatioCaptureArea = 5/3
            prCompOrientation = .landscapeLeft
            prShapeType = .rectangle
            if(componentType == .idCapture){
                prMaskFill = .defaultBackground
            }
            if(componentType == .videoRecorder){
                prMaskFill = .transparency
            }
        case .none:
            break
        case .some(.unknown(value: _)):
            break;
       
        }
    }
    // Validation
}




struct ComponentHelper{
    
    private var compDimension: Dimension?
    private var ratioCaptureArea: Double? = 0
    private var compOrientation: UIInterfaceOrientation? = .portrait
    private var shapeType: ShapeType?
    private var type : SDKComponent?
    
    init(type: SDKComponent){
        if(type == .faceCapture){
            ratioCaptureArea = 100/63 //4/3
            compOrientation = .portrait
            shapeType = .oval
            self.type = type
            //dimension =
        }
        if(type == .idCapture){
            ratioCaptureArea = 4/3
            compOrientation = .portrait
            shapeType = .oval
            self.type = type
            //dimension =
        }
    }
    
    /*func tasks() -> [Task]{
        
        if(type == .faceCapture){
            var taskConf = TaskConfiguration()
            taskConf.load(type: TaskType.faceCapture, componentType: .faceCapture)
            return [taskConf]
        }
        if(type == .idCapture){
            var taskConf = TaskConfiguration()
            taskConf.load(type: TaskType.idCapture, componentType: .idCapture)
            return [taskConf]
        }
        return []
    }*/
    
    func loadConfigurations(){
        
    }
    
    /*func dimension(resolution: CGSize) -> Dimension{
        return Dimension(resolution: resolution , ratioCaptureArea: ratioCaptureArea, orientation: orientation, shapeType: shapeType!)
    }
    
    var orientation: UIInterfaceOrientation {
      compOrientation
    }*/
    
}


struct Dimension{
    
    private let screenSize: CGRect = UIScreen.main.bounds
    private var screenWidth: CGFloat?
    private var screenHeight: CGFloat?
    
    var width: CGFloat?
    var height: CGFloat?
    
    private var ratioScreen : CGFloat?
    private var offsetY: CGFloat?
    
    private var captureArea: CGRect?
    private var captureAreaResolution: CGRect?
    private var captureAreaWithBorder: CGRect?
    private var frameMask: CGRect?
    
    private var ratioCaptureArea: CGFloat = 0.0
    
    private var messageFrame : CGRect?
    private var messagePosition : CGPoint?
    
    private var orientation : Orientation?
    var shapeType: ShapeType?
    var shapeRadius = 0

    init(conf: Task){
        self.ratioCaptureArea = conf.area.ratio!
        self.shapeType = conf.shape!
        self.orientation = conf.orientation!
    }
    
    mutating func load(resolution: CGSize){
        
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        if(shapeType == ShapeType.rectangle){
            self.shapeRadius = 25
        }
        
        //self.ratioCaptureArea = ratioCaptureArea
        
        // Calculate ratio between resolution width and screen width
        ratioScreen = CGFloat(resolution.width) / screenWidth!
        
        let screenHeightCropped = CGFloat(resolution.height) / ratioScreen!
        
        // Calculate the vertical offset
        offsetY = (screenHeight! - screenHeightCropped)/2
        //print("offsetY", offsetY)
        frameMask = CGRect(x: 0, y: 0, width: Int(screenWidth!), height: Int(screenHeightCropped))
        //print("screenWidth", screenWidth)
        //print("screenHeightCropped", screenHeightCropped)
        
        // Calculate capture area
        var areaWidth:CGFloat = CGFloat(screenWidth!) * 0.68
        var areaHeight:CGFloat =  areaWidth * ratioCaptureArea
        // Calculate the area origin coordinates abolsute, consider offset to the relative area
        let x: CGFloat = CGFloat( Int((screenWidth! -  areaWidth)/2) )
        let y: CGFloat = CGFloat ( Int((screenHeight! - areaHeight)/3) )
        
        //frameAreaOnImage
        if(orientation == .landscape){
        //    areaHeight = CGFloat(screenHeight!) * 0.68
        //    areaWidth =  areaHeight * ratioCaptureArea
        }
        /*print("orientation", orientation)
        print("areaHeight", areaHeight)
        print("areaWidth", areaWidth)

        print("screenWidth", screenWidth)
        print("screenHeight", screenHeight)*/
        //print("conj", areaWidth, areaHeight, ratioCaptureArea)
        

        let offset:  CGFloat  = (CGFloat(areaWidth)*ratioScreen!)*0.15
        // Calculate the area rect
        captureArea = CGRect(x: x, y: y, width: areaWidth, height: areaHeight)
        captureAreaResolution = CGRect(
            x: x*ratioScreen!-offset/2.0,
            y: y*ratioScreen!-offset/2.0 + offsetY!,
            width: areaWidth*ratioScreen! + offset,
            height: areaHeight*ratioScreen! + offset)
        
        let lineWidth: CGFloat = 4.0
        captureAreaWithBorder = CGRect(x: x - lineWidth, y: y + offsetY! - lineWidth, width: areaWidth +  2 * lineWidth, height: areaHeight + (2 * lineWidth))
        
        let textWidth = Int(screenWidth! / 1.17)
        
        messageFrame = CGRect(x: 0, y: 0, width: textWidth, height: Int( Double(y) * Double(0.7)  ))
        messagePosition = CGPoint(x: (screenWidth! / 2), y: Double(Int(y)/2) + offsetY!)
    }
    
    init(resolution: CGSize, ratioCaptureArea : Double, orientation: Orientation, shapeType: ShapeType){
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        self.orientation = orientation
        self.shapeType = shapeType
        
        if(shapeType == ShapeType.rectangle){
            self.shapeRadius = 25
        }
        
        self.ratioCaptureArea = ratioCaptureArea
        
        // Calculate ratio between resolution width and screen width
        ratioScreen = CGFloat(resolution.width) / screenWidth!
        
        let screenHeightCropped = CGFloat(resolution.height) / ratioScreen!
        
        // Calculate the vertical offset
        offsetY = (screenHeight! - screenHeightCropped)/2
        
        frameMask = CGRect(x: 0, y: 0, width: Int(screenWidth!), height: Int(screenHeightCropped))
        
        // Calculate capture area
        var areaWidth:CGFloat = CGFloat(screenWidth!) * 0.68
        var areaHeight:CGFloat =  areaWidth * ratioCaptureArea
        
        if(orientation == .landscape){
            areaHeight = CGFloat(screenHeight!) * 0.68
            areaWidth =  areaHeight * ratioCaptureArea
        }
        // Calculate the area origin coordinates abolsute, consider offset to the relative area
        let x: CGFloat = CGFloat( Int((screenWidth! -  areaWidth)/2) )
        let y: CGFloat = CGFloat ( Int((screenHeight! - areaHeight)/3) )
        
        let offset:  CGFloat  = (CGFloat(areaWidth)*ratioScreen!)*0.15
        // Calculate the area rect
        captureArea = CGRect(x: x, y: y, width: areaWidth, height: areaHeight)
        captureAreaResolution = CGRect(
            x: x*ratioScreen!-offset/2.0,
            y: y*ratioScreen!-offset/2.0 + offsetY!,
            width: areaWidth*ratioScreen! + offset,
            height: areaHeight*ratioScreen! + offset)
        
        let lineWidth: CGFloat = 4.0
        captureAreaWithBorder = CGRect(x: x - lineWidth, y: y + offsetY! - lineWidth, width: areaWidth +  2 * lineWidth, height: areaHeight + (2 * lineWidth))
        
        let textWidth = Int(screenWidth! / 1.17)
        
        messageFrame = CGRect(x: 0, y: 0, width: textWidth, height: Int( Double(y) * Double(0.7)  ))
        messagePosition = CGPoint(x: (screenWidth! / 2), y: Double(Int(y)/2) + offsetY!)

    }
    
    func frameAreaOnScreen() -> CGRect {
        return captureArea!
    }

    func frameAreaOnScreenRelative() -> CGRect {
        return captureAreaWithBorder!
    }
    
    func frameAreaOnImage() -> CGRect {
        return captureAreaResolution!
    }
    
    func frameMaskCamera() -> CGRect {
        return frameMask!
    }
    
    func positionMaskCamera() -> CGPoint{
        return CGPoint(x: screenWidth!/2, y: screenHeight!/2)
    }
    
    func frameMessage() -> CGRect {
        return messageFrame!
    }
    
    func positionMessage() -> CGPoint{
        return messagePosition!
    }
    
}
