//
//  Utils.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 09/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation

public class Utils{
    
    static func localizedString(forKey key: String, defaultTable: String, alternateTable: String) -> String {
        if(alternateTable != ""){
            var result = Bundle.main.localizedString(forKey: key, value: nil, table: alternateTable)
            if result == key {
                result = Bundle.main.localizedString(forKey: key, value: nil, table: defaultTable)
            }
            return result
        }else{
            let result = Bundle.main.localizedString(forKey: key, value: nil, table: defaultTable)
            return result
        }
    }
    
}
