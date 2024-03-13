//
//  IdCapture.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 15/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import UIKit
import Device
import AVFoundation

class IdCapture:  SdkComponent, CameraViewControllerDelegate  {
    func updateStatus(status: ComponentStatus) {
        
    }
    
    func getStatus() -> ComponentStatus {
        return ComponentStatus.started
    }
    
    func respond(response: Any,component : SDKComponent) {
        self.idCaptureResponse = (response as? IdCaptureResponse)!
       
    }
    
    // View Controller Reference
    private var requestId: String = ""
    
    private var identifier : String = ""
    private var allow : [IdCaptureFeature] = []
    private var deny : [IdCaptureFeature] = []
    private var order : [IdCaptureFeature] = []

    private var idCaptureResponse: IdCaptureResponse = IdCaptureResponse()
    private var reasonFail: IdCaptureReasonFail?
    private var failMessage: String = ""
    private var error: IdCaptureError?
    private var errorMessage: String = ""
    private var started: Bool = false
    private var position: AVCaptureDevice.Position = .front
    
    
    // Public properties, exposed and customizables
    private var status: ComponentStatus = .created
        private var tasks: [Task] = []
        
      
    var allowCaptureOnFail : Bool = false
   
    
    // Public event listeners
    var onSuccess: ((_: IdCaptureResult, _: UIImage, _: UIImage )->Void)?
    var onFail: ((_: IdCaptureResult, _: IdCaptureReasonFail, _: String )->Void)?
    var onError: ((_: IdCaptureError, _: String)->Void)?
    // Public initialize events
    var onLoad: ((_: String)->Void)?
    var onInitError: ((_: IdCaptureInitError, _: String)->Void)?
    
    // Custom validator
    private var customValidator: ((_: IdCapturePreview)->Void)?
    private func throwResponse(responseType: ResponseEventType){
    }
    
    override init(viewController : UIViewController){
        super.init(viewController: viewController)
        self.identifier = "ComponentCapture"
        self.allowManualSideView = false
        for line in self.configuration!.components{
                    if (line.type == .idCapture) {
                        print("Tasks", line.tasks)
                        tasks = line.tasks
                    }
                }
    }
    
    private func validateParameters(){
        let frontCameras = getListOfCameras(position: .front)
        let backCameras = getListOfCameras(position: .back)
        
        if(sideView == .front){
            position = .front
        }else{
            if(sideView == .frontElseBack){
                if(frontCameras.count > 0){
                    position = .front
                }else{
                    if(backCameras.count > 0){
                        position = .back
                    }else{
                        // error
                    }
                }
            }else{
                if(sideView == .frontOrBack){
                    if(frontCameras.count>0 && backCameras.count>0){
                        allowManualSideView = true
                    }
                    if(frontCameras.count > 0){
                        position = .front
                    }else{
                        if(backCameras.count > 0){
                            position = .back
                        }else{
                            // error
                        }
                    }
                }else{
                    if(sideView == .back){
                        position = .back
                    }else{
                        if(sideView == .backElseFront){
                            if(backCameras.count > 0){
                                position = .back
                            }else{
                                if(frontCameras.count > 0){
                                    position = .front
                                }else{
                                    // error
                                }
                            }
                        }else{
                            if(sideView == .backOrFront){
                                if(frontCameras.count>0 && backCameras.count>0){
                                    allowManualSideView = true
                                }
                                if(backCameras.count > 0){
                                    position = .back
                                }else{
                                    if(frontCameras.count > 0){
                                        position = .front
                                    }else{
                                        // error
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func recoverRequestId() -> String{
        self.requestId = ""
        let defaults = UserDefaults.standard
        let code = (String(describing: self)).snakeCased()!
        if let id = defaults.string(forKey: code + ".request_id") {
            print("recover request id", id)
            self.requestId = id
        }
        return self.requestId
    }
    
    private func saveRequestId(){
        let defaults = UserDefaults.standard
        let code = (String(describing: self)).snakeCased()!
        defaults.setValue(requestId, forKey: code + ".request_id")
        defaults.synchronize()
    }
    
    private func validateRequest(){
        let dInfo = UIDevice.deviceInfo
        let version = ComponentInfo.version.description
        //print("dInfo", dInfo)
        //let _info = ["ios": dInfo]
        let apiRequest = ServiceSdk.validateToken(token: requestId, device: dInfo["id"] as! String, force_request: true, component: "bf", version: version)
        apiRequest.start()
        apiRequest.onSuccess { entity in
            let data:ValidateTokenModel = (entity.content as! ValidateTokenModel)
            print("ValidateTokenModel", data)
            if(data.status.lowercased()=="ok" || data.status.lowercased()=="valid"){
                self.onLoad!(self.requestId)
            }else{
                if(data.message == "accountLocked"){
                    self.onInitError!(.accountLocked, "User account ("  + self.username + ") locked.")
                }else{
                    if(data.message == "userDisabled"){
                        self.onInitError!(.userDisabled, "User account ("  + self.username + ") disabled.")
                    }else{
                        // Falta homologar server y cliente
                        self.onInitError!(.unknown, data.message)
                    }
                }
            }
        }
        apiRequest.onFailure { error in
            if error.httpStatusCode == 401 || error.httpStatusCode == 403 {
                self.onInitError!(.badCredentials, FaceCaptureInitError.badCredentials.description)
            }else{
                self.onInitError!(.invalidStatusCode, String(error.httpStatusCode!))
            }
            print("error", error)
        }
    }
    
    private func authAndCreateRequest(){
        let dInfo = UIDevice.deviceInfo
        let version = ComponentInfo.version.description
        print("dInfo", dInfo)
        let info = ["ios": dInfo]
        let apiRequest = ServiceSdk.createRequest(component : "bf", version: version, device:dInfo["id"] as! String, tag:tags,info:info)
        apiRequest.start()
        apiRequest.onSuccess { entity in
            let data:RequestModel = (entity.content as! RequestModel)
            if(data.status!.lowercased()=="ok" || data.status!.lowercased()=="valid"){
                self.requestId = data.id
                self.saveRequestId()
                self.onLoad!(self.requestId)
                print("data", data)
            }else{
                if(data.message! == "accountLocked"){
                    self.onInitError!(.accountLocked, "User account ("  + self.username + ") locked.")
                }else{
                    if(data.message == "userDisabled"){
                        self.onInitError!(.userDisabled, "User account ("  + self.username + ") disabled.")
                    }else{
                        // Falta homologar server y cliente
                        self.onInitError!(.unknown, data.message!)
                    }
                }
            }
        }
        apiRequest.onFailure { error in
            if error.httpStatusCode == 401 || error.httpStatusCode == 403 {
                self.onInitError!(.badCredentials, IdCaptureInitError.badCredentials.description)
            }else{
                self.onInitError!(.invalidStatusCode, String(error.httpStatusCode!))
            }
            print("error", error)
        }
    }

    //##### Public ####
    
    func initialize(){
        // Use the latest credentials
        ServiceSdk.logIn(username: username, password: password)
        
        validateParameters()
        
        // Create for recover request
        let id = recoverRequestId()
        print("id recovered", id)
        if(id == ""){
            authAndCreateRequest()
        }else{
            validateRequest()
        }
    }
    
    // Initialize credentials
    func credentials(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func policyRules(allow: [IdCaptureFeature], deny: [IdCaptureFeature], order: [IdCaptureFeature]) {
        self.allow = allow
        self.deny = deny
        self.order = order
    }
    
    func start(){
        self.started = true
        (self.viewController).performSegue(withIdentifier: identifier, sender: self.viewController)
    }
    
    func process(){
        if(started && idCaptureResponse.responseEventType != .undefined){
            let result = idCaptureResponse.result
            switch idCaptureResponse.responseEventType{
            case .success:
                print("Exito")
                self.onSuccess!(result,idCaptureResponse.front, idCaptureResponse.back)
            case .fail:
                self.onFail!(result, idCaptureResponse.reasonFail!, idCaptureResponse.failMessage)
            case .error:
                self.onError!(idCaptureResponse.error!, errorMessage)
            case .undefined:
                break
            }
        }
    }
    
    func prepare(segue:UIStoryboardSegue){
        
        var idCaptureOptions = IdCaptureOptions()
                    idCaptureOptions.id = requestId
                    idCaptureOptions.showPreview = showPreview
                    idCaptureOptions.livenessRequired = livenessRequired
                    idCaptureOptions.allow = allow
                    idCaptureOptions.deny = deny
                    idCaptureOptions.order = order
                    idCaptureOptions.maxValidations = maxValidations
                    idCaptureOptions.showIntro = showIntro
                    idCaptureOptions.allowCaptureOnFail = allowCaptureOnFail
                    idCaptureOptions.timeout = timeout
                    idCaptureOptions.level = level
                    idCaptureOptions.aditionalConfigurationParameters = aditionalConfigurationParameters
                    idCaptureOptions.enableVideoHelp = enableVideoHelp
                    idCaptureOptions.enableTroubleshootHelp = enableTroubleshootHelp
                    idCaptureOptions.messagesResource = messagesResource
                    idCaptureOptions.allowManualSideView = allowManualSideView
                    idCaptureOptions.sideView = sideView
                    
                    // telling the compiler what type of VC the sugue.destination is
                    let destinationVC = segue.destination as! ComponentCaptureViewController
                    destinationVC.idCaptureOptions = idCaptureOptions
                    destinationVC.loadTasks(tasks: tasks)
                    destinationVC.requestId = self.requestId
                    destinationVC.sdkComponent = (self as SdkComponent)
                    destinationVC.delegate = self

        
    }
}

struct IdCaptureResponse{
    var front: UIImage =  UIImage()
    var back: UIImage =  UIImage()
    var result = IdCaptureResult()
    var reasonFail: IdCaptureReasonFail?
    var failMessage = ""
    var error: IdCaptureError?
    var errorMessage = ""
    var responseEventType: ResponseEventType = .undefined
}

struct IdCapturePreview{
    var frame: UIImage =  UIImage()
    var document: UIImage = UIImage()
    var area: UIImage =  UIImage()
    var idCaptureResult = IdCaptureResult()
}

struct IdCaptureResult{
    var result:String = "unevaluated"
    var confidence : Double = 0.0
    var retro: [String] = []
}

struct IdCaptureOptions{
    var id: String = ""
    var livenessRequired: Bool = true
    var level: AntispoofingLevel = .medium
    var showPreview: Bool = false
    var showIntro: Bool = true
    var enableVideoHelp: Bool = false
    var enableTroubleshootHelp: Bool =  false
    var timeout : Int = 60
    var maxValidations : Int = 3
    var allowCaptureOnFail : Bool = false
    var sideView : CameraSideView = .front
    var allowManualSideView = false
    var allow: [IdCaptureFeature] = []
    var deny: [IdCaptureFeature] = [.glasses, .facemask]
    var order: [IdCaptureFeature] = []
    var aditionalConfigurationParameters: [ComponentCaptureParameter: Any] = [:]
    
    var messagesResource: String = ""
}

enum IdCaptureParameter{
    case helpVideoUrl,
         troubleshootUrl,
         showTroubleshootAfterFail,
         countInvalidRuleAsFail
}
