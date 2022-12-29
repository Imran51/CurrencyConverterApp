//
//  CurrencyRateViewModel.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import Combine

final class CurrencyRateViewModel {
    @Published var exchangeRate: [ExchangeRate] = []
    @Published var baseCurrency: String = "USD"
    private var initialExchangeRate: [ExchangeRate] = []
    private let networkService: CurrencyService
    private let realmStore: RealmStore
    private let localUserDefaults: CurrencyLocalStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: CurrencyService, realmStore: RealmStore, locaStore: CurrencyLocalStoreProtocol) {
        self.networkService = networkService
        self.realmStore = realmStore
        self.localUserDefaults = locaStore
    }
    
    func fetchLatestCurrencies() {
        if let date: Date = localUserDefaults.get(for: .currenciesFetchedTimestamp), Date() < date + 30 * 60 {
            guard let fetchedLastCurrency = realmStore.getLatestCurrencies() else {
                return
            }
            var dict = [String: Double]()
            fetchedLastCurrency.rates.forEach({ dict[$0.key] = $0.val })
            let latestCurrency = LatestCurrencies(timestamp: fetchedLastCurrency.timestamp, base: fetchedLastCurrency.base, rates: dict)
            exchangeRate = latestCurrency.rates.compactMap({ ExchangeRate(targetCurrencyCode: $0.key, value: $0.value) }).sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
            initialExchangeRate = exchangeRate
            baseCurrency = fetchedLastCurrency.base
        } else {
            networkService.fetchLatestCurrencies(base: nil)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        print(error.localizedDescription)
                    case .finished:
                        print("Success")
                    }
                    
                }) { [weak self] latestCurrencies in
                    var exchangeList = latestCurrencies.rates.compactMap({ ExchangeRate(targetCurrencyCode: $0.key, value: $0.value) })
                    exchangeList = exchangeList.sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
                    self?.baseCurrency = latestCurrencies.base
                    self?.initialExchangeRate = exchangeList
                    self?.exchangeRate = exchangeList
                    self?.localUserDefaults.set(value: Date(), for: .currenciesFetchedTimestamp)
                    let realmObject = LocalCurrencies()
                    realmObject.base = latestCurrencies.base
                    realmObject.timestamp = latestCurrencies.timestamp
                    realmObject.appendToList(rateDictionary: latestCurrencies.rates)
                    self?.realmStore.addOrUpdate(realmObject)
                }
                .store(in: &cancellables)
        }
        
    }
    
    func changeCurrentRate(for text: String) {
        guard !text.isEmpty else {
            exchangeRate = initialExchangeRate
            return
        }
        exchangeRate = initialExchangeRate.map { rate in
            let currVal = Double(text) ?? 1
            let val = currVal * rate.value
            
            return ExchangeRate(targetCurrencyCode: rate.targetCurrencyCode, value: val)
        }
    }
}
