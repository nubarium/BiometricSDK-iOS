//
//  ComponentInfo.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 02/02/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//

import Foundation

var ComponentInfo = _ComponentInfo()

struct _ComponentInfo{
    
    var version : (minor: Int, major: Int, patch: Int, description: String)
    
    init(){
        version.major = 1
        version.minor = 0
        version.patch = 0
        version.description = "1.0.0"
    }
    
    /*func version() -> (_:Int, _:Int, _:Int, _:String){
        return componentVersion
    }*/
    
    
    
}


