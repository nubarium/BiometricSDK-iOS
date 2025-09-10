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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        faceCapture = FaceCapture(viewController: self)

    }

    private var comp = "";

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if comp == "face" {
            faceCapture!.process()
        }
        if comp == "id" {

        }

    }

    
    // In case of Storyboard use
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
        print(area.convertImageToBase64String())
        
        if(result.result == "PASS"){
            //startIdCapture()
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
