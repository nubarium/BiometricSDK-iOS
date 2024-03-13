//
//  BiometricRequestResponseModel.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 06/02/23.
//  Copyright © 2023 Nubarium SA de CV. All rights reserved.
//

import Foundation

struct BiometricRequestResponseModel: Codable {
    let id: String
    let status: String
    let ts: Int64
    let expire: Int64
    let operations: Int?
    let component: String
    let device: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case id
        case ts
        case expire
        case operations
        case component
        case device
    }
    
}
