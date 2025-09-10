//  FaceProcessor.swift
//  NubariumSDK
//
//  Vision-only. Mantiene firma pública de processAsync(...).
//  Detecta orientación (EXIF) y cae a orientación de dispositivo;
//  si no puede, asume .right (portrait) para privilegiar la captura.

import Foundation
import Vision
import UIKit
import CoreMedia
import ImageIO

class FaceProcessor {

    var area: CGRect
    private let sequenceHandler = VNSequenceRequestHandler()

    init(area: CGRect) { self.area = area }

    /// Procesa el frame y retorna una lista de FaceDetail calculada con Apple Vision.
    /// Firma compatible con la implementación previa.
    func processAsync(sampleBuffer: CMSampleBuffer?, _ function: @escaping ([FaceDetail], CMSampleBuffer, Error?) -> Void) {
        guard let sampleBuffer = sampleBuffer,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            // Entrada inválida: no llamar callback con sampleBuffer nil para evitar crash aguas arriba.
            return
        }

        let faceRectangles = VNDetectFaceRectanglesRequest()
        let landmarksRequest = VNDetectFaceLandmarksRequest()

        var qualityRequest: VNDetectFaceCaptureQualityRequest?
        if #available(iOS 15.0, *) { qualityRequest = VNDetectFaceCaptureQualityRequest() }

        let orientation = Self.resolvedExifOrientation(for: sampleBuffer)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1) Detectar rostros (rectángulos)
                try self.sequenceHandler.perform([faceRectangles], on: pixelBuffer, orientation: orientation)
                let rectObservations = (faceRectangles.results as? [VNFaceObservation]) ?? []

                if rectObservations.isEmpty {
                    DispatchQueue.main.async { function([], sampleBuffer, nil) }
                    return
                }

                // 2) Landmarks (y opcionalmente calidad)
                landmarksRequest.inputFaceObservations = rectObservations
                if #available(iOS 15.0, *) { qualityRequest?.inputFaceObservations = rectObservations }

                if let q = qualityRequest {
                    try self.sequenceHandler.perform([landmarksRequest, q], on: pixelBuffer, orientation: orientation)
                } else {
                    try self.sequenceHandler.perform([landmarksRequest], on: pixelBuffer, orientation: orientation)
                }

                let lmObservations = (landmarksRequest.results as? [VNFaceObservation]) ?? rectObservations

                var ret: [FaceDetail] = []
                ret.reserveCapacity(lmObservations.count)
                for obs in lmObservations {
                    // Si quisieras un filtro mínimo por tamaño, actívalo aquí (similar a minFaceSize=0.45):
                    // if obs.boundingBox.height < 0.45 { continue }
                    let detail = FaceDetail(observation: obs, containerArea: self.area, snapshot: sampleBuffer)
                    ret.append(detail)
                }

                DispatchQueue.main.async { function(ret, sampleBuffer, nil) }
            } catch {
                DispatchQueue.main.async { function([], sampleBuffer, error) }
            }
        }
    }

    // MARK: - Orientación robusta

    /// Intenta EXIF del sampleBuffer; si no, deriva de UIDevice; si no, asume .right (portrait).
    private static func resolvedExifOrientation(for sampleBuffer: CMSampleBuffer) -> CGImagePropertyOrientation {
        if let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault,
                                                           target: sampleBuffer,
                                                           attachmentMode: kCMAttachmentMode_ShouldPropagate) as? [CFString: Any],
           let exifRaw = attachments[kCGImagePropertyOrientation] as? UInt32,
           let exif = CGImagePropertyOrientation(rawValue: exifRaw) {
            return exif
        }
        if let dev = exifFromDeviceOrientation() {
            return dev
        }
        // Fallback seguro privilegiando portrait
        return .right
    }

    /// Mapeo típico de orientación de dispositivo a EXIF.
    private static func exifFromDeviceOrientation() -> CGImagePropertyOrientation? {
        switch UIDevice.current.orientation {
        case .portrait: return .right
        case .portraitUpsideDown: return .left
        case .landscapeLeft: return .up
        case .landscapeRight: return .down
        case .faceUp, .faceDown, .unknown: return nil
        @unknown default: return nil
        }
    }
}
