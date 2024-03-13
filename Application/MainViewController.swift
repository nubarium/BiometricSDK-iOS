//
//  MainViewController.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 03/02/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class MainViewController: UIViewController {
    
    private var faceCapture:FaceCapture?
    private var idCapture:IdCapture?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        faceCapture = FaceCapture(viewController: self)
        idCapture = IdCapture(viewController: self)
    }

    private var comp = "";

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if comp == "face" {
            faceCapture!.process()
        }
        if comp == "id" {
            idCapture!.process()
        }

    }

    
    // In case of Storyboard use
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
          if comp == "id" {
              idCapture!.prepare(segue: segue)
          }
          if comp == "face" {
              faceCapture!.prepare(segue: segue)
          }
      }


    @IBAction func startFaceCapture(_ sender: Any) {
        
        // Configure properties
        faceCapture!.credentials(username: "amilcar.flores",password: "elpass")
        faceCapture!.livenessRequired = true
        //faceCapture!.level = .medium
        faceCapture!.showPreview = true
        faceCapture!.showIntro = true
        faceCapture!.enableVideoHelp = true
        faceCapture!.enableTroubleshootHelp = true
        
        faceCapture!.timeout = 999
        faceCapture!.maxValidations = 4
        faceCapture!.allowCaptureOnFail = false
            // faceCapture!.policyRules(allow:[], deny:[.glasses, .facemask], order:[])
        faceCapture!.policyRules(allow:[.glasses], deny:[ .facemask], order:[])

        faceCapture!.aditionalConfigurationParameters = [.helpVideoUrl:"",.troubleshootUrl:"", .showTroubleshootAfterFail:true, .countInvalidRuleAsFail: false ]
        faceCapture!.sideView = .front
        
        // Configure response event listeners
        faceCapture!.onLoad = onLoadFaceCapture
        faceCapture!.onInitError = onInitError
        
        // Configure response event listeners
        faceCapture!.onSuccess = onSuccess
        faceCapture!.onFail = onFail
        faceCapture!.onError = onError
        
        faceCapture!.messagesResource = "CustomFaceCapture"
        // Initialize component
        faceCapture!.initialize()
        comp = "face"
        
    }
    
    
    @IBAction func startIdCapture() {
        
        // Configure properties
                idCapture!.credentials(username: "amilcar.flores",password: "elpass")
                //idCapture!.livenessRequired = true
                //idCapture!.level = .medium
                idCapture!.showPreview = true
                idCapture!.showIntro = false
                idCapture!.enableVideoHelp = false
                idCapture!.enableTroubleshootHelp = false

                idCapture!.timeout = 180
                idCapture!.maxValidations = 4
                idCapture!.allowCaptureOnFail = true
                idCapture!.policyRules(allow:[], deny:[], order:[])
                idCapture!.aditionalConfigurationParameters = [.helpVideoUrl:"",.troubleshootUrl:"", .showTroubleshootAfterFail:true, .countInvalidRuleAsFail: false ]
                idCapture!.sideView = .back
                
                
                // Configure response event listeners
                idCapture!.onLoad = onLoadIdCapture
                idCapture!.onInitError = onInitError
                
                // Configure response event listeners
                idCapture!.onSuccess = onSuccess
                idCapture!.onFail = onFail
                idCapture!.onError = onError
                
                //idCapture!.messagesResource = "CustomIdCapture"
                // Initialize component
                idCapture!.initialize()
                comp = "id"
        
    }
    
    
    @IBAction func startVideoRecord(_ sender: Any) {
    }
    
    func onLoadFaceCapture(id: String){
        print("Initilized with ID " + id)
        // Start and show ViewController component
        faceCapture!.start()
    }

    func onLoadIdCapture(id: String){
        print("Initilized with ID " + id)
        // Start and show ViewController component
        idCapture!.start()

    }
    
    func onInitError(error: FaceCaptureInitError, msg: String){
        print("Init Error ->" ,error)
    }
    
    func onSuccess(result : FaceCaptureResult,face: UIImage, area: UIImage, frame: UIImage){
        print("OnSuccess output")
        print("Confidence", result.confidence)
        print("Result", result.result)
        print("width", area.size.width)
        print("height", area.size.height)
        
        if(result.result == "PASS"){
            startIdCapture()
        }
        //print("Size",area.size.width, faceCaptureResponse.area.size.height)
    }
    
    func onFail(result : FaceCaptureResult, faceCaptureReasonFail: FaceCaptureReasonFail, reason: String){
        print("OnFail")
        print("Confidence", result.confidence)
        print("Result", result.result)
        print("Fail", faceCaptureReasonFail)
        print("Reason", reason)
    }
    
    func onError(faceCaptureReasonError: FaceCaptureReasonError, message: String){
        print("OnError")
        print("Error", faceCaptureReasonError)
        print("Message", message)
    }
    
    /* IdCapture Event Listeners */
        func onInitError(error: IdCaptureInitError, msg: String){
            print("Init Error ->" ,error)
        }
        
        func onSuccess(result : IdCaptureResult,front: UIImage, back: UIImage){
            print("OnSuccess output")
            print("Confidence", result.confidence)
            print("Result", result.result)
            //print("width", area.size.width)
            //print("height", area.size.height)
            //print("Size",area.size.width, faceCaptureResponse.area.size.height)
        }
        
        func onFail(result : IdCaptureResult, idCaptureReasonFail: IdCaptureReasonFail, reason: String){
            print("OnFail")
            print("Confidence", result.confidence)
            print("Result", result.result)
            print("Fail", idCaptureReasonFail)
            print("Reason", reason)
        }
        
        
        func onError(idCaptureError: IdCaptureError, message: String){
            print("OnError")
            print("Error", idCaptureError)
            print("Message", message)
        }
    
    // SwiftUI Pendent
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
