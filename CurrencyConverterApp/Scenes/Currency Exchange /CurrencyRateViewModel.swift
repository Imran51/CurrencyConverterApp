//
//  CurrencyRateViewModel.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import Combine

final class CurrencyRateViewModel {
    var exchangeRate = CurrentValueSubject<[ExchangeRate], NetworkError>([])
    var fromBaseCurrency = CurrentValueSubject<String, Never>("USD")
    var toBaseCurrency = CurrentValueSubject<String, Never>("BDT")
    var isProcessingData = CurrentValueSubject<Bool, Never>(false)
    var fromExchangeRate = CurrentValueSubject<String, Never>("1 USD")
    var toExchangeRate = CurrentValueSubject<String, Never>("102.35 BDT")
    
    private var initialExchangeRate: [ExchangeRate] = []
    private var initialFromExchangeRate: Double = 1.000
    private var initialToExchangeRate: Double = 102.350
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
        isProcessingData.send(true)
        if let date: Date = localUserDefaults.get(for: .currenciesFetchedTimestamp), isDataNeedsToRefresh(for: date)  {
            guard let fetchedLastCurrency = realmStore.getLatestCurrencyExchangeRate(by: fromBaseCurrency.value) else {
                isProcessingData.send(false)
                return
            }
            setDisplableExchangeRate(for: fetchedLastCurrency, with: 1.0)
        } else {
            fetchCurrencyBy()
        }
    }
    
    func isDataNeedsToRefresh(for date: Date) -> Bool {
        Date() < date + 30 * 60
    }
    
    func exchangeCurrency(forAmount amount: Double = 1,fromBase: String, toBase: String) {
        isProcessingData.send(true)
        if let fetchedLastCurrency = realmStore.getLatestCurrencyExchangeRate(by: fromBase), let date: Date = localUserDefaults.get(for: .currenciesFetchedTimestamp), isDataNeedsToRefresh(for: date) {
            setFromAndToBaseCurrency(from: fromBase, to: toBase)
            setDisplableExchangeRate(for: fetchedLastCurrency, with: amount)
            isProcessingData.send(false)
        } else {
            fetchCurrencyBy(fromBase: fromBase, toBase: toBase, amount: amount)
        }
    }
    
    private func setDisplableExchangeRate(for localCurrencyExchangeRate: LocalCurrencyExchangeRate, with amount: Double) {
        var exchangeRateMap = [String: Double]()
        localCurrencyExchangeRate.rates.forEach({ exchangeRateMap[$0.key] = $0.val })
        
        setFromAndToExchangeRate(fromRate: (exchangeRateMap[fromBaseCurrency.value] ?? 1.000)*amount, toRate: (exchangeRateMap[toBaseCurrency.value] ?? 1.000)*amount)
        initialExchangeRate = exchangeValueBasedOn(baseCode: "USD", rates: exchangeRateMap).sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
        let exr = exchangeValueBasedOn(baseCode: localCurrencyExchangeRate.base, rates: exchangeRateMap).sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
        exchangeRate.send(exr.map { ExchangeRate(targetCurrencyCode: $0.targetCurrencyCode, value: $0.value*amount) })
        isProcessingData.send(false)
    }
    
    private func fetchCurrencyBy(fromBase: String? = nil, toBase: String? = nil, amount: Double = 1) {
        networkService.fetchLatestCurrencies(currencyRequest: CurrencyRequestLayer.latestCurrencies(base: nil))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }
                self.isProcessingData.send(false)
                switch result {
                case .failure(let error):
                    self.exchangeRate.send(completion: .failure(error))
                    self.exchangeRate.send(completion: .finished)
                case .finished:
                    print("Success")
                }
            }) { [weak self] latestCurrencies in
                guard let self = self else { return }
                let exchangeRates = self.exchangeValueBasedOn(
                    baseCode: fromBase,
                    rates: latestCurrencies.rates
                ).sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
                
                self.setFromAndToBaseCurrency(from: fromBase ?? latestCurrencies.base, to: toBase ?? self.toBaseCurrency.value)
                self.initialExchangeRate = exchangeRates
                
                self.exchangeRate.send(exchangeRates.map { ExchangeRate(targetCurrencyCode: $0.targetCurrencyCode, value: $0.value * amount) })
                self.exchangeRate.send(completion: .finished)
                
                let fromVal: Double = latestCurrencies.rates[self.fromBaseCurrency.value] ?? 1.00
                let toVal: Double = latestCurrencies.rates[self.toBaseCurrency.value] ?? 102.33
                self.initialFromExchangeRate = fromVal
                self.initialToExchangeRate = toVal
                
                self.setFromAndToExchangeRate(fromRate: (fromVal)*amount, toRate: (toVal)*amount)
                
                self.localUserDefaults.set(value: Date(), for: .currenciesFetchedTimestamp)
                self.storeCurrency(with: exchangeRates, base: self.fromBaseCurrency.value, timeStamp: latestCurrencies.timestamp)
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
    
    func displayableExchangeRateStr(val: Double, isFromVal: Bool) -> String {
        String(format: "%.3f", val) + " " + (isFromVal ? fromBaseCurrency.value : toBaseCurrency.value)
    }
    
    func changeCurrentRate(for text: String) {
        guard !text.isEmpty else {
            exchangeRate.send(initialExchangeRate)
            resetFromAndToExchangeRate()
            return
        }
        var currentExchangeRate = [ExchangeRate]()
        var fromRate: Double = 1
        var toRate: Double = 1
        var exchangeRateMap = [String: Double]()
        initialExchangeRate.forEach({ exchangeRateMap[$0.targetCurrencyCode] = $0.value })
        let exr = exchangeValueBasedOn(baseCode: fromBaseCurrency.value, rates: exchangeRateMap).sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
        exr.forEach { rate in
            let currVal = Double(text) ?? 1
            let val = currVal * rate.value
            if rate.targetCurrencyCode == fromBaseCurrency.value {
                fromRate = val
            } else if rate.targetCurrencyCode == toBaseCurrency.value {
                toRate = val
            }
            currentExchangeRate.append(ExchangeRate(targetCurrencyCode: rate.targetCurrencyCode, value: val))
        }
        setFromAndToExchangeRate(fromRate: fromRate, toRate: toRate)
        
        exchangeRate.send(currentExchangeRate)
    }
    
    func setFromAndToBaseCurrency(from: String, to: String){
        fromBaseCurrency.send(from)
        toBaseCurrency.send(to)
    }
    
    func resetFromAndToExchangeRate() {
        let fromBaseCurrencyStr = "\(initialFromExchangeRate) "+self.fromBaseCurrency.value
        let toBaseCurrencyStr = "\(initialToExchangeRate) "+self.toBaseCurrency.value
        fromExchangeRate.send(fromBaseCurrencyStr)
        toExchangeRate.send(toBaseCurrencyStr)
    }
    
    func setFromAndToExchangeRate(fromRate: Double, toRate: Double) {
        let fromBaseCurrencyStr = displayableExchangeRateStr(val: fromRate, isFromVal: true)
        let toBaseCurrencyStr = displayableExchangeRateStr(val: toRate, isFromVal: false)
        fromExchangeRate.send(fromBaseCurrencyStr)
        toExchangeRate.send(toBaseCurrencyStr)
    }
}
