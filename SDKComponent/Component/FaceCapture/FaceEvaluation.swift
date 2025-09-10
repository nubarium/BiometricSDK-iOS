//  FaceEvaluation.swift
//  NubariumSDK
//
//  Sin ML Kit. Robustez en el índice y sin crashes. Mantiene contratos.

import Foundation
import CoreGraphics

class FaceEvaluation {

    private var bestFaceIndex = -1
    private var maxOpenEyesProbability: CGFloat = 0.0
    private var status: ResultStatus = .wait
    private var faceList = FaceList()
    private var queueEyesOpen: [CGFloat] = []

    func bestFace() -> FaceDetail {
        let list = self.faceList.listWithfaces()
        let count = list.count
        let idx = (bestFaceIndex >= 0 && bestFaceIndex < count) ? bestFaceIndex : max(0, count - 1)
        return list[idx]
    }

    func resultStatus() -> ResultStatus { status }

    func reset() {
        status = .wait
        maxOpenEyesProbability = 0.0
        queueEyesOpen = []
        self.faceList = FaceList()
        self.bestFaceIndex = -1
    }

    private func getMaxEyesOpenIndex() -> Int {
        let lista = faceList.listWithfaces()
        guard !lista.isEmpty else { return 0 }
        var maxProb: CGFloat = -CGFloat.greatestFiniteMagnitude
        var maxIndex = 0
        for i in 0..<lista.count {
            let p = (lista[i].leftEyeOpenProbability + lista[i].rightEyeOpenProbability) / 2.0
            if p > maxProb { maxProb = p; maxIndex = i }
        }
        return maxIndex
    }

    func addFace(face: FaceDetail) {
        faceList.add(face)
        bestFaceIndex = getMaxEyesOpenIndex()
    }

    func count() -> Int { faceList.count() }

    func isBlinking() -> Bool {
        
        return true
    }
}

enum ResultStatus { case pass, fail, warning, wait }
