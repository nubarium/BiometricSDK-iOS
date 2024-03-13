//
//  ValidateFace.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 06/02/23.
//  Copyright © 2023 Nubarium SA de CV. All rights reserved.
//

import Foundation

struct ValidateFaceModel: Codable {
    let status: String
    let id: String?
    let result: String?
    let confidence: Double?
    let retro: [String]?
    let reason: String?
    let features: FaceFeaturesModel?

    enum CodingKeys: String, CodingKey {
        case status
        case id
        case result
        case confidence
        case retro
        case reason
        case features
    }
    
}


