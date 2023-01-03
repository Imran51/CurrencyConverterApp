//
//  CurrencyConverterAppTests.swift
//  CurrencyConverterAppTests
//
//  Created by Imran Sayeed on 12/28/22.
//

import XCTest
@testable import CurrencyConverterApp
import RealmSwift
import Realm
import Combine

final class CurrencyConverterAppTests: XCTestCase {
    var mockService: MockApiService?
    var mockRealm: MockRealmManager?
    private var cancellables = Set<AnyCancellable>()
    var sut: CurrencyExchangeRateViewModel?
    
    override func setUp() {
        super.setUp()
        mockService = MockApiService(apiClient: ApiClient())
        mockRealm = MockRealmManager()
        sut = CurrencyExchangeRateViewModel(networkService: mockService!, realmStore: mockRealm!, locaStore: MockUserDefaultsStore.shared)
    }
    
    override func tearDown() {
        super.tearDown()
        mockService = nil
        mockRealm = nil
        cancellables = []
    }
    
    func testCurrencyAPIRequestLayer() throws {
        let currencyPath: String = "https://openexchangerates.org/api/currencies.json?app_id=3bc55e298dd1415eb3c5f04e60ed6306"
        let latestjsonPath: String = "https://openexchangerates.org/api/latest.json?app_id=3bc55e298dd1415eb3c5f04e60ed6306"
        let latestjsonPathWithBase: String = "https://openexchangerates.org/api/latest.json?app_id=3bc55e298dd1415eb3c5f04e60ed6306&base=USD"
        let currencyLayerRequest = try CurrencyRequestLayer.currencies.asURLRequest()
        let currencyJSONRequest = try CurrencyRequestLayer.latestCurrencies(base: nil).asURLRequest()
        let currencyJSONRequestWithBasePath = try CurrencyRequestLayer.latestCurrencies(base: "USD").asURLRequest()
        XCTAssertTrue(currencyLayerRequest.httpMethod == "GET" )
        XCTAssertTrue(currencyLayerRequest.url?.absoluteString == currencyPath )
        XCTAssertTrue(currencyJSONRequest.url?.absoluteString == latestjsonPath)
        XCTAssertTrue(currencyJSONRequestWithBasePath.url?.absoluteString == latestjsonPathWithBase)
    }
    
    func testFetchLatestExchangeRate() throws {
        let response = try awaitPublisher(mockService!.fetchLatestCurrencies(currencyRequest: .latestCurrencies(base: "USD")))
        XCTAssertEqual(response.base, "USD")
        XCTAssertTrue(response.rates.isEmpty == false)
    }
    
    func testFetchCurrencyExchangeRateFromAPI() throws {
        let sut = try XCTUnwrap(sut)
        let lastFectingTime = Calendar.current.date(byAdding: .minute, value: -31, to: Date())!
        
        sut.currencyLocalPreference.set(value: lastFectingTime, for: .currencyExchangeRateFetched)
        sut.fetchLatestCurrencyRate()
        XCTAssertTrue(sut.isDataNeedsToRefresh(for: .currencyExchangeRateFetched))
        let exp = expectation(description: "Fetch latest exchangeRate")
        sut.exchangeRateList.sink(receiveValue: { rates in
            guard !rates.isEmpty else { return }
            XCTAssertTrue(rates.count > 0)
            exp.fulfill()
        }).store(in: &cancellables)
        
        wait(for: [exp], timeout: 10)
    }
    
    func testFetchCurrencyExchangeRateFromLocalStore() throws {
        let exchangeRates = [
            "AED": 3.672655,
            "BAM": 1.827622,
            "BBD": 2,
            "BDT": 102.905665,
            "JPY": 130.78866667,
            "USD": 1.000
        ].map { ExchangeRate(targetCurrencyCode: $0.key, value: $0.value) }
        let sut = try XCTUnwrap(sut)
        let baseStr = "USD"
        let exchangeRateObject = LocalCurrencyExchangeRate()
        exchangeRateObject.base = baseStr
        exchangeRateObject.timestamp = Date().timeIntervalSince1970
        exchangeRateObject.appendToList(rateDictionary: exchangeRates)
        
        let saved = mockRealm?.addOrUpdate(exchangeRateObject)
        XCTAssertNotNil(saved)
        
        let lastFectingTime = Calendar.current.date(byAdding: .minute, value: -10, to: Date())!
        
        sut.currencyLocalPreference.set(value: lastFectingTime, for: .currencyExchangeRateFetched)
        sut.fetchLatestCurrencyRate()
        print(sut.isDataNeedsToRefresh(for: .currencyExchangeRateFetched))
        XCTAssertTrue(sut.isDataNeedsToRefresh(for: .currencyExchangeRateFetched) == false)
        let exp = expectation(description: "Fetch latest exchangeRate")
        sut.exchangeRateList.sink(receiveValue: { rates in
            guard !rates.isEmpty else { return }
            
            XCTAssertTrue(rates.count > 0)
            XCTAssertEqual(rates, exchangeRates.sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode }))
            exp.fulfill()
        }).store(in: &cancellables)
        
        wait(for: [exp], timeout: 10)
    }
    
    func testCalculateCurrentExchangeRate() throws {
        let sut = try XCTUnwrap(sut)
        
        sut.exchangeRateMap = [
            "AED": 3.672655,
            "BAM": 1.827622,
            "BBD": 2,
            "BDT": 102.905665,
            "JPY": 130.78866667,
            "USD": 1.000
        ]
        
        sut.baseCurrency.value.from = "AED"
        sut.baseCurrency.value.to = "BDT"
        sut.calculateCurrentExchangeRate(for: "2")
        let exp = expectation(description: "Fetch latest exchangeRate")
        sut.exchangeRateList.sink(receiveValue: { rates in
            guard !rates.isEmpty else { return }
            XCTAssertTrue(rates.count > 0)
            exp.fulfill()
        }).store(in: &cancellables)
        
        wait(for: [exp], timeout: 10)
        XCTAssertTrue(sut.fromToExchangeRate.value.to == "56.039 BDT")
    }
    
    func testFetchSupportedCurrencies() throws {
        let response = try awaitPublisher(mockService!.getSupportedCurrencies(currencyRequest: .currencies))
        XCTAssertNotNil(response)
        XCTAssertEqual(response["BDT"]?.lowercased(), "Bangladeshi Taka".lowercased())
    }
    
    func testRealmManagerOperation() throws {
        let baseStr = "KLL"
        let exchangeRateObject = LocalCurrencyExchangeRate()
        exchangeRateObject.base = baseStr
        exchangeRateObject.timestamp = Date().timeIntervalSince1970
        exchangeRateObject.appendToList(rateDictionary: [ExchangeRate(targetCurrencyCode: baseStr, value: 201.33)])
        
        let saved = mockRealm?.addOrUpdate(exchangeRateObject)
        XCTAssertNotNil(saved)
        XCTAssertTrue(saved == true)
        
        let exchangeRate = mockRealm?.getLatestCurrencyExchangeRate()
        XCTAssertNotNil(exchangeRate)
        XCTAssertTrue(exchangeRate?.base == baseStr)
        let currentExchangeRateMap = try XCTUnwrap(exchangeRate?.rates)
        XCTAssertTrue(currentExchangeRateMap.count > 0)
        
        let exchangeRateByBase = mockRealm?.getLatestCurrencyExchangeRate(by: baseStr)
        XCTAssertNotNil(exchangeRateByBase)
        
        
        var currecyList = [Currency]()
        let currency = Currency()
        currency.code = "JPI"
        currency.name = "Japanese Yen"
        currecyList.append(currency)
        let currecyListSaved = mockRealm?.addorUpdate(currecyList)
        XCTAssertNotNil(currecyListSaved)
        XCTAssertTrue(currecyListSaved == true)
    }
}

extension XCTestCase {
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        var result: Result<T.Output, Error>?
        let expectation = self.expectation(description: "Awaiting publisher")
        
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                expectation.fulfill()
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }
                
                
            },
            receiveValue: { value in
                result = .success(value)
            }
        )
        
        waitForExpectations(timeout: timeout)
        cancellable.cancel()
        
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )
        
        return try unwrappedResult.get()
    }
}
