//
//  CurrencyRateViewModel.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import Combine

final class CurrencyExchangeRateViewModel {
    var exchangeRate = CurrentValueSubject<[ExchangeRate], Never>([])
    var dataFetchingError = CurrentValueSubject<NetworkError?, Never>(nil)
    var fromBaseCurrency = CurrentValueSubject<String, Never>("USD")
    var toBaseCurrency = CurrentValueSubject<String, Never>("BDT")
    var isProcessingData = CurrentValueSubject<Bool?, Never>(nil)
    var fromExchangeRate = CurrentValueSubject<String, Never>("1.000 USD")
    var toExchangeRate = CurrentValueSubject<String, Never>("102.229 BDT")
    
    private let networkService: CurrencyService
    private let realmStore: RealmStore
    private var cancellables = Set<AnyCancellable>()
    
    let currencyLocalPreference: CurrencyLocalStoreProtocol
    var exchangeRateMap = [String: Double]()
    
    init(networkService: CurrencyService, realmStore: RealmStore, locaStore: CurrencyLocalStoreProtocol) {
        self.networkService = networkService
        self.realmStore = realmStore
        self.currencyLocalPreference = locaStore
    }
    
    func fetchLatestCurrencyRate() {
        isProcessingData.send(true)
        if isDataNeedsToRefresh(for: .currencyExchangeRateFetched)  {
            fetchCurrency()
        } else {
            guard let fetchedLastCurrency = realmStore.getLatestCurrencyExchangeRate(by: fromBaseCurrency.value) else {
                dataFetchingError.send(.unknown("Couldn't found any data"))
                isProcessingData.send(false)
                return
            }
            setDisplableExchangeRate(for: fetchedLastCurrency, with: 1.0)
        }
    }
    
    func isDataNeedsToRefresh(for localStoreKey: DefaultsKey) -> Bool {
        guard let date: Date = currencyLocalPreference.get(for: localStoreKey)  else { return false }
        let is30MinCrossed = Date() > date + 30 * 60
        return is30MinCrossed
    }
    
    func exchangeCurrency(forAmount amount: Double = 1,fromBase: String, toBase: String) {
        isProcessingData.send(true)
        var fromBase = fromBase
        var toBase = toBase
        
        if fromBase == toBase  {
            fromBase = toBaseCurrency.value
            toBase = fromBaseCurrency.value
        }
        
        if let fetchedLastCurrency = realmStore.getLatestCurrencyExchangeRate(by: fromBase), isDataNeedsToRefresh(for: .currencyExchangeRateFetched) {
            setFromAndToBaseCurrency(from: fromBase, to: toBase)
            setDisplableExchangeRate(for: fetchedLastCurrency, with: amount)
            isProcessingData.send(false)
        } else {
            fetchCurrency(fromBase: fromBase, toBase: toBase, amount: amount)
        }
    }
    
    private func setDisplableExchangeRate(for localCurrencyExchangeRate: LocalCurrencyExchangeRate, with amount: Double) {
        localCurrencyExchangeRate.rates.forEach({ exchangeRateMap[$0.key] = $0.val })
        
        setFromAndToExchangeRate(for: amount)
        
        exchangeRate.send(
            exchangeValueBasedOn(baseCode: fromBaseCurrency.value)
                .sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
                .map { ExchangeRate(
                    targetCurrencyCode: $0.targetCurrencyCode,
                    value: $0.value*amount)
                }
        )
        
        isProcessingData.send(false)
    }
    
    private func fetchCurrency(fromBase: String? = nil, toBase: String? = nil, amount: Double = 1) {
        networkService
            .fetchLatestCurrencies(currencyRequest: CurrencyRequestLayer
                .latestCurrencies(base: nil))
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                self.isProcessingData.send(false)
                switch result {
                case .failure(let error):
                    self.dataFetchingError.send(error)
                case .finished:
                    print("Success")
                }
            }) { [weak self] latestCurrencies in
                guard let self = self else { return }
                self.exchangeRateMap = latestCurrencies.rates
                
                let exchangeRates = self.exchangeValueBasedOn(
                    baseCode: fromBase
                ).sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
                
                self.setFromAndToBaseCurrency(from: fromBase ?? latestCurrencies.base, to: toBase ?? self.toBaseCurrency.value)
                
                self.exchangeRate.send(exchangeRates.map { ExchangeRate(targetCurrencyCode: $0.targetCurrencyCode, value: $0.value * amount) })
                
                
                self.setFromAndToExchangeRate(for: amount)
                
                self.currencyLocalPreference.set(value: Date(), for: .currencyExchangeRateFetched)
                self.storeCurrency(
                    with: exchangeRates,
                    base: self.fromBaseCurrency.value,
                    timeStamp: latestCurrencies.timestamp
                )
            }
            .store(in: &cancellables)
    }
    
    private func exchangeValueBasedOn(baseCode: String?) -> [ExchangeRate] {
        guard let baseCode = baseCode, !baseCode.isEmpty else {
            return exchangeRateMap
                .compactMap({ ExchangeRate(targetCurrencyCode: $0.key, value: $0.value) })
        }
        guard let currRate = exchangeRateMap[baseCode] else {
            return  exchangeRateMap
                .compactMap({ ExchangeRate(targetCurrencyCode: $0.key, value: $0.value)})
        }
        let usdToCurrBaseRate: Double = 1/currRate
        return exchangeRateMap
            .compactMap { ExchangeRate(
                targetCurrencyCode: $0.key,
                value: usdToCurrBaseRate*$0.value)
            }
    }
    
    private func storeCurrency(with exchageRates: [ExchangeRate], base: String, timeStamp: Double) {
        let realmObject = LocalCurrencyExchangeRate()
        realmObject.base = base
        realmObject.timestamp = timeStamp
        realmObject.appendToList(rateDictionary: exchageRates)
        realmStore.addOrUpdate(realmObject)
    }
    
    func displayableExchangeRateStr(val: Double, isFromVal: Bool) -> String {
        String(format: "%.3f", val) + " " + (isFromVal ? fromBaseCurrency.value : toBaseCurrency.value)
    }
    
    func calculateCurrentExchangeRate(for input: String) {
        guard !input.isEmpty else {
            exchangeRate
                .send(exchangeValueBasedOn(baseCode: fromBaseCurrency.value)
                    .sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode }))
            resetFromAndToExchangeRate()
            return
        }
        
        var currentExchangeRate = [ExchangeRate]()
        let currVal = Double(input) ?? 1
        
        exchangeValueBasedOn(baseCode: fromBaseCurrency.value)
            .sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
            .forEach { rate in
                let currVal = Double(input) ?? 1
                let val = currVal * rate.value
                currentExchangeRate.append(ExchangeRate(targetCurrencyCode: rate.targetCurrencyCode, value: val))
            }
        
        setFromAndToExchangeRate(for: currVal)
        
        exchangeRate.send(currentExchangeRate)
    }
    
    func setFromAndToBaseCurrency(from: String, to: String){
        fromBaseCurrency.send(from)
        toBaseCurrency.send(to)
    }
    
    func resetFromAndToExchangeRate() {
        let fromBaseRate: Double = 1/(self.exchangeRateMap[self.fromBaseCurrency.value] ?? 1)
        let toBaseRate: Double = fromBaseRate*(self.exchangeRateMap[self.toBaseCurrency.value] ?? 1)
        let fromBaseCurrencyStr = displayableExchangeRateStr(val: 1, isFromVal: true)
        let toBaseCurrencyStr = displayableExchangeRateStr(val: toBaseRate, isFromVal: false)
        fromExchangeRate.send(fromBaseCurrencyStr)
        toExchangeRate.send(toBaseCurrencyStr)
    }
    
    func setFromAndToExchangeRate(for amount: Double) {
        let fromBaseRate: Double = 1/(self.exchangeRateMap[self.fromBaseCurrency.value] ?? 1)
        let toBaseRate: Double = fromBaseRate*(self.exchangeRateMap[self.toBaseCurrency.value] ?? 1)
        let fromBaseCurrencyStr = displayableExchangeRateStr(val: amount, isFromVal: true)
        let toBaseCurrencyStr = displayableExchangeRateStr(val: toBaseRate*amount, isFromVal: false)
        fromExchangeRate.send(fromBaseCurrencyStr)
        toExchangeRate.send(toBaseCurrencyStr)
    }
}
