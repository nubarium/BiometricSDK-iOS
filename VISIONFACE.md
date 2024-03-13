#  <#Title#>

    
    
    func detectNewFace(sampleBuffer: CMSampleBuffer){
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let image = UIImage(pixelBuffer: pixelBuffer!)
        //print(image?.size.width  , image?.size.height )
        //var sequenceHandler = VNSequenceRequestHandler()
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer!, orientation: .up )
        let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFace)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([detectFaceRequest])
            } catch {
                print(error)
            }
        }
    }
    
    func detectedFace(request: VNRequest, error: Error?) {
      // 1
      guard
        let results = request.results as? [VNFaceObservation],
        let result = results.first
        else {
          // 2
          //faceView.clear()
          return
      }
        
      // 3
      let box = result.boundingBox
      //faceView.boundingBox = convert(rect: box)
        
      // 4
      DispatchQueue.main.async {
          let boundingRects: CGRect = VNImageRectForNormalizedRect(box,720, 1280)
                                                                  /* Int(image.size.width),
                                                                   Int(image.size.height))*/
          
          print("Cara", boundingRects.minX, boundingRects.minY, boundingRects.width)
        //self.faceView.setNeedsDisplay()
      }
    }
    
    
    
    
    
    
    
    
    /*  OLD WAY  */


    
    
    func detectFaces(sampleBuffer: CMSampleBuffer?) {
        //guard let image = image else { return }
        let visionImage = VisionImage(buffer: sampleBuffer!)
        visionImage.orientation = .up
        // [START detect_faces]
        weak var weakSelf = self
        faceDetector.process(visionImage) { faces, error in
            guard weakSelf != nil else {
                return
            }
            guard error == nil, let faces = faces, !faces.isEmpty else {
                // [START_EXCLUDE]
                let _ = error?.localizedDescription ?? "No results returned."
                if(self.hasExpired){
                    self.isFinished = true
                    
                    self.updateMessage(code: "expired")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        var retro: [String] = []
                        if(self.counterStaticEye > 0){
                            retro = ["static_eye"]
                        }
                        self.processFailFace(retro: retro, faceCaptureReasonFail: .timeout, score: 0.0)
                    }
                }else{
                    //self.updateMessageFace(code: .noFace)
                    self.updateMessage(code: "noFace")
                    self.resetEvaluation()
                }
                // [END_EXCLUDE]
                return
            }
            
            
        }
        // [END detect_faces]
    }





    
    func parseFace(faces: [Face], image: CMSampleBuffer){
        if faces.count == 0 {
            if(self.hasExpired){
                self.isFinished = true
                //self.updateMessageFace(code: .expired)
                self.updateMessage(code: "expired")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    var retro: [String] = []
                    if(self.counterStaticEye > 0){
                        retro = ["static_eye"]
                    }
                    self.processFailFace(retro: retro, faceCaptureReasonFail: .timeout, score: 0.0)
                }
            }else{
                //self.updateMessageFace(code: .noFace)
                self.updateMessage(code: "noFace")
                self.resetEvaluation()
            }
            return
        }
        if faces.count > 2 {
            if(self.hasExpired){
                self.isFinished = true
                //self.updateMessageFace(code: .expired)
                self.updateMessage(code: "expired")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    var retro: [String] = ["many_faces"]
                    if(self.counterStaticEye > 0){
                        retro.append("static_eye")
                    }
                    self.processFailFace(retro: retro, faceCaptureReasonFail: .timeout, score: 0.0)
                }
            }else{
                //self.updateMessageFace(code: .manyFaces )
                self.updateMessage(code: "manyFaces")
                self.resetEvaluation()
            }
            return
        }
        // Faces detected
        faces.forEach { face in
            let faceDetail = FaceDetail(face: face, containerArea: self.areaRectScale, snapshot: image)
            if(faceDetail.isValid()){
                if(faceDetail.isInside()){
                    if(self.faceEvaluation.count()==10 && self.statusFaceCheckFeatures == .notStarted ){ // self.flagCheckFeatures == false
                        print("Check Features Thread")
                        self.bestFace = self.faceEvaluation.bestFace()
                        self.checkFaceFeatures()
                        self.flagFaceCheckFeatures = true
                        return
                    }
                    
                    self.faceEvaluation.addFace(face: faceDetail)
                    if(self.faceEvaluation.count() >= self.maxNumFacesOk){
                        var isBlinking = true
                        if(self.sdkComponent!.livenessRequired){
                            isBlinking = self.faceEvaluation.isBlinking()
                        }
                        if(isBlinking){
                            self.bestFace = self.faceEvaluation.bestFace()
                            self.validateFaceRequest()
                        }else{
                            self.counterFail += 1
                            if(self.counterFail > self.sdkComponent!.maxValidations){
                                self.isFinished = true
                                //self.updateMessageFace(code: .maxValidations)
                                self.updateMessage(code: "maxValidations")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    self.processFailFace(retro: ["static_eye"], faceCaptureReasonFail: .maxValidationsExceeded, score: 0.0)
                                }
                            }else{
                                if(self.hasExpired){
                                    self.isFinished = true
                                    //self.updateMessageFace(code: .expired)
                                    self.updateMessage(code: "expired")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        self.processFailFace(retro: ["static_eye"], faceCaptureReasonFail: .timeout, score: 0.0)
                                    }
                                }else{
                                    self.counterStaticEye += 1
                                    //self.updateMessageFace(code: .staticEye)
                                    self.updateMessage(code: "staticEye")
                                    self.resetEvaluation()
                                }
                            }
                        }
                    }else{
                        //self.updateMessageFace(code: .keep)
                        self.updateMessage(code: "keep")
                        return
                    }
                }
            }else{
                // return if exired
                if(self.hasExpired){
                    self.isFinished = true
                    //self.updateMessageFace(code: .expired)
                    self.updateMessage(code: "expired")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        var retro: [String] = []
                        if(self.counterStaticEye > 0){
                            retro = []
                        }
                        self.processFailFace(retro: retro, faceCaptureReasonFail: .timeout, score: 0.0)
                    }
                }else{
                    //Keep trying if hasnt expired
                    self.resetEvaluation()
                    if(faceDetail.isInside()){
                        if(faceDetail.tooFar()){
                            //self.updateMessageFace(code: .farAway)
                            self.updateMessage(code: "farAway")
                            //print("Es INVALIDO y esta DENTRO pero esta muy LEJOS")
                        }else{
                            if(faceDetail.tooClose()){
                                self.updateMessage(code: "tooClose")
                                //self.updateMessageFace(code: .tooClose)
                                //print("Es INVALIDO y esta DENTRO pero esta muy CERCA")
                            }else{
                                if(faceDetail.pose() == .left || faceDetail.pose() == .right){
                                    self.updateMessage(code: "align")
                                    //self.updateMessageFace(code: .align)
                                }else{
                                    //self.updateMessageFace(code: .unknown)
                                    self.updateMessage(code: "unknown")
                                }
                                //print("Es INVALIDO y esta DENTRO y de TAMANO CORRECTO")
                            }
                        }
                    }else{
                        //self.updateMessageFace(code: .outbounds)
                        self.updateMessage(code: "outbounds")
                        //print("Es INVALIDO y esta FUERA")
                    }
                }
            }
        }
    }
    
