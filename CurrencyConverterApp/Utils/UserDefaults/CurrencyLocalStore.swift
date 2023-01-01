//
//  LocalUserDefaults.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/29/22.
//

import Foundation

enum DefaultsKey: String {
    case fetchedTimestamp
    case currenciesFetchedTimestamp
    case baseCurrencyCode
}

protocol CurrencyLocalStoreProtocol {
    func get<T>(for key: DefaultsKey) -> T?
    func set<T>(value: T?, for key: DefaultsKey)
}

class CurrencyLocalStore: CurrencyLocalStoreProtocol {

    static let shared = CurrencyLocalStore()
    #if TESTING
        private let defaults: UserDefaults = MockUserDefaults(suiteName: "TestingCurrencyLocalStore")
    #else
        private let defaults: UserDefaults = UserDefaults.standard
    #endif

    private init() {}

    func get<T>(for key: DefaultsKey) -> T? {
        return defaults.object(forKey: key.rawValue) as? T
    }

    func set<T>(value: T?, for key: DefaultsKey) {
        defaults.set(value, forKey: key.rawValue)
    }
}


class MockUserDefaults : UserDefaults {
  convenience init() {
    self.init(suiteName: "Mock User Defaults")!
  }

  override init?(suiteName suitename: String?) {
    UserDefaults().removePersistentDomain(forName: suitename!)
    super.init(suiteName: suitename)
  }
}
