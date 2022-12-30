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
    @Published var isProcessingData: Bool = false
    @Published var currencyFetchingError: NetworkError? = nil
    
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
    
    func fetchLatestCurrencyRate() {
        isProcessingData = true
        if let date: Date = localUserDefaults.get(for: .currenciesFetchedTimestamp), isDataNeedsToRefresh(for: date)  {
            guard let fetchedLastCurrency = realmStore.getLatestCurrencyExchangeRate(by: baseCurrency) else {
                isProcessingData = false
                return
            }
            setDisplableExchangeRate(for: fetchedLastCurrency, with: 1.0)
        } else {
            fetchCurrencyBy(base: nil)
        }
    }
    
    private func isDataNeedsToRefresh(for date: Date) -> Bool {
        Date() < date + 30 * 60
    }
    
    func exchangeCurrency(forAmount amount: Double = 1,andBase base: String) {
        isProcessingData = true
        if let fetchedLastCurrency = realmStore.getLatestCurrencyExchangeRate(by: base), let date: Date = localUserDefaults.get(for: .currenciesFetchedTimestamp), isDataNeedsToRefresh(for: date) {
            setDisplableExchangeRate(for: fetchedLastCurrency, with: amount)
            isProcessingData = false
        } else {
            fetchCurrencyBy(base: base, amount: amount)
        }
    }
    
    private func setDisplableExchangeRate(for localCurrencyExchangeRate: LocalCurrencyExchangeRate, with amount: Double) {
        baseCurrency = localCurrencyExchangeRate.base
        var exchangeRateMap = [String: Double]()
        localCurrencyExchangeRate.rates.forEach({ exchangeRateMap[$0.key] = $0.val })
        initialExchangeRate = exchangeValueBasedOn(baseCode: localCurrencyExchangeRate.base, rates: exchangeRateMap).sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
        exchangeRate = initialExchangeRate.map { ExchangeRate(targetCurrencyCode: $0.targetCurrencyCode, value: $0.value*amount) }
        isProcessingData = false
    }
    
    private func fetchCurrencyBy(base: String?, amount: Double = 1) {
        networkService.fetchLatestCurrencies(base: nil)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                self.isProcessingData = false
                switch result {
                case .failure(let error):
                    self.currencyFetchingError = error
                case .finished:
                    print("Success")
                }
            }) { [weak self] latestCurrencies in
                guard let self = self else { return }
                let exchangeRates = self.exchangeValueBasedOn(
                    baseCode: base,
                    rates: latestCurrencies.rates
                ).sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
                
                self.baseCurrency = base ?? latestCurrencies.base
                self.initialExchangeRate = exchangeRates
                self.exchangeRate = exchangeRates.map { ExchangeRate(targetCurrencyCode: $0.targetCurrencyCode, value: $0.value * amount) }
                
                self.localUserDefaults.set(value: Date(), for: .currenciesFetchedTimestamp)
                self.storeCurrency(with: exchangeRates, base: self.baseCurrency, timeStamp: latestCurrencies.timestamp)
            }
            .store(in: &cancellables)
    }
    
    private func exchangeValueBasedOn(baseCode: String?, rates: [String: Double]) -> [ExchangeRate] {
        guard let baseCode = baseCode, !baseCode.isEmpty else {
            return rates.compactMap({ ExchangeRate(targetCurrencyCode: $0.key, value: $0.value) })
        }
        guard let currRate = rates[baseCode] else {
            return  rates.compactMap({ ExchangeRate(targetCurrencyCode: $0.key, value: $0.value)})
        }
        let usdToCurrBaseRate: Double = 1/currRate
        return rates.compactMap { ExchangeRate(targetCurrencyCode: $0.key, value: usdToCurrBaseRate*$0.value) }
    }
    
    private func storeCurrency(with exchageRates: [ExchangeRate], base: String, timeStamp: Double) {
        let realmObject = LocalCurrencyExchangeRate()
        realmObject.base = base
        realmObject.timestamp = timeStamp
        realmObject.appendToList(rateDictionary: exchageRates)
        realmStore.addOrUpdate(realmObject)
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
