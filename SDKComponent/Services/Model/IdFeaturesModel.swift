//
//  IdFeaturesModel.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 15/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation

struct IdFeaturesModel: Codable {
    let status: String?
    let id: String?
    let has_glasses: Bool?
    let has_mask: Bool?
    let has_facemask: Bool?
    let has_hat: Bool?
    let blur: Int?
    let message: String? = ""
    
    enum CodingKeys: String, CodingKey {
        case status
        case id
        case has_glasses
        case has_mask
        case has_facemask
        case has_hat
        case blur
        case message
    }
}
