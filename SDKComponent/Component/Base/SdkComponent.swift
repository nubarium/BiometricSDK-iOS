//
//  SdkComponent.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 10/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class SdkComponent{
    
    internal var viewController : UIViewController
    internal var configuration: Configuration?
    
    var username: String = ""
    var password: String = ""
    var livenessRequired: Bool = true
    var level: AntispoofingLevel = .medium
    var showPreview: Bool = false
    var showIntro: Bool = true
    var enableVideoHelp: Bool = false
    var enableTroubleshootHelp: Bool = false
    var timeout : Int = 180
    var maxValidations : Int = 3
    
    var aditionalConfigurationParameters : [ComponentCaptureParameter: Any] = [:]
    var tags : [String: String] = [:]
    var messagesResource: String = ""
    var sideView : CameraSideView = .front
    var allowManualSideView: Bool = false
    
    enum ResponseType{
        case success, fail, error
    }
    
    init(viewController : UIViewController){
        self.viewController = viewController
        configuration = loadConfiguration()
    }
    
    internal func loadConfiguration() -> Configuration? {
        if let url = Bundle.main.url(forResource: "Configuration", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(Configuration.self, from: data)
                return jsonData
            } catch {
                print("Errror:\(error)")
            }
        }
        return nil
    }
    
    internal func getListOfCameras(position: AVCaptureDevice.Position) -> [AVCaptureDevice] {
        let cameras = getListOfCameras()
        var list:[AVCaptureDevice] = []
        for camera in cameras{
            if(camera.position == position){
                list.append(camera)
            }
        }
        return list
    }
    
    /// Returns all cameras on the device.
    internal func getListOfCameras() -> [AVCaptureDevice] {
        
#if os(iOS)
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInTelephotoCamera
            ],
            mediaType: .video,
            position: .unspecified)
#elseif os(macOS)
        let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera
            ],
            mediaType: .video,
            position: .unspecified)
#endif
        
        return session.devices
    }
    
    /// Returns all microphones on the device.
    fileprivate func getListOfMicrophones() -> [AVCaptureDevice] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInMicrophone
            ],
            mediaType: .audio,
            position: .unspecified)
        
        return session.devices
    }
    
}

enum AntispoofingLevel{
    case low, medium, high
    
    var description : String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        }
    }
    
    var value : Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
    
}
