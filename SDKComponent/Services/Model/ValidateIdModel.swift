//
//  ValidateIdModel.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 06/02/23.
//  Copyright © 2023 Nubarium SA de CV. All rights reserved.
//

import Foundation

struct ValidateIdModel: Codable {
    
    let status: String
    let id: String?
    let result: String?
    let confidence: Double?
    let retro: [String]?
    let reason: String?
    let features: IdFeaturesModel?

    enum CodingKeys: String, CodingKey {
        case status
        case id
        case result
        case confidence
        case retro
        case reason
        case features
    }
    
    /*
    let status: String
    let result: String
    let ocurrences: Int
    let attack: Double
    let retro: [String]
    
    enum CodingKeys: String, CodingKey {
        case status
        case result
        case ocurrences
        case attack
        case retro
    }*/
    
}


