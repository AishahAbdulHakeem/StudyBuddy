import Foundation
import SwiftUI
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: Int? = nil
    @Published var profile: Profile = Profile()
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    private let userDefaultsKey = "SB.currentUserId"
    
    init() {}
    
    private func persistUserId(_ id: Int?) {
        if let id {
            UserDefaults.standard.set(id, forKey: userDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
    
    func restoreOnLaunch() async {
        if let savedId = UserDefaults.standard.object(forKey: userDefaultsKey) as? Int {
            self.userId = savedId
            self.isAuthenticated = true
            self.errorMessage = nil
        } else {
            self.userId = nil
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Login
    func login(username: String, password: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        
        return await withCheckedContinuation { continuation in
            APIManager.shared.login(username: username, password: password) { [weak self] result in
                guard let self else { continuation.resume(returning: false); return }
                switch result {
                case .success(let res):
                    if (200...299).contains(res.statusCode), let uid = res.userId ?? res.user?.id {
                        self.userId = uid
                        self.isAuthenticated = true
                        self.persistUserId(uid)
                        continuation.resume(returning: true)
                    } else {
                        self.errorMessage = "Login failed."
                        continuation.resume(returning: false)
                    }
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Sign Up
    func signUp(username: String, email: String, password: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        
        return await withCheckedContinuation { continuation in
            APIManager.shared.signUp(username: username, email: email, password: password) { [weak self] result in
                guard let self else {
                    continuation.resume(returning: false)
                    return
                }
                switch result {
                case .success(let res):
                    if res.statusCode == 201 {
                        if let uid = res.userId ?? (res.user?.id.flatMap { Int($0) }) {
                            self.userId = uid
                            self.isAuthenticated = true
                            self.persistUserId(uid)
                        }
                        continuation.resume(returning: true)
                    } else {
                        self.errorMessage = "Signup failed."
                        continuation.resume(returning: false)
                    }
                case .failure(let err):
                    self.errorMessage = err.errorDescription ?? err.localizedDescription
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Profile
    func createOrUpdateProfile(setup: APIManager.CreateProfileRequest) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        
        return await withCheckedContinuation { continuation in
            APIManager.shared.createProfile(setup) { [weak self] result in
                guard let self else { continuation.resume(returning: false); return }
                switch result {
                case .success(let res):
                    if let _ = res.profile {
                        self.isAuthenticated = true
                    }
                    continuation.resume(returning: (200...299).contains(res.statusCode))
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Courses quick-path resolver
    func resolveCourseIDs(from codes: [String]) async -> [Int] {
        let trimmed = codes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }
        
        var ids: [Int] = []
        for code in trimmed {
            if let id = await createOrFetchCourseID(for: code) {
                ids.append(id)
            }
        }
        return ids
    }
    
    private func createOrFetchCourseID(for code: String) async -> Int? {
        await withCheckedContinuation { continuation in
            APIManager.shared.createCourse(code: code) { [weak self] result in
                switch result {
                case .success(let res):
                    if let id = res.course?.id {
                        continuation.resume(returning: id)
                    } else {
                        self?.fetchCourseIDByListing(code: code, continuation: continuation)
                    }
                case .failure:
                    self?.fetchCourseIDByListing(code: code, continuation: continuation)
                }
            }
        }
    }
    
    private func fetchCourseIDByListing(code: String, continuation: CheckedContinuation<Int?, Never>) {
        APIManager.shared.getCourses { result in
            switch result {
            case .success(let list):
                let normalized = code.uppercased()
                let id = list.first { ($0.code ?? "").uppercased() == normalized }?.id
                continuation.resume(returning: id)
            case .failure:
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Majors quick-path resolver
    func resolveMajorID(from name: String) async -> Int? {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        return await withCheckedContinuation { continuation in
            APIManager.shared.createMajor(name: cleaned) { [weak self] result in
                switch result {
                case .success(let res):
                    if let id = res.major?.id {
                        continuation.resume(returning: id)
                    } else {
                        self?.fetchMajorIDByListing(name: cleaned, continuation: continuation)
                    }
                case .failure:
                    self?.fetchMajorIDByListing(name: cleaned, continuation: continuation)
                }
            }
        }
    }
    
    private func fetchMajorIDByListing(name: String, continuation: CheckedContinuation<Int?, Never>) {
        APIManager.shared.getMajors { result in
            switch result {
            case .success(let list):
                let target = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let id = list.first { ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == target }?.id
                continuation.resume(returning: id)
            case .failure:
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Study times resolver (predefined IDs)
    func resolveStudyTimeIDs(from selected: Set<ProfileSetUp.StudyTime>) -> [Int] {
        var ids: [Int] = []
        if selected.contains(.morning) { ids.append(1) } // morning id
        if selected.contains(.day)     { ids.append(2) } // day id
        if selected.contains(.night)   { ids.append(3) } // night id
        return ids
    }
}
