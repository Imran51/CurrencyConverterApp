//
//  CurrencyRateViewModel.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import Combine

final class CurrencyExchangeRateViewModel {
    var exchangeRateList = CurrentValueSubject<[ExchangeRate], Never>([])
    var dataFetchingError = CurrentValueSubject<NetworkError?, Never>(nil)
    var baseCurrency = CurrentValueSubject<(from:String,to:String), Never>((from: "USD", to: "BDT"))
    var isProcessingData = CurrentValueSubject<Bool?, Never>(nil)
    var fromToExchangeRate = CurrentValueSubject<(from:String,to:String), Never>((from: "1.00 USD", to: "102.229 BDT"))
    
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
            guard let fetchedLastCurrency = realmStore.getLatestCurrencyExchangeRate(by: baseCurrency.value.from) else {
                dataFetchingError.send(.unknown("Couldn't found any data"))
                isProcessingData.send(false)
                return
            }
            setDisplableExchangeRate(for: fetchedLastCurrency, with: 1.0)
        }
    }
    
    func isDataNeedsToRefresh(for localStoreKey: DefaultsKey) -> Bool {
        guard let date: Date = currencyLocalPreference.get(for: localStoreKey)  else { return true }
        let is30MinCrossed = Date() > date + 30 * 60
        return is30MinCrossed
    }
    
    func exchangeCurrency(
        forAmount amount: Double = 1,
        fromBase: String,
        toBase: String
    ) {
        
        isProcessingData.send(true)
        var fromBase = fromBase
        var toBase = toBase
        
        if fromBase == toBase  {
            fromBase = baseCurrency.value.from
            toBase = baseCurrency.value.to
        }
        
        if let fetchedLastCurrency = realmStore.getLatestCurrencyExchangeRate(by: fromBase), isDataNeedsToRefresh(for: .currencyExchangeRateFetched) {
            setFromAndToBaseCurrency(from: fromBase, to: toBase)
            setDisplableExchangeRate(for: fetchedLastCurrency, with: amount)
            isProcessingData.send(false)
        } else {
            fetchCurrency(fromBase: fromBase, toBase: toBase, amount: amount)
        }
    }
    
    private func setDisplableExchangeRate(
        for localCurrencyExchangeRate: LocalCurrencyExchangeRate,
        with amount: Double
    ) {
        localCurrencyExchangeRate.rates.forEach({ exchangeRateMap[$0.key] = $0.val })
        
        setFromAndToExchangeRate(for: amount)
        
        exchangeRateList.send(
            exchangeValueBasedOn(baseCode: baseCurrency.value.from)
                .sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
                .map { ExchangeRate(
                    targetCurrencyCode: $0.targetCurrencyCode,
                    value: $0.value*amount)
                }
        )
        
        isProcessingData.send(false)
    }
    
    private func fetchCurrency(
        fromBase: String? = nil,
        toBase: String? = nil,
        amount: Double = 1
    ) {
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
                
                self.setFromAndToBaseCurrency(from: fromBase ?? latestCurrencies.base, to: toBase ?? self.baseCurrency.value.to)
                
                self.exchangeRateList.send(exchangeRates.map { ExchangeRate(targetCurrencyCode: $0.targetCurrencyCode, value: $0.value * amount) })
                
                
                self.setFromAndToExchangeRate(for: amount)
                
                self.currencyLocalPreference.set(value: Date(), for: .currencyExchangeRateFetched)
                self.storeCurrency(
                    with: exchangeRates,
                    base: self.baseCurrency.value.from,
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
        String(format: "%.3f", val) + " " + (isFromVal ? baseCurrency.value.from : baseCurrency.value.to)
    }
    
    func calculateCurrentExchangeRate(for input: String) {
        guard !input.isEmpty else {
            exchangeRateList
                .send(exchangeValueBasedOn(baseCode: baseCurrency.value.from)
                    .sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode }))
            resetFromAndToExchangeRate()
            return
        }
        
        var currentExchangeRate = [ExchangeRate]()
        let currVal = Double(input) ?? 1
        
        exchangeValueBasedOn(baseCode: baseCurrency.value.from)
            .sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
            .forEach { rate in
                let currVal = Double(input) ?? 1
                let val = currVal * rate.value
                currentExchangeRate.append(ExchangeRate(targetCurrencyCode: rate.targetCurrencyCode, value: val))
            }
        
        setFromAndToExchangeRate(for: currVal)
        
        exchangeRateList.send(currentExchangeRate)
    }
    
    func setFromAndToBaseCurrency(from: String, to: String){
        baseCurrency.send((from: from, to: to))
    }
    
    func resetFromAndToExchangeRate() {
        let fromBaseRate: Double = 1/(self.exchangeRateMap[self.baseCurrency.value.from] ?? 1)
        let toBaseRate: Double = fromBaseRate*(self.exchangeRateMap[self.baseCurrency.value.to] ?? 1)
        let fromBaseCurrencyStr = displayableExchangeRateStr(val: 1, isFromVal: true)
        let toBaseCurrencyStr = displayableExchangeRateStr(val: toBaseRate, isFromVal: false)
        fromToExchangeRate.send((from: fromBaseCurrencyStr, to:toBaseCurrencyStr))
    }
    
    func setFromAndToExchangeRate(for amount: Double) {
        let fromBaseRate: Double = 1/(self.exchangeRateMap[self.baseCurrency.value.from] ?? 1)
        let toBaseRate: Double = fromBaseRate*(self.exchangeRateMap[self.baseCurrency.value.to] ?? 1)
        let fromBaseCurrencyStr = displayableExchangeRateStr(val: amount, isFromVal: true)
        let toBaseCurrencyStr = displayableExchangeRateStr(val: toBaseRate*amount, isFromVal: false)
        fromToExchangeRate.send((from: fromBaseCurrencyStr, to:toBaseCurrencyStr))
    }
}
