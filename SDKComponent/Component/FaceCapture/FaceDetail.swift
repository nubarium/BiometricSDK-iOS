//  FaceDetail.swift
//  NubariumSDK
//
//  Vision-only. Defaults favorables: ojos=1.0 y yaw/roll=0° si no se pueden calcular.
//  Mantiene API/contratos tal cual. Se clampa todo recorte a los límites de imagen.

import Foundation
import UIKit
import CoreMedia
import Vision

struct FaceDetail {

    private var frameSnapshot: UIImage
    private var isInsideProp = false
    private var tooCloseProp = false
    private var tooFarProp = false
    private var ts = Date()

    // Properties
    var area: CGRect

    // Original Properties (compatibilidad 1:1)
    var frame: CGRect
    var hasHeadEulerAngleX: Bool
    var headEulerAngleX: CGFloat
    var hasHeadEulerAngleY: Bool
    var headEulerAngleY: CGFloat
    var hasHeadEulerAngleZ: Bool
    var headEulerAngleZ: CGFloat
    var hasSmilingProbability: Bool
    var smilingProbability: CGFloat
    var hasLeftEyeOpenProbability: Bool
    var leftEyeOpenProbability: CGFloat
    var hasRightEyeOpenProbability: Bool
    var rightEyeOpenProbability: CGFloat

    // === Apple Vision ===
    init(observation: VNFaceObservation, containerArea: CGRect, snapshot: CMSampleBuffer) {
        self.ts = Date()
        self.frameSnapshot = UIImage()
        self.frame = .zero

        // 1) Defaults que favorecen la captura (robusto/compatible)
        self.hasHeadEulerAngleX = false
        self.headEulerAngleX = 0.0 // Vision no da pitch -> dummy
        self.hasHeadEulerAngleY = true
        self.headEulerAngleY = 0.0 // como si mirara al frente (si no hay yaw)
        self.hasHeadEulerAngleZ = true
        self.headEulerAngleZ = 0.0 // nivelado (si no hay roll)
        self.hasSmilingProbability = false
        self.smilingProbability = 0.0 // sin sonrisa -> dummy
        self.hasLeftEyeOpenProbability = true
        self.leftEyeOpenProbability = 1.0 // ojos abiertos por defecto (si no hay landmarks)
        self.hasRightEyeOpenProbability = true
        self.rightEyeOpenProbability = 1.0 // ojos abiertos por defecto (si no hay landmarks)

        // 2) Si Vision SI trae yaw/roll, úsalo (en grados)
        if let yaw = observation.yaw {
            self.headEulerAngleY = Self.radiansToDegrees(CGFloat(truncating: yaw))
        }
        if let roll = observation.roll {
            self.headEulerAngleZ = Self.radiansToDegrees(CGFloat(truncating: roll))
        }

        // 3) Si hay landmarks, estimar “probabilidad” de ojo abierto con EAR (si falla, queda 1.0)
        if let marks = observation.landmarks {
            if let leftEAR = Self.estimatedEyeOpenProbability(from: marks.leftEye) {
                self.leftEyeOpenProbability = leftEAR
            }
            if let rightEAR = Self.estimatedEyeOpenProbability(from: marks.rightEye) {
                self.rightEyeOpenProbability = rightEAR
            }
        }

        // 4) Mapear bbox normalizado a píxeles (y clamp seguro)
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(snapshot) else {
            // No snapshot: manten defaults y sal
            self.area = containerArea
            return
        }
        let w = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let h = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageBounds = CGRect(x: 0, y: 0, width: w, height: h)

        let bb = observation.boundingBox
        var rect = CGRect(
            x: bb.origin.x * w,
            y: (1.0 - bb.origin.y - bb.height) * h, // flip Y
            width: bb.width * w,
            height: bb.height * h
        ).integral
        rect = rect.intersection(imageBounds)
        self.frame = rect

        // 5) Asegurar que `area` sea usable (si no, usar los límites de la imagen)
        var effArea = containerArea
        if effArea.isEmpty || effArea.width < 1 || effArea.height < 1 {
            effArea = imageBounds
        } else if !imageBounds.contains(effArea) {
            let inter = effArea.intersection(imageBounds)
            effArea = inter.isEmpty ? imageBounds : inter
        }
        self.area = effArea

        // 6) Reglas de tamaño/posición (conservadas)
        self.isInsideProp = effArea.contains(rect)
        let ratio = effArea.height > 0 ? (rect.height / effArea.height) : 0
        self.tooCloseProp = (ratio > 0.74)
        self.tooFarProp = (ratio < 0.55)

        // 7) Guardar snapshot si pasa “validaciones suaves”
        if let image = UIImage(pixelBuffer: pixelBuffer),
           self.isInsideProp && !self.tooFarProp && !self.tooCloseProp {
            self.frameSnapshot = image
        }
    }

    public mutating func release() { frameSnapshot = UIImage() }
    func create() -> Date { ts }
    func isInside() -> Bool { isInsideProp }
    func tooFar() -> Bool { tooFarProp }
    func tooClose() -> Bool { tooCloseProp }
    func hasEyesOpen() -> Bool { true }

    func pose() -> Pose {
        // Mantiene tu regla ±19° (compatibilidad)
        if self.headEulerAngleY > 19 { return .left }
        else if self.headEulerAngleY < -19 { return .right }
        else { return .front }
    }

    func isValid() -> Bool {
        return (self.isInsideProp && !self.tooFarProp && !self.tooCloseProp && self.pose() == .front)
    }

    func frameImage() -> UIImage { frameSnapshot }

    func areaImage() -> UIImage {
        guard frameSnapshot.size.width > 0, frameSnapshot.size.height > 0 else { return UIImage() }
        let rect = area.intersection(CGRect(origin: .zero, size: frameSnapshot.size))
        return frameSnapshot.crop(rect: rect)
    }

    func faceImage() -> UIImage {
        guard frameSnapshot.size.width > 0, frameSnapshot.size.height > 0 else { return UIImage() }
        let rect = frame.intersection(CGRect(origin: .zero, size: frameSnapshot.size))
        return frameSnapshot.crop(rect: rect)
    }

    // MARK: - Helpers

    private static func radiansToDegrees(_ r: CGFloat) -> CGFloat { r * 180.0 / .pi }

    /// EAR→[0,1], o nil si no hay puntos suficientes (si es nil, queda default 1.0 asignado antes)
    private static func estimatedEyeOpenProbability(from region: VNFaceLandmarkRegion2D?) -> CGFloat? {
        guard let region = region, region.pointCount >= 3 else { return nil }
        let pts = region.normalizedPoints
        var minX: CGFloat = 1, maxX: CGFloat = 0, minY: CGFloat = 1, maxY: CGFloat = 0
        for p in pts {
            if p.x < minX { minX = p.x }
            if p.x > maxX { maxX = p.x }
            if p.y < minY { minY = p.y }
            if p.y > maxY { maxY = p.y }
        }
        let w = max(maxX - minX, 1e-6), h = maxY - minY
        var ratio = h / w // abierto→mayor, cerrado→menor
        // Normalización heurística [0.02..0.35] → [0..1]
        let minR: CGFloat = 0.02, maxR: CGFloat = 0.35
        ratio = (ratio - minR) / (maxR - minR)
        return max(0, min(1, ratio))
    }
}

enum Pose { case front, up, down, left, right }
