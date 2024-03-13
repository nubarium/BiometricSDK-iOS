#  <#Title#>
                deny
                
            showPreview
            livenessRequired
            maxValidations
            
        faceCaptureOptions.timeout
            enableVideoHelp
            enableTroubleshootHelp 
            showIntro
            sideView
            messagesResource
            allowManualSideView
              
    
    /*
    func detectedFace(request: VNRequest, error: Error?) {
      // 1
      guard
        let results = request.results as? [VNFaceObservation],
        let result = results.first
        else {
          // 2
          faceView.clear()
          return
      }
        
      // 3
      let box = result.boundingBox
      faceView.boundingBox = convert(rect: box)
        
      // 4
      DispatchQueue.main.async {
        self.faceView.setNeedsDisplay()
      }
    }
    var sequenceHandler = VNSequenceRequestHandler()
    func detectFace(image: CMSampleBuffer?){
        // 1
        guard let imageBuffer = CMSampleBufferGetImageBuffer(image!) else {
          return
        }

        // 2
        let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFace)

        // 3
        do {
          try sequenceHandler.perform(
            [detectFaceRequest],
            on: imageBuffer,
            orientation: .leftMirrored)
        } catch {
          print(error.localizedDescription)
        }
    }*/              
              
              
              
                    
/*
 
 func detectId(image: UIImage?)  {
     
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
     
     var family = ""
     
     var isForeign = false, isINE = false, isIFE = false
     var isFechaAlignedNombre = false, isSexoAlignedNombre = false, isEdadAlignedNombre = false
     
     
     guard let image = image else { return }
     let options = TextRecognizerOptions()
     let textRecognizer = TextRecognizer.textRecognizer(options:options)
     //CONTOUR_MODE_NONE
     //options.landmarkMode = .none
     //options.classificationMode = .none
     //options.performanceMode = .fast
     //options.contourMode = .none
     
     // [END config_face]
     // [START init_face]
     // [END init_face]
     // Initialize a `VisionImage` object with the given `UIImage`.
     let visionImage = VisionImage(image: image)
     visionImage.orientation = image.imageOrientation
     
     // [START detect_faces]
     weak var weakSelf = self
     textRecognizer.process(visionImage) { result, error in
         guard let strongSelf = weakSelf else {
             print("Self is nil!")
             return
         }
         
         guard error == nil, let result = result, !result.text.isEmpty else {
             // [START_EXCLUDE]
             let errorString = error?.localizedDescription ?? Constants.detectionNoResultsMessage
             //strongSelf.resultsText = "On-Device face detection failed with error: \(errorString)"
             print( "On-Device text detection failed with error: \(errorString)")
             
             //strongSelf.showResults()
             // [END_EXCLUDE]
             return
         }
         
         var attemptSide = ""
         let document = CGRect()
         
         let resultText = result.text
         for block in result.blocks {
             let blockText = block.text
             let blockLanguages = block.recognizedLanguages
             let blockCornerPoints = block.cornerPoints
             let blockFrame = block.frame
             for line in block.lines {
                 print("ocr", line.text)
                 let lineText = line.text
                 let lineLanguages = line.recognizedLanguages
                 let lineCornerPoints = line.cornerPoints
                 let lineFrame = line.frame
                 
                 
                 var txt: String = lineText.trimmingCharacters(in: .whitespacesAndNewlines)

                 
                 var texto : CGRect = line.frame
                 
                 if ((txt.contains("IDMEX")) && (txt.count >= 28 && txt.count <= 31) ) {
                     attemptSide = "BACK";
                 }
                 if ((txt.contains("SEX") || (txt.distance(from: "SEXH")<=2  || txt.distance(from: "SEXM")<=2) ) && P_SEXO.x==0) {
                     P_SEXO.x = texto.minX
                     P_SEXO.y = texto.minY
                 }
                 if (  (txt.contains("EDAD") || (txt.distance( from:"EDAD")<=2  || txt.distance( from:"EDAD")<=2) )   && P_EDAD.x==0) {
                     P_EDAD.x = texto.minX
                     P_EDAD.y = texto.minY
                 }
                 if (   (txt.contains("NOMBR") || (txt.distance( from:"NOMBRE")<=3  || txt.distance( from:"NOMBRE")<=3)    ) && P_NOMBRE.x == 0) {
                     attemptSide = "FRONT";
                     P_NOMBRE.x = texto.minX
                     P_NOMBRE.y = texto.minY
                 }
                 if (txt.contains("FECHA") || txt.contains("FECH") || txt.contains("NACMENT") || txt.contains("CMENTO")  ) {
                     P_FECHA_NACIMIENTO.x = texto.minX
                     P_FECHA_NACIMIENTO.y = texto.minY
                 }
                 if (txt.contains("EXTRAN")) {
                     isForeign = false
                 }
                 if ((txt.contains("NACIONA") || txt.contains("TITUIONAC") ||  txt.contains("TITUTONAC") ||  txt.contains("TUTONAC") ) && !isINE) {
                     isINE = true;
                     isIFE = false;
                 }
                 if ((txt.contains("FEDERA") || txt.contains("TITUIOFED") ||  txt.contains("TITUTOFED") ||  txt.contains("TUTOFED") ) && !isINE && !isIFE) {
                     isIFE = true;
                     isINE = false;
                 }
                 
                 
                 
                 if (P_NOMBRE.x > 5 && (P_SEXO.x > 5 || P_FECHA_NACIMIENTO.x > 5)) {
                     
                     
                     if (abs(P_FECHA_NACIMIENTO.y - P_NOMBRE.y) <= 100 && P_FECHA_NACIMIENTO.y>0 && P_NOMBRE.y>0) {
                         isFechaAlignedNombre = true
                     }
                     if (abs(P_SEXO.y - P_NOMBRE.y) <= 30 && P_SEXO.y>0 && P_NOMBRE.y>0) {
                         isSexoAlignedNombre = true
                     }
                     if (abs(P_EDAD.y - P_NOMBRE.y) <= 100 && P_EDAD.y>0 && P_NOMBRE.y>0) {
                         isEdadAlignedNombre = true
                     }
                     
                     if(!isFechaAlignedNombre && !isSexoAlignedNombre && !isEdadAlignedNombre){
                         return
                     }
                     
                    
                     /*
                      if (isINE) {
                          if (isFechaAlignedNombre) {
                              family = "EF"
                              if (isForeign) {
                                  type = "F"
                              } else {
                                  type = "E"
                              }
                          } else {
                              if (isSexoAlignedNombre) {
                                  family = "HG"
                                  if (isForeign) {
                                      type = "H"
                                  } else {
                                      type = "G"
                                  }
                              } else {
                                  type = nil
                                  family = nil
                              }
                          }
                      } else {
                          if (isFechaAlignedNombre) {
                              family = "D";
                              type = "D";
                          } else {
                              if (isEdadAlignedNombre) {
                                  family = "C";
                                  type = "C";
                              } else {
                                  type = nil
                                  family = nil
                              }
                          }
                      }
                      if (type == nil) {
                          isINE = false;
                          isIFE = false;
                          isForeign = false;
                          return;
                      }
                      //HG  default
                      var ORIGINAL_NOMBRE_X = 340, ORIGINAL_NOMBRE_Y = 180
                      var ORIGINAL_WIDTH = 1000, ORIGINAL_HEIGHT = 630
                      
                      var ORIGINAL_REFERENCE_X = 880, ORIGINAL_REFERENCE_Y = 180
                      
                      var P_REF : CGPoint = P_SEXO
                      if (family == "EF") {
                          ORIGINAL_NOMBRE_X = 324
                          ORIGINAL_NOMBRE_Y = 164
                          
                          ORIGINAL_REFERENCE_X = 784
                          ORIGINAL_REFERENCE_Y = 167
                          P_REF = P_FECHA_NACIMIENTO
                      }
                      if (family == "D") {
                          ORIGINAL_NOMBRE_X = 312
                          ORIGINAL_NOMBRE_Y = 164
                          
                          ORIGINAL_REFERENCE_X = 773
                          ORIGINAL_REFERENCE_Y = 168
                          P_REF = P_FECHA_NACIMIENTO
                      }
                      if (family == "C") {
                          ORIGINAL_NOMBRE_X = 57
                          ORIGINAL_NOMBRE_Y = 181
                          
                          ORIGINAL_REFERENCE_X = 551
                          ORIGINAL_REFERENCE_Y = 210
                          P_REF = P_EDAD
                      }
                      var ratiowidthSexNombre = CGFloat(ORIGINAL_REFERENCE_X - ORIGINAL_NOMBRE_X) / CGFloat(ORIGINAL_WIDTH)
                      var heightRatio = CGFloat( ORIGINAL_NOMBRE_Y) / CGFloat(ORIGINAL_HEIGHT)
                      
                      WIDTH_SEX_NOMBRE = P_REF.x - P_NOMBRE.x;
                      WIDTH_ID = Int( CGFloat( WIDTH_SEX_NOMBRE) / ratiowidthSexNombre);
                      HEIGHT_ID = Int( CGFloat(ORIGINAL_HEIGHT) / (ORIGINAL_WIDTH) * CGFloat(WIDTH_ID) )
                      
                      P_ID.x = Int((P_NOMBRE.x - (  CGFloat(WIDTH_ID) *  ( CGFloat(ORIGINAL_NOMBRE_X) / 1000.0))))
                      P_ID.y = Int( P_NOMBRE.y - (  CGFloat(HEIGHT_ID) * heightRatio ) )
                      
                      
                      /*logueaD("rocco Credencial CROP", "WIDTH_SEX_NOMBRE: " + WIDTH_SEX_NOMBRE);
                       logueaD("rocco Credencial CROP", "W: " + WIDTH_ID + "  H: " + HEIGHT_ID + "  X: " + P_ID.x + "   Y:" + P_ID.y);*/
                      
                      if(P_ID.x>0 && P_ID.y>0 && (P_ID.x + WIDTH_ID)>0 && (P_ID.y + HEIGHT_ID)>0) {
                          //document = new Rect(P_ID.x*2, P_ID.y*2, (P_ID.x + WIDTH_ID)*2, (P_ID.y + HEIGHT_ID)*2);
                          var radio = CGFloat(WIDTH_ID) / CGFloat(HEIGHT_ID)
                          var r = ORIGINAL_WIDTH / ORIGINAL_HEIGHT
                          if(  abs( radio-r) < 0.2 ) {
                              document = CGRect(x: P_ID.x, y:P_ID.y, width:(WIDTH_ID), height: (HEIGHT_ID))
                          }
                      }
                      
                      
                      
                      
                      
                      */
                     
                     
                     
                     
                     
                     
                 }
                 
                 for element in line.elements {
                     let elementText = element.text
                     let elementCornerPoints = element.cornerPoints
                     let elementFrame = element.frame
                 }
             }
         }
     }
     
     
     
     
     //  for (Text.Element element : line.getElements()) {
     //                        }
     //}
     //}
     
     // [END detect_faces]
 }
 
 
 */



//print(1)
//do{
//OpenCVWrapper.toGray(image)
//var blurred = OpenCVWrapper.gaussianBlurImage(image)
//print("blurred", blurred)
//var blur = OpenCVWrapper.isImageBlurry(image);
//print("blur", blur)
//OpenCVWrapper.isBlurry(image)
//image.isBlurry();
//}catch{
//}
//if(contador==121){
//var cropeada = image.crop(rect: CGRect(x: 120, y: 320, width: 480, height: 640))
//var b64 = image.convertImageToBase64String()
//print("base64 ",b64)
//}
//detectId(image: image)
