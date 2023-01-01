//
//  CurrencyConverterAppTests.swift
//  CurrencyConverterAppTests
//
//  Created by Imran Sayeed on 12/28/22.
//

import XCTest
@testable import CurrencyConverterApp
import RealmSwift
//@testable import Realm
import Realm
import Combine

final class CurrencyConverterAppTests: XCTestCase {
    var mockService: MockApiService?
    var mockRealm: RealmManager?
    private var cancellables = Set<AnyCancellable>()
    var sut: CurrencyRateViewModel?
    
    override func setUp() {
        super.setUp()
        mockService = MockApiService(apiClient: ApiClient())
        mockRealm = RealmManager(defaultConfig: Realm.Configuration(inMemoryIdentifier: "MockRelamManager"))
        sut = CurrencyRateViewModel(networkService: mockService!, realmStore: mockRealm!, locaStore: CurrencyLocalStore.shared)
    }
    
    override func tearDown() {
        super.tearDown()
        mockService = nil
        mockRealm = nil
        cancellables = []
    }
    
    func testCurrencyRequestLayer() throws {
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
    
    func testFetchLatestCurrencies() throws {
        let response = try awaitPublisher(mockService!.fetchLatestCurrencies(currencyRequest: .latestCurrencies(base: "USD")))
        XCTAssertEqual(response.base, "USD")
        XCTAssertTrue(response.rates.isEmpty == false)
    }
    
    func testFetchAvailableCurrencies() throws {
        let response = try awaitPublisher(mockService!.getCurrencies(currencyRequest: .currencies))
        XCTAssertNotNil(response)
        XCTAssertEqual(response["BDT"]?.lowercased(), "Bangladeshi Taka".lowercased())
    }
    
    func testRealmAddUpdate() throws {
        let baseStr = "KLL"
        let exchangeRateObject = CurrencyConverterApp.LocalCurrencyExchangeRate()
        exchangeRateObject.base = baseStr
        exchangeRateObject.timestamp = Date().timeIntervalSince1970
        exchangeRateObject.appendToList(rateDictionary: [CurrencyConverterApp.ExchangeRate(targetCurrencyCode: baseStr, value: 201.33)])

        let saved = mockRealm?.addOrUpdate(exchangeRateObject)
        XCTAssertNotNil(saved)
        XCTAssertTrue(saved == true)
//        let exchangeRate = mockRealm?.getLatestCurrencyExchangeRate()
//        XCTAssertNotNil(exchangeRate)
//        XCTAssertTrue(exchangeRate?.base == baseStr)
        
//        let exchangeRateByBase = mockRealm?.getLatestCurrencyExchangeRate(by: baseStr)
//        XCTAssertNotNil(exchangeRateByBase)
//        XCTAssertTrue(exchangeRateByBase!.rates.isEmpty == false)
        var currecyList = [Currency]()
        let currency = Currency()
        currency.code = "JPI"
        currency.name = "Japanese Yen"
        currecyList.append(currency)
        let currecyListSaved = mockRealm?.addorUpdate(currecyList)
        XCTAssertNotNil(currecyListSaved)
        XCTAssertTrue(currecyListSaved == true)
    }
    
//    func testRealmReadOperation() {
//        let baseStr = "KLL"
//        
//    }
    
    
    func testCurrencyRateViewModel() throws {
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut?.baseCurrency)
//        sut!.fetchLatestCurrencyRate()
        
//        let isProcessingData = try awaitPublisher(sut!.$isProcessingData)
//        XCTAssertNotNil(isProcessingData)
//        XCTAssertTrue(isProcessingData == true)
//        let error = try awaitPublisher(sut!.$currencyFetchingError)
//        XCTAssertNil(error)
    }
    
    
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        // This time, we use Swift's Result type to keep track
        // of the result of our Combine pipeline:
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
        
        // Just like before, we await the expectation that we
        // created at the top of our test, and once done, we
        // also cancel our cancellable to avoid getting any
        // unused variable warnings:
        waitForExpectations(timeout: timeout)
        cancellable.cancel()
        
        // Here we pass the original file and line number that
        // our utility was called at, to tell XCTest to report
        // any encountered errors at that original call site:
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )
        
        return try unwrappedResult.get()
    }
}

struct MockApiService: CurrencyService {
    
    let apiClient: ApiClient
    func fetchLatestCurrencies(currencyRequest: CurrencyRequestLayer) -> AnyPublisher<LatestCurrencyExchangeRateInfo, NetworkError> {
        guard let _ = try? currencyRequest.asURLRequest() else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return Just(LatestCurrencyExchangeRateInfo(timestamp: Date().timeIntervalSince1970, base: "BDT", rates: ["USD":0.112])).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
    }
    
    func getCurrencies(currencyRequest: CurrencyRequestLayer) -> AnyPublisher<[String : String], NetworkError> {
        guard let _ = try? currencyRequest.asURLRequest() else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return Just(["BDT": "Bangladeshi taka", "JPY": "Japanese Yen"]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
    }
}
