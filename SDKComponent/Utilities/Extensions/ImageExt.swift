/*
  Copyright (c) 2017-2021 M.I. Hollemans
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
*/

#if canImport(UIKit)

import UIKit
import VideoToolbox
import CoreGraphics
import VideoToolbox
import Vision

extension UIImage {
    func resizeImageTo(size: CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
            VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

            guard let cgImage = cgImage else {
                return nil
            }

            self.init(cgImage: cgImage)
    }
    
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
            let radiansToDegrees: (CGFloat) -> CGFloat = {
                return $0 * (180.0 / CGFloat.pi)
            }
            let degreesToRadians: (CGFloat) -> CGFloat = {
                return $0 / 180.0 * CGFloat.pi
            }

            // calculate the size of the rotated view's containing box for our drawing space
            let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: size))
            let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
            rotatedViewBox.transform = t
            let rotatedSize = rotatedViewBox.frame.size

            // Create the bitmap context
            UIGraphicsBeginImageContext(rotatedSize)
            let bitmap = UIGraphicsGetCurrentContext()

            // Move the origin to the middle of the image so we will rotate and scale around the center.
            bitmap?.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)

            //   // Rotate the image context
            bitmap?.rotate(by: degreesToRadians(degrees))

            // Now, draw the rotated/scaled image into the context
            var yFlip: CGFloat

            if(flip){
                yFlip = CGFloat(-1.0)
            } else {
                yFlip = CGFloat(1.0)
            }

            bitmap?.scaleBy(x: yFlip, y: -1.0)
            let rect = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)

            bitmap?.draw(cgImage!, in: rect)

            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage!
        }
    
    func convertImageToBase64String () -> String {
        return self.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }
    
    func crop(rect: CGRect) -> UIImage {
        let cgImage = self.cgImage! //image.cgImage! // better to write "guard" in realm app
        let croppedCGImage = cgImage.cropping(to: rect)
        return UIImage(cgImage: croppedCGImage!)
    }
    
    func detectText(){
        var image : UIImage = self
        print("Paso -2")
        var img: CGImage? = self.cgImage
        print("Corrupcion")
        print(img!.width)
        if let cgImage = image.cgImage {
            
           // VNImageRequestHandler(cmSampleBuffer: <#T##CMSampleBuffer#>)
            print("Paso -1")
          let requestHandler = VNImageRequestHandler(cgImage: cgImage)

            print("Paso 0")
          let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
            // 1. Parse the results
              print("Paso 1")
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
              return
            }
            print("Paso 2")
            // 2. Extract the data you want
            let recognizedStrings = observations.compactMap { observation in
              observation.topCandidates(1).first?.string
            }
            
            // 3. Display or update UI
            DispatchQueue.main.async {
              print(recognizedStrings)
            }
          }
          
            recognizeTextRequest.recognitionLevel = .accurate
          
          DispatchQueue.global(qos: .userInitiated).async {
            do {
              try requestHandler.perform([recognizeTextRequest])
            } catch {
              print(error)
            }
          }
        }
    }
   
    
    
}

#endif


extension CMSampleBuffer {
    /// https://stackoverflow.com/questions/15726761/make-an-uiimage-from-a-cmsamplebuffer
    func image(orientation: UIImage.Orientation = .up, scale: CGFloat = 1.0) -> UIImage? {
        if let buffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: buffer)

            return UIImage(ciImage: ciImage, scale: scale, orientation: orientation)
        }

        return nil
    }

    func imageWithCGImage(orientation: UIImage.Orientation = .up, scale: CGFloat = 1.0) -> UIImage? {
        if let buffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: buffer)

            let context = CIContext(options: nil)

            guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else {
                return nil
            }
            
            return UIImage(cgImage: cg, scale: scale, orientation: orientation)
        }

        return nil
    }
    
    func detectText(image: UIImage){
        
        // VNImageRequestHandler(cmSampleBuffer: <#T##CMSampleBuffer#>)
       
        if #available(iOS 14.0, *) {
            let requestHandler = VNImageRequestHandler(cmSampleBuffer: self, orientation: .right)
            
            
            print("Paso 0")
            let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
                // 1. Parse the results
                print("Paso 1")
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }
                print("Paso 2")
                // 2. Extract the data you want
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                // 3. Display or update UI
                DispatchQueue.main.async {
                    //print(recognizedStrings)
                }
                
                let boundingRects: [CGRect] = observations.compactMap { observation in

                    // Find the top observation.
                    guard let candidate = observation.topCandidates(1).first else { return .zero }
                    
                    // Find the bounding-box observation for the string range.
                    let stringRange = candidate.string.startIndex..<candidate.string.endIndex
                    let boxObservation = try? candidate.boundingBox(for: stringRange)
                    
                    // Get the normalized CGRect value.
                    let boundingBox = boxObservation?.boundingBox ?? .zero
                    
                    let boundingRects: CGRect = VNImageRectForNormalizedRect(boundingBox,
                                                                             Int(image.size.width),
                                                                             Int(image.size.height))
                                
                    //print(candidate.string, boundingRects)
                    /*candidate.string
                    VNConfidence
                    boundingRects*/
                    print(candidate.string, " -> " , boundingRects.minX,boundingRects.minY, boundingRects.height)
                    
                    // Convert the rectangle from normalized coordinates to image coordinates.
                    return boundingRects
                }
                
                // 3. Display or update UI
                DispatchQueue.main.async {
                    //print(boundingRects)
                }
                
                
                
            }
            
            recognizeTextRequest.recognitionLevel = .accurate
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try requestHandler.perform([recognizeTextRequest])
                } catch {
                    print(error)
                }
            }
            
        }
        else {
            // Fallback on earlier versions
        }
    }
}
