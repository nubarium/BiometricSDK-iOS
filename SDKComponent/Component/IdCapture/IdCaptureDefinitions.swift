//
//  IdCaptureDefinitions.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 15/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation

enum IdCaptureInitError {
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



enum IdCaptureReasonFail{
    case timeout, maxValidationsExceeded, rulesNotMet
}

enum IdCaptureError {
    case transactionError, networkProblem,
         serviceError, serviceNotAvailable,
         unknown
}

enum IdCaptureLevelValidation{
    case low, medium, high
    
    var description : String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        }
    }
    
    var value : Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
    
}

enum IdCaptureFeature{
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

