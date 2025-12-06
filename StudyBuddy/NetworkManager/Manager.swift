import Alamofire
import SwiftUI

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

struct AnyDecodable: Decodable {
    let value: Any
    
    var asString: String? {
        if let s = value as? String { return s }
        if let i = value as? Int { return String(i) }
        if let d = value as? Double { return String(d) }
        return nil
    }
    var asDict: [String: AnyDecodable]? { value as? [String: AnyDecodable] }
    
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

struct SignupUser: Decodable {
    let id: String?
    let username: String?
    let email: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let flat = try? container.decode([String: AnyDecodable].self) {
            id = flat["id"]?.asString ?? (flat["user"]?.asDict?["id"]?.asString)
            username = flat["username"]?.asString ?? flat["user"]?.asDict?["username"]?.asString
            email = flat["email"]?.asString ?? flat["user"]?.asDict?["email"]?.asString
            return
        }
        let keyed = try decoder.container(keyedBy: DynamicCodingKeys.self)
        if let idKey = DynamicCodingKeys(stringValue: "id"),
           let idString = try? keyed.decodeIfPresent(FlexibleID.self, forKey: idKey)?.string {
            id = idString
        } else if let userKey = DynamicCodingKeys(stringValue: "user"),
                  let nested = try? keyed.decodeIfPresent([String: AnyDecodable].self, forKey: userKey) {
            id = nested["id"]?.asString
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

final class APIManager {
    static let shared = APIManager()
    
    private let baseURL = "http://34.21.81.90/"
    
    private let session: Session
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private init() {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.httpCookieStorage = .shared
        
        self.session = Session(configuration: configuration)
        
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .useDefaultKeys
        self.encoder = enc
        
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .useDefaultKeys
        self.decoder = dec
    }
    
    struct SignupRequest: Encodable {
        let username: String
        let email: String
        let password: String
    }
    struct SignupResult {
        let userId: Int?
        let user: SignupUser?
        let rawData: Data?
        let statusCode: Int
    }
    
    func signUp(username: String, email: String, password: String, completion: @escaping (Result<SignupResult, APIError>) -> Void) {
        let path = "signup/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let payload = SignupRequest(username: username, email: email, password: password)
        guard let body = try? encoder.encode(payload) else {
            completion(.failure(.decodingFailed))
            return
        }
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        session.request(
            url,
            method: .post,
            parameters: nil,
            encoding: JSONDataEncoding(data: body),
            headers: headers
        )
        .validate(statusCode: 200..<600)
        .responseData { [weak self] response in
            guard let self else { return }
            let statusCode = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let data):
                if statusCode == 201 {
                    let userId = self.extractTopLevelID(from: data)
                    let user = try? self.decoder.decode(SignupUser.self, from: data)
                    completion(.success(SignupResult(userId: userId, user: user, rawData: data, statusCode: statusCode)))
                } else {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: statusCode, message: message)))
                }
            case .failure(let afError):
                if let data = response.data {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: statusCode, message: message ?? afError.localizedDescription)))
                } else {
                    completion(.failure(.unknown(afError)))
                }
            }
        }
    }
    
    struct LoginUser: Decodable {
        let email: String?
        let id: Int?
        let username: String?
        let profile: AnyDecodable?
    }
    struct LoginResult {
        let userId: Int?
        let user: LoginUser?
        let rawData: Data?
        let statusCode: Int
    }
    
    func login(username: String, password: String, completion: @escaping (Result<LoginResult, APIError>) -> Void) {
        let path = "login/"
        guard var components = URLComponents(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }
        components.queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password)
        ]
        guard let url = components.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        session.request(url, method: .get)
            .validate(statusCode: 200..<600)
            .responseData { [weak self] response in
                guard let self else { return }
                let status = response.response?.statusCode ?? -1
                switch response.result {
                case .success(let data):
                    if (200...299).contains(status) {
                        let userId = self.extractTopLevelID(from: data)
                        let user = try? self.decoder.decode(LoginUser.self, from: data)
                        let resolvedId: Int? = {
                            if let id = userId { return id }
                            if let id = user?.id { return id }
                            return nil
                        }()
                        completion(.success(LoginResult(userId: resolvedId, user: user, rawData: data, statusCode: status)))
                    } else {
                        let message = self.extractErrorMessage(from: data)
                        completion(.failure(.requestFailed(status: status, message: message)))
                    }
                case .failure(let afError):
                    if let data = response.data {
                        let message = self.extractErrorMessage(from: data)
                        completion(.failure(.requestFailed(status: status, message: message ?? afError.localizedDescription)))
                    } else {
                        completion(.failure(.unknown(afError)))
                    }
                }
            }
    }
    
    struct UserProfileRef: Decodable {
        let has_profile_image_blob: Bool?
        let id: Int?
        let profile_image_mime: String?
        let study_area_id: Int?
        let user_id: Int?
    }
    
    struct UserDTO: Decodable {
        let email: String?
        let id: Int?
        let profile: UserProfileRef?
        let username: String?
    }
    
    // UPDATED: college_id is now optional
    struct CreateProfileRequest: Encodable {
        let user_id: Int
        let study_area_id: Int
        let course_ids: [Int]
        let study_time_ids: [Int]
        let major_ids: [Int]
        let name: String
        let college_id: Int?
    }
    
    struct ProfileDTO: Decodable {
        let id: Int?
        let user_id: Int?
        let study_area_id: Int?
        let course_ids: [Int]?
        let study_time_ids: [Int]?
        let major_ids: [Int]?
        let name: String?
        let college_id: Int?
    }
    
    struct CreateProfileResult {
        let profile: ProfileDTO?
        let rawData: Data?
        let statusCode: Int
    }
    
    func createProfile(_ request: CreateProfileRequest, completion: @escaping (Result<CreateProfileResult, APIError>) -> Void) {
        let path = "profiles/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }
        
        guard let body = try? encoder.encode(request) else {
            completion(.failure(.decodingFailed))
            return
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        session.request(
            url,
            method: .post,
            parameters: nil,
            encoding: JSONDataEncoding(data: body),
            headers: headers
        )
        .validate(statusCode: 200..<600)
        .responseData { [weak self] response in
            guard let self else { return }
            let status = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let data):
                if (200...299).contains(status) {
                    let profile = try? self.decoder.decode(ProfileDTO.self, from: data)
                    completion(.success(CreateProfileResult(profile: profile, rawData: data, statusCode: status)))
                } else {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message)))
                }
            case .failure(let afError):
                if let data = response.data {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message ?? afError.localizedDescription)))
                } else {
                    completion(.failure(.unknown(afError)))
                }
            }
        }
    }
    
    struct RichProfileDTO: Decodable {
        struct Course: Decodable { let id: Int?; let code: String? }
        struct Major: Decodable { let id: Int?; let name: String? }
        struct Minor: Decodable { let id: Int?; let name: String? }
        struct StudyArea: Decodable { let id: Int?; let name: String? }
        struct StudyTime: Decodable { let id: Int?; let name: String? }
        struct College: Decodable { let id: Int?; let name: String? }
        
        let id: Int?
        let user_id: Int?
        let name: String?
        let courses: [Course]?
        let majors: [Major]?
        let minors: [Minor]?
        let study_area: StudyArea?
        let study_times: [StudyTime]?
        let college: College?
        
        let has_profile_image_blob: Bool?
        let profile_image_blob_base64: String?
        let profile_image_blob_url: String?
        let profile_image_mime: String?
    }
    
    func getProfile(id: Int, completion: @escaping (Result<RichProfileDTO, APIError>) -> Void) {
        let path = "profiles/\(id)"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL)); return
        }
        
        session.request(url, method: .get)
            .validate(statusCode: 200..<600)
            .responseData { [weak self] response in
                guard let self else { return }
                let status = response.response?.statusCode ?? -1
                switch response.result {
                case .success(let data):
                    if status == 200 {
                        if let dto = try? self.decoder.decode(RichProfileDTO.self, from: data) {
                            completion(.success(dto))
                        } else {
                            completion(.failure(.decodingFailed))
                        }
                    } else {
                        let message = self.extractErrorMessage(from: data)
                        completion(.failure(.requestFailed(status: status, message: message)))
                    }
                case .failure(let afError):
                    completion(.failure(.unknown(afError)))
                }
            }
    }
    
    func getAllProfiles(completion: @escaping (Result<[RichProfileDTO], APIError>) -> Void) {
        let path = "profiles/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }

        session.request(url, method: .get)
            .validate(statusCode: 200..<600)
            .responseData { [weak self] response in
                guard let self else { return }
                let status = response.response?.statusCode ?? -1

                switch response.result {
                case .success(let data):
                    if status == 200 {
                        if let arr = try? self.decoder.decode([RichProfileDTO].self, from: data) {
                            completion(.success(arr))
                        } else if let single = try? self.decoder.decode(RichProfileDTO.self, from: data) {
                            completion(.success([single]))
                        } else {
                            completion(.failure(.decodingFailed))
                        }
                    } else {
                        let message = self.extractErrorMessage(from: data)
                        completion(.failure(.requestFailed(status: status, message: message)))
                    }

                case .failure(let afError):
                    completion(.failure(.unknown(afError)))
                }
            }
    }
    
    struct UpdateProfileRequest: Encodable {
        let study_area_id: Int?
        let course_ids: [Int]?
        let study_time_ids: [Int]?
        let major_ids: [Int]?
    }
    
    struct UpdateProfileResult {
        let rawData: Data?
        let statusCode: Int
    }
    
    func updateProfile(id: Int, request: UpdateProfileRequest, completion: @escaping (Result<UpdateProfileResult, APIError>) -> Void) {
        let path = "profiles/\(id)/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }
        
        guard let body = try? encoder.encode(request) else {
            completion(.failure(.decodingFailed))
            return
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        session.request(
            url,
            method: .put,
            parameters: nil,
            encoding: JSONDataEncoding(data: body),
            headers: headers
        )
        .validate(statusCode: 200..<600)
        .responseData { response in
            let status = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let data):
                if (200...299).contains(status) {
                    completion(.success(UpdateProfileResult(rawData: data, statusCode: status)))
                } else {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message)))
                }
            case .failure(let afError):
                if let data = response.data {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message ?? afError.localizedDescription)))
                } else {
                    completion(.failure(.unknown(afError)))
                }
            }
        }
    }
    
    struct CourseDTO: Decodable {
        let id: Int?
        let code: String?
    }
    struct CreateCourseRequest: Encodable {
        let code: String
    }
    struct CreateCourseResult {
        let course: CourseDTO?
        let rawData: Data?
        let statusCode: Int
    }
    
    func createCourse(code: String, completion: @escaping (Result<CreateCourseResult, APIError>) -> Void) {
        let path = "courses/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }
        let payload = CreateCourseRequest(code: code)
        guard let body = try? encoder.encode(payload) else {
            completion(.failure(.decodingFailed))
            return
        }
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        session.request(
            url,
            method: .post,
            parameters: nil,
            encoding: JSONDataEncoding(data: body),
            headers: headers
        )
        .validate(statusCode: 200..<600)
        .responseData { [weak self] response in
            guard let self else { return }
            let status = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let data):
                if (200...299).contains(status) {
                    let course = try? self.decoder.decode(CourseDTO.self, from: data)
                    completion(.success(CreateCourseResult(course: course, rawData: data, statusCode: status)))
                } else {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message)))
                }
            case .failure(let afError):
                if let data = response.data {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message ?? afError.localizedDescription)))
                } else {
                    completion(.failure(.unknown(afError)))
                }
            }
        }
    }
    
    func getCourses(completion: @escaping (Result<[CourseDTO], APIError>) -> Void) {
        let path = "courses/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL)); return
        }
        session.request(url, method: .get)
            .validate(statusCode: 200..<600)
            .responseData { [weak self] response in
                guard let self else { return }
                let status = response.response?.statusCode ?? -1
                switch response.result {
                case .success(let data):
                    if (200...299).contains(status) {
                        if let arr = try? self.decoder.decode([CourseDTO].self, from: data) {
                            completion(.success(arr))
                        } else {
                            completion(.failure(.decodingFailed))
                        }
                    } else {
                        let message = self.extractErrorMessage(from: data)
                        completion(.failure(.requestFailed(status: status, message: message)))
                    }
                case .failure(let afError):
                    completion(.failure(.unknown(afError)))
                }
            }
    }
    
    struct MajorDTO: Decodable {
        let id: Int?
        let name: String?
    }
    struct CreateMajorRequest: Encodable {
        let name: String
    }
    struct CreateMajorResult {
        let major: MajorDTO?
        let rawData: Data?
        let statusCode: Int
    }
    
    func createMajor(name: String, completion: @escaping (Result<CreateMajorResult, APIError>) -> Void) {
        let path = "majors/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL)); return
        }
        let payload = CreateMajorRequest(name: name)
        guard let body = try? encoder.encode(payload) else {
            completion(.failure(.decodingFailed)); return
        }
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        session.request(
            url,
            method: .post,
            parameters: nil,
            encoding: JSONDataEncoding(data: body),
            headers: headers
        )
        .validate(statusCode: 200..<600)
        .responseData { [weak self] response in
            guard let self else { return }
            let status = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let data):
                if (200...299).contains(status) {
                    let major = try? self.decoder.decode(MajorDTO.self, from: data)
                    completion(.success(CreateMajorResult(major: major, rawData: data, statusCode: status)))
                } else {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message)))
                }
            case .failure(let afError):
                if let data = response.data {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message ?? afError.localizedDescription)))
                } else {
                    completion(.failure(.unknown(afError)))
                }
            }
        }
    }
    
    func getMajors(completion: @escaping (Result<[MajorDTO], APIError>) -> Void) {
        let path = "majors/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL)); return
        }
        session.request(url, method: .get)
            .validate(statusCode: 200..<600)
            .responseData { [weak self] response in
                guard let self else { return }
                let status = response.response?.statusCode ?? -1
                switch response.result {
                case .success(let data):
                    if (200...299).contains(status) {
                        if let arr = try? self.decoder.decode([MajorDTO].self, from: data) {
                            completion(.success(arr))
                        } else {
                            completion(.failure(.decodingFailed))
                        }
                    } else {
                        let message = self.extractErrorMessage(from: data)
                        completion(.failure(.requestFailed(status: status, message: message)))
                    }
                case .failure(let afError):
                    completion(.failure(.unknown(afError)))
                }
            }
    }
    
    // MARK: - Colleges API
    struct CollegeDTO: Decodable {
        let id: Int?
        let name: String?
    }
    struct CreateCollegeRequest: Encodable {
        let name: String
    }
    struct CreateCollegeResult {
        let college: CollegeDTO?
        let rawData: Data?
        let statusCode: Int
    }
    
    func createCollege(name: String, completion: @escaping (Result<CreateCollegeResult, APIError>) -> Void) {
        let path = "colleges/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL)); return
        }
        let payload = CreateCollegeRequest(name: name)
        guard let body = try? encoder.encode(payload) else {
            completion(.failure(.decodingFailed)); return
        }
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        session.request(
            url,
            method: .post,
            parameters: nil,
            encoding: JSONDataEncoding(data: body),
            headers: headers
        )
        .validate(statusCode: 200..<600)
        .responseData { [weak self] response in
            guard let self else { return }
            let status = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let data):
                if (200...299).contains(status) {
                    let college = try? self.decoder.decode(CollegeDTO.self, from: data)
                    completion(.success(CreateCollegeResult(college: college, rawData: data, statusCode: status)))
                } else {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message)))
                }
            case .failure(let afError):
                if let data = response.data {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: status, message: message ?? afError.localizedDescription)))
                } else {
                    completion(.failure(.unknown(afError)))
                }
            }
        }
    }
    
    func getColleges(completion: @escaping (Result<[CollegeDTO], APIError>) -> Void) {
        let path = "colleges/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL)); return
        }
        session.request(url, method: .get)
            .validate(statusCode: 200..<600)
            .responseData { [weak self] response in
                guard let self else { return }
                let status = response.response?.statusCode ?? -1
                switch response.result {
                case .success(let data):
                    if (200...299).contains(status) {
                        if let arr = try? self.decoder.decode([CollegeDTO].self, from: data) {
                            completion(.success(arr))
                        } else if let single = try? self.decoder.decode(CollegeDTO.self, from: data) {
                            completion(.success([single]))
                        } else {
                            completion(.failure(.decodingFailed))
                        }
                    } else {
                        let message = self.extractErrorMessage(from: data)
                        completion(.failure(.requestFailed(status: status, message: message)))
                    }
                case .failure(let afError):
                    completion(.failure(.unknown(afError)))
                }
            }
    }
    
    struct UserMatchDTO: Decodable {
        let match_id: Int?
        let matched_user: UserDTO?
        let matched_on: String?
    }
    
    func getUserMatches(userId: Int, completion: @escaping (Result<[UserMatchDTO], APIError>) -> Void) {
        let path = "users/\(userId)/matches/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }
        
        session.request(url, method: .get)
            .validate(statusCode: 200..<600)
            .responseData { [weak self] response in
                guard let self else { return }
                let status = response.response?.statusCode ?? -1
                switch response.result {
                case .success(let data):
                    if (200...299).contains(status) {
                        if let arr = try? self.decoder.decode([UserMatchDTO].self, from: data) {
                            completion(.success(arr))
                        } else {
                            completion(.failure(.decodingFailed))
                        }
                    } else {
                        let message = self.extractErrorMessage(from: data)
                        completion(.failure(.requestFailed(status: status, message: message)))
                    }
                case .failure(let afError):
                    completion(.failure(.unknown(afError)))
                }
            }
    }
    
    // NEW: Get a user by id (with trailing slash)
    func getUser(id: Int, completion: @escaping (Result<UserDTO, APIError>) -> Void) {
        let path = "users/\(id)/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }
        
        session.request(url, method: .get)
            .validate(statusCode: 200..<600)
            .responseData { [weak self] response in
                guard let self else { return }
                let status = response.response?.statusCode ?? -1
                switch response.result {
                case .success(let data):
                    if status == 200 {
                        if let user = try? self.decoder.decode(UserDTO.self, from: data) {
                            completion(.success(user))
                        } else {
                            completion(.failure(.decodingFailed))
                        }
                    } else {
                        let message = self.extractErrorMessage(from: data)
                        completion(.failure(.requestFailed(status: status, message: message)))
                    }
                case .failure(let afError):
                    completion(.failure(.unknown(afError)))
                }
            }
    }
    
    // MARK: - Swipe APIs
    struct SwipeRequest: Encodable {
        let swiper_id: Int
        let target_id: Int
        let status: String
    }
    struct SwipeResponse: Decodable {
        let match_found: Bool?
        let new_match_id: Int?
    }
    
    func recordSwipe(swiperId: Int, targetId: Int, status: String, completion: @escaping (Result<SwipeResponse, APIError>) -> Void) {
        let path = "swipes/"
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.invalidURL))
            return
        }
        let payload = SwipeRequest(swiper_id: swiperId, target_id: targetId, status: status)
        guard let body = try? encoder.encode(payload) else {
            completion(.failure(.decodingFailed))
            return
        }
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        session.request(
            url,
            method: .post,
            parameters: nil,
            encoding: JSONDataEncoding(data: body),
            headers: headers
        )
        .validate(statusCode: 200..<600)
        .responseData { [weak self] response in
            guard let self else { return }
            let statusCode = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let data):
                if (200...299).contains(statusCode) {
                    if let res = try? self.decoder.decode(SwipeResponse.self, from: data) {
                        completion(.success(res))
                    } else {
                        completion(.failure(.decodingFailed))
                    }
                } else {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: statusCode, message: message)))
                }
            case .failure(let afError):
                if let data = response.data {
                    let message = self.extractErrorMessage(from: data)
                    completion(.failure(.requestFailed(status: statusCode, message: message ?? afError.localizedDescription)))
                } else {
                    completion(.failure(.unknown(afError)))
                }
            }
        }
    }
}

extension APIManager {

    // MARK: - Upload Profile Image (Alamofire multipart, preserves cookies/auth)
    func uploadProfileImage(profileId: Int, image: UIImage) async -> Bool {
        let path = "profiles/\(profileId)/image/"
        guard let url = URL(string: baseURL + path) else { return false }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return false }

        return await withCheckedContinuation { continuation in
            session.upload(
                multipartFormData: { form in
                    form.append(imageData, withName: "image", fileName: "avatar.jpg", mimeType: "image/jpeg")
                },
                to: url,
                method: .post
            )
            .validate(statusCode: 200..<600)
            .responseData { response in
                let status = response.response?.statusCode ?? -1
                if !(200...299).contains(status) {
                    if let data = response.data, let raw = String(data: data, encoding: .utf8) {
                        print("[UploadImage] HTTP \(status) body: \(raw)")
                    } else {
                        print("[UploadImage] HTTP \(status) no body")
                    }
                }
                switch response.result {
                case .success:
                    continuation.resume(returning: (200...299).contains(status))
                case .failure(let err):
                    print("[UploadImage] Failed: \(err.localizedDescription)")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    // MARK: - Fetch Profile Image
    func fetchProfileImage(profileId: Int) async -> UIImage? {
        guard let url = URL(string: "http://34.21.81.90/profiles/\(profileId)/image/") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            print("[FetchImage] Error:", error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Helpers used across requests
    func extractErrorMessage(from data: Data) -> String? {
        if let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let s = obj["detail"] as? String { return s }
            if let s = obj["error"] as? String { return s }
            if let s = obj["message"] as? String { return s }
        }
        return String(data: data, encoding: .utf8)
    }
    
    func extractTopLevelID(from data: Data) -> Int? {
        if let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let id = obj["id"] as? Int { return id }
            if let s = obj["id"] as? String, let i = Int(s) { return i }
        }
        return nil
    }
}

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

// MARK: - Data helper to append Strings as UTF-8
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
