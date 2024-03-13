//
//  Enum.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 10/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation

enum CameraSideView{
    case front,
         back,
         frontElseBack,
         backElseFront,
         frontOrBack,
         backOrFront
}

enum StatusRequest{
    case notStarted, started, failed, completed
}
