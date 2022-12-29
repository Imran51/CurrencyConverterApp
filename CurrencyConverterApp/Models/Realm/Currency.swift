//
//  Currency.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import RealmSwift

class Currency: Object {
    @objc dynamic var code: String = ""
    @objc dynamic var name: String = ""

    override class func primaryKey() -> String? {
        return "code"
    }
}
