//
//  Manager.swift
//  StudyBuddy
//
//  Created by Aishah A on 12/4/25.
//

import Alamofire
import SwiftUI

// MARK: - APIError
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(status: Int, message: String?)
    case decodingFailed
    case unknown(Error)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .requestFailed(let status, let message):
            if let message, !message.isEmpty { return message }
            return "Request failed with status code \(status)."
        case .decodingFailed:
            return "Failed to decode server response."
        case .unknown(let error):
            return error.localizedDescription
        case .noData:
            return "No data received from the server."
        }
    }
}

// MARK: - Flexible decoders for unknown schema
struct FlexibleID: Decodable {
    let string: String
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) {
            string = s
        } else if let i = try? c.decode(Int.self) {
            string = String(i)
        } else if let d = try? c.decode(Double.self) {
            string = String(d)
        } else {
            string = UUID().uuidString
        }
    }
}

struct SignupUser: Decodable {
    let id: String?
    let username: String?
    let email: String?
    
    // Try to decode either a top-level user object or a wrapped payload
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try decoding as { id, username, email, ... }
        if let flat = try? container.decode([String: AnyDecodable].self) {
            id = flat["id"]?.asString
            username = flat["username"]?.asString
            email = flat["email"]?.asString
            return
        }
        
        // Fallback to a keyed container to attempt id, username, email directly
        let keyed = try decoder.container(keyedBy: DynamicCodingKeys.self)
        if let idKey = DynamicCodingKeys(stringValue: "id"),
           let idString = try? keyed.decodeIfPresent(FlexibleID.self, forKey: idKey)?.string {
            id = idString
        } else {
            id = nil
        }
        if let uKey = DynamicCodingKeys(stringValue: "username") {
            username = try? keyed.decodeIfPresent(String.self, forKey: uKey)
        } else {
            username = nil
        }
        if let eKey = DynamicCodingKeys(stringValue: "email") {
            email = try? keyed.decodeIfPresent(String.self, forKey: eKey)
        } else {
            email = nil
        }
    }
}

// Helper to decode arbitrary JSON dictionaries in a tolerant way
struct AnyDecodable: Decodable {
    let value: Any
    
    var asString: String? {
        if let s = value as? String { return s }
        if let i = value as? Int { return String(i) }
        if let d = value as? Double { return String(d) }
        return nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(String.self) {
            value = v
        } else if let v = try? container.decode(Int.self) {
            value = v
        } else if let v = try? container.decode(Double.self) {
            value = v
        } else if let v = try? container.decode(Bool.self) {
            value = v
        } else if let v = try? container.decode([String: AnyDecodable].self) {
            value = v
        } else if let v = try? container.decode([AnyDecodable].self) {
            value = v
        } else {
            value = NSNull()
        }
    }
}

struct DynamicCodingKeys: CodingKey, Hashable {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

// MARK: - APIManager
final class APIManager {
    static let shared = APIManager()
    
    // Adjust this if you move servers
    private let baseURL = "http://34.21.81.90"
    
    private let session: Session
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private init() {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        
        self.session = Session(configuration: configuration)
        
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .useDefaultKeys
        self.encoder = enc
        
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .useDefaultKeys
        self.decoder = dec
    }
    
    // MARK: - Signup
    struct SignupRequest: Encodable {
        let username: String
        let email: String
        let password: String
    }
    
    struct SignupResult {
        let user: SignupUser?
        let rawData: Data?
        let statusCode: Int
    }
    
    func signUp(username: String, email: String, password: String, completion: @escaping (Result<SignupResult, APIError>) -> Void) {
        let path = "/signup/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let payload = SignupRequest(username: username, email: email, password: password)
        
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        // Encode body
        guard let body = try? encoder.encode(payload) else {
            completion(.failure(.decodingFailed))
            return
        }
        
        // Perform request
        session.request(
            url,
            method: .post,
            parameters: nil,
            encoding: JSONDataEncoding(data: body),
            headers: headers
        )
        .validate(statusCode: 200..<600) // We'll handle codes manually below
        .responseData { [weak self] response in
            guard let self else { return }
            
            let statusCode = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let data):
                if statusCode == 201 {
                    // Try to decode a tolerant user
                    let user = try? self.decoder.decode(SignupUser.self, from: data)
                    completion(.success(SignupResult(user: user, rawData: data, statusCode: statusCode)))
                } else {
                    // Attempt to decode error message from "error" or "message"
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: statusCode, message: message)))
                }
            case .failure(let afError):
                // Try to pull server-provided message if data is present
                if let data = response.data {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: statusCode, message: message ?? afError.localizedDescription)))
                } else {
                    completion(.failure(.unknown(afError)))
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func extractErrorMessage(from data: Data) -> String? {
        // Try a tolerant parse for "error" or "message"
        if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let msg = dict["error"] as? String { return msg }
            if let msg = dict["message"] as? String { return msg }
            if let detail = dict["detail"] as? String { return detail }
        }
        return nil
    }
}

// MARK: - JSONDataEncoding for Alamofire
struct JSONDataEncoding: ParameterEncoding {
    private let data: Data
    init(data: Data) { self.data = data }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
