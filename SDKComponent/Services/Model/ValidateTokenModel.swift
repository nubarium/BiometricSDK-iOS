//
//  ValidateToken.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 06/02/23.
//  Copyright © 2023 Nubarium SA de CV. All rights reserved.
//

import Foundation

struct ValidateTokenModel: Codable {
    let status: String
    let message: String
    let request: BiometricRequestResponseModel?
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case request
    }
    
}
