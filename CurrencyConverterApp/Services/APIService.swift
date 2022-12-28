//
//  APIService.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import Combine

protocol CurrencyService {
    func fetchLatestCurrencies() -> AnyPublisher<LatestCurrencies, NetworkError>
    func getCurrencies() -> AnyPublisher<[String:String], NetworkError>
}

struct ErrorInfo: Decodable {
    let error: Bool
    let status: Int
    let message: String
    let description: String
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

protocol DataRequest {
    var method: HTTPMethod { get }
    var path: String { get }
    var headers: [String : String] { get }
    var queryItems: [URLQueryItem] { get }
    
    func asURLRequest() throws -> URLRequest
}

extension DataRequest {
    var headers: [String : String] {
        [:]
    }
    
    var queryItems: [URLQueryItem] {
        []
    }
}

enum CurrencyRequestLayer: DataRequest {
    private enum Constants {
        static let baseURLPath = "https://openexchangerates.org/api"
        static let apiId = "3bc55e298dd1415eb3c5f04e60ed6306"
    }
    
    case currencies
    case latestCurrencies
    
    var queryItems: [URLQueryItem] {
        switch self {
        case .currencies, .latestCurrencies:
            return [URLQueryItem(name: "app_id", value: Constants.apiId)]
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .currencies, .latestCurrencies:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .currencies:
            return "currencies.json"
        case .latestCurrencies:
            return "latest.json"
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        guard let baseUrl = URL(string: Constants.baseURLPath), var components = URLComponents(url: baseUrl.appendingPathComponent(path), resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        return request
    }
    
}

enum NetworkError: Error {
    case invalidResponse(String)
    case invalidURL
    case decodingError
    case connectionError
    case unknown(String)
    
    var message: String {
        switch self {
        case .invalidResponse(let errorDetail):
            return errorDetail
        case .decodingError:
            return "Couldn't decode properly."
        case .connectionError:
            return "Please check your internet connection"
        case .unknown(let error):
            return error.description
        case .invalidURL:
            return "URL is invalid"
        }
    }
}

class APIServiceImpl: CurrencyService {
    func fetchLatestCurrencies() -> AnyPublisher<LatestCurrencies, NetworkError> {
        request(urlRequest: CurrencyRequestLayer.latestCurrencies)
    }
    
    func getCurrencies() -> AnyPublisher<[String:String], NetworkError> {
        request(urlRequest: CurrencyRequestLayer.currencies)
    }
    
    private func request<T: Decodable>(urlRequest: DataRequest) -> AnyPublisher<T, NetworkError> {
        guard let urlRequest = try? urlRequest.asURLRequest() else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        print(urlRequest)
        return URLSession.shared
            .dataTaskPublisher(for: urlRequest)
            .tryMap { response in
                guard let httpResponse = response.response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                    throw NetworkError.invalidResponse(response.response.debugDescription)
                }
                return response.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                switch error {
                case is DecodingError:
                    return NetworkError.decodingError
                default:
                    return NetworkError.invalidResponse(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
}
