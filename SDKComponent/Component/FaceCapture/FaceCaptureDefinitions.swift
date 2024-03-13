//
//  FaceCaptureDefinitions.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 06/02/23.
//  Copyright © 2023 Nubarium SA de CV. All rights reserved.
//

import Foundation

enum FaceCaptureInitError {
    case badCredentials, accountLocked, userDisabled, timeout, tokenRequestError, networkProblem,
         serviceError, serviceNotAvailable,
         cameraNotAvailable, frontCameraNotAvailable, backCameraNotAvailable,
         invalidStatusCode, unknown
    
    var description : String {
        switch self {
        case .badCredentials: return "Bad credentials"
        case .accountLocked: return "Account locked"
        case .userDisabled: return "User disabled"
        case .timeout: return "Validation timeout"
        case .tokenRequestError: return "Error getting the request identifier"
        case .networkProblem: return "Network problem"
        case .serviceError: return "Service error"
        case .serviceNotAvailable: return "Service not available"
        case .cameraNotAvailable: return "Camera is not available"
        case .frontCameraNotAvailable: return "Front camera is not available"
        case .backCameraNotAvailable: return "Back camera is not available"
        case .invalidStatusCode: return "Invalid status code"
        case .unknown: return "Unknown error"
        }
    }
}

enum ResponseEventType{
    case success, fail, error, undefined
}

enum FaceCaptureReasonFail{
    case timeout, livenessFail, faceDetectFail, maxValidationsExceeded, rulesNotMet
}

enum FaceCaptureReasonError {
    case transactionError, networkProblem,
         serviceError, serviceNotAvailable,
         unknown
}



enum FaceCaptureFeature{
    case glasses, facemask, mask, hat, veryBlurred, blurred
    
    var description : String {
        switch self {
        case .glasses: return "glasses"
        case .facemask: return "facemask"
        case .mask: return "mask"
        case .hat: return "hat"
        case .blurred: return "blurred"
        case .veryBlurred: return "veryBlurred"
        }
    }
    
    var retro : String {
        switch self {
        case .glasses: return "has_glasses"
        case .facemask: return "has_facemask"
        case .mask: return "has_mask"
        case .hat: return "has_hat"
        case .blurred: return "blurred"
        case .veryBlurred: return "very_blurred"
        }
    }
}
