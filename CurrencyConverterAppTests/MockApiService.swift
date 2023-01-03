//
//  MockApiService.swift
//  CurrencyConverterAppTests
//
//  Created by Imran Sayeed on 1/2/23.
//

import Foundation
@testable import CurrencyConverterApp
import Combine


struct MockApiService: CurrencyService {
    private let rateDict = [
        "AED": 3.672655,
        "AFN": 89.009346,
        "ALL": 106.798105,
        "AMD": 392.767581,
        "ANG": 1.797972,
        "AOA": 503.691,
        "ARS": 176.735804,
        "AUD": 1.471427,
        "AWG": 1.8,
        "AZN": 1.7,
        "BAM": 1.827622,
        "BBD": 2,
        "BDT": 102.905665,
        "JPY": 130.78866667,
        "USD": 1.000
    ]
    
    let apiClient: ApiClient
    func fetchLatestCurrencies(currencyRequest: CurrencyRequestLayer) -> AnyPublisher<LatestCurrencyExchangeRateInfo, NetworkError> {
        guard let _ = try? currencyRequest.asURLRequest() else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return Just(LatestCurrencyExchangeRateInfo(timestamp: 1672657200, base: "USD", rates: rateDict)).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
//        return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
    }
    
    func getSupportedCurrencies(currencyRequest: CurrencyRequestLayer) -> AnyPublisher<[String : String], NetworkError> {
        guard let _ = try? currencyRequest.asURLRequest() else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return Just(["BDT": "Bangladeshi Taka", "JPY": "Japanese Yen"]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
    }
}


class MockUserDefaultsStore: CurrencyLocalStoreProtocol {
    
    static let shared = MockUserDefaultsStore()
    private var defaults: MockUserDefaults?
    private init() {
        defaults = MockUserDefaults(suiteName: "MockUserDefaultsStore")
    }
    func get<T>(for key: DefaultsKey) -> T? {
        return defaults?.object(forKey: key.rawValue) as? T
    }
    
    func set<T>(value: T?, for key: DefaultsKey) {
        defaults?.set(value, forKey: key.rawValue)
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
