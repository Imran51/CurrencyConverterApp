//
//  Currencies.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation

struct CurrencyInformation: Hashable {
    var code: String
    var name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(name)
    }
}

extension CurrencyInformation: Equatable {
    static func == (lhs: CurrencyInformation, rhs: CurrencyInformation) -> Bool {
        lhs.code == rhs.code && lhs.name == rhs.name
    }
}
