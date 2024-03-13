//
//  StringCase.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 23/02/23.
//  Copyright © 2023 Google Inc. All rights reserved.
//

import Foundation

extension String {

    /// A collection of all the words in the string by separating out any punctuation and spaces.
    var words: [String] {
        return components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    }

    /// Returns a copy of the string with the first word beginning lowercased, and the first
    /// letter of each word thereafter is capitalized, with no intervening spaces or punctuation,
    /// e.g., "theQuickBrownFoxJumpsOverTheLazyDog".
    ///
    /// *Lower camel case* (or, illustratively, *camelCase*) is also known as *Dromendary case*.
    func lowerCamelCased() -> String {
        guard !self.isEmpty else { return "" }
        let words = self.words
        let first = words.first!.lowercased()
        let rest = words.dropFirst().map { $0.capitalized }
        return ([first] + rest).joined()
    }

    /// Returns a copy of the string with the first letter of each word capitalized, with no
    /// intervening spaces or punctuation, e.g., "TheQuickBrownFoxJumpsOverTheLazyDog".
    ///
    /// *Upper camel case* (or, illustratively, *CamelCase*) is also known as *Pascal case*.
    func upperCamelCased() -> String {
        return self.words.map({ $0.capitalized }).joined()
    }
    
  func snakeCased() -> String? {
    let pattern = "([a-z0-9])([A-Z])"

    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: self.count)
    return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
  }
}
