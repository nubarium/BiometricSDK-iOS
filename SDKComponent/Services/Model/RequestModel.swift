//
//  RequestResponse.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 01/02/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//

import Foundation

struct RequestModel: Codable {
    let status: String?
    let message: String?
    let id: String
    let version: String?
    let owner: String?
    let available: Bool?
    let ts: Int?
    let start: Int?
    let expire: Int?
    let operations: Int?
    let component: String?
    let device: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case id
        case version
        case owner
        case available
        case ts
        case start
        case expire
        case operations
        case component
        case device
      }
}
