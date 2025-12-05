import Foundation
import SwiftUI
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: Int? = nil
    @Published var profileBackendId: Int? = nil  // backend profile.id
    @Published var profile: Profile = Profile()
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    private let userIdKey = "SB.currentUserId"
    
    init() {}
    
    // MARK: - Persistence
    private func persistUserId(_ id: Int?) {
        if let id {
            UserDefaults.standard.set(id, forKey: userIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userIdKey)
        }
    }
    
    func restoreOnLaunch() async {
        if let savedId = UserDefaults.standard.object(forKey: userIdKey) as? Int {
            self.userId = savedId
            self.isAuthenticated = true
            self.errorMessage = nil
            await fetchAndPopulateProfileForCurrentUser()
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
        
        let ok: Bool = await withCheckedContinuation { continuation in
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
        
        if ok {
            await fetchAndPopulateProfileForCurrentUser()
        }
        return ok
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
                            // Pre-fill local profile with signup info
                            self.profile.name = username
                            self.profile.email = email
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
    
    // MARK: - Create profile (ProfileSetUp)
    func createOrUpdateProfile(setup: APIManager.CreateProfileRequest) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        
        return await withCheckedContinuation { continuation in
            APIManager.shared.createProfile(setup) { [weak self] result in
                guard let self else { continuation.resume(returning: false); return }
                switch result {
                case .success(let res):
                    if (200...299).contains(res.statusCode) {
                        self.isAuthenticated = true
                        if let pid = res.profile?.id {
                            self.profileBackendId = pid
                        }
                        continuation.resume(returning: true)
                    } else {
                        self.errorMessage = "Failed to create profile."
                        continuation.resume(returning: false)
                    }
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Fetch current user's profile from backend
    
    func fetchAndPopulateProfileForCurrentUser() async {
        guard let uid = userId else { return }
        
        // 1) Get user -> profile id
        let userDTO: APIManager.UserDTO? = await withCheckedContinuation { continuation in
            APIManager.shared.getUser(id: uid) { result in
                switch result {
                case .success(let user): continuation.resume(returning: user)
                case .failure: continuation.resume(returning: nil)
                }
            }
        }
        
        guard let user = userDTO, let profileId = user.profile?.id else {
            // user exists but no profile yet
            return
        }
        
        self.profileBackendId = profileId
        
        // 2) Get full profile
        let dto: APIManager.RichProfileDTO? = await withCheckedContinuation { continuation in
            APIManager.shared.getProfile(id: profileId) { result in
                switch result {
                case .success(let profileDTO): continuation.resume(returning: profileDTO)
                case .failure: continuation.resume(returning: nil)
                }
            }
        }
        
        guard let dto else { return }
        
        let p = Profile()
        
        // Courses
        p.courses = (dto.courses ?? [])
            .compactMap { $0.code?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Majors (names only)
        p.majors = (dto.majors ?? [])
            .compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        p.major = p.majors.first ?? ""
        
        // Study times -> Profile.StudyTime set
        let times = Set((dto.study_times ?? []).compactMap { st in
            switch st.name?.lowercased() {
            case "morning": return Profile.StudyTime.morning
            case "day":     return Profile.StudyTime.day
            case "night":   return Profile.StudyTime.night
            default:        return nil
            }
        })
        p.selectedTimes = times
        
        // Study area -> Location
        if let areaName = dto.study_area?.name?.trimmingCharacters(in: .whitespacesAndNewlines) {
            let loc: Profile.Location? = {
                switch areaName.lowercased() {
                case "library":     return .library
                case "cafe":        return .cafe
                case "study hall":  return .studyHall
                default:            return nil
                }
            }()
            if let loc { p.selectedLocations = [loc] }
        }
        
        // Photo
        if let b64 = dto.profile_image_blob_base64,
           let data = Data(base64Encoded: b64) {
            p.photoData = data
        }
        
        self.profile = p
    }
    
    // MARK: - Push current profile back to backend (EditProfilePage)
    func syncProfileToBackend() async -> Bool {
        guard let uid = userId else {
            self.errorMessage = "Missing user id."
            return false
        }
        guard let profileId = profileBackendId else {
            self.errorMessage = "No profile found on server for user \(uid)."
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        
        let p = profile
        
        // Study area mapping: Cafe=1, Study Hall=2, Library=3 (matches your backend)
        var studyAreaId: Int?
        if p.selectedLocations.contains(.cafe) {
            studyAreaId = 1
        } else if p.selectedLocations.contains(.studyHall) {
            studyAreaId = 2
        } else if p.selectedLocations.contains(.library) {
            studyAreaId = 3
        } else {
            studyAreaId = nil
        }
        
        // Courses -> core IDs (create-if-needed)
        let courseIDs = await resolveCourseIDs(from: p.courses)
        
        // Majors -> IDs (take the first as “primary”)
        var majorIDs: [Int] = []
        if let primaryMajor = p.majors.first {
            if let mid = await resolveMajorID(from: primaryMajor) {
                majorIDs = [mid]
            }
        }
        
        // Study times -> IDs
        let timeIDs = resolveStudyTimeIDs(fromProfileTimes: p.selectedTimes)
        
        let payload = APIManager.UpdateProfileRequest(
            study_area_id: studyAreaId,
            course_ids: courseIDs.isEmpty ? nil : courseIDs,
            study_time_ids: timeIDs.isEmpty ? nil : timeIDs,
            major_ids: majorIDs.isEmpty ? nil : majorIDs
        )
        
        return await withCheckedContinuation { continuation in
            APIManager.shared.updateProfile(id: profileId, request: payload) { [weak self] result in
                guard let self else {
                    continuation.resume(returning: false)
                    return
                }
                switch result {
                case .success(let res):
                    let ok = (200...299).contains(res.statusCode)
                    if !ok {
                        self.errorMessage = "Failed to update profile."
                    }
                    continuation.resume(returning: ok)
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Courses helper
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
    
    // MARK: - Majors helper
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
    
    // MARK: - Study times helpers
    
    // used by ProfileSetUp.StudyTime
    func resolveStudyTimeIDs(from selected: Set<ProfileSetUp.StudyTime>) -> [Int] {
        var ids: [Int] = []
        if selected.contains(.morning) { ids.append(1) }
        if selected.contains(.day)     { ids.append(2) }
        if selected.contains(.night)   { ids.append(3) }
        return ids
    }
    
    // used by Profile.StudyTime (EditProfilePage)
    func resolveStudyTimeIDs(fromProfileTimes selected: Set<Profile.StudyTime>) -> [Int] {
        var ids: [Int] = []
        if selected.contains(.morning) { ids.append(1) }
        if selected.contains(.day)     { ids.append(2) }
        if selected.contains(.night)   { ids.append(3) }
        return ids
    }
    
    // MARK: - Fetch matches for MessagesPage (real implementation)
    func fetchMatches() async -> [MatchUser] {
        guard let uid = userId else { return [] }
        
        // 1) Fetch match refs
        let matchRefs: [APIManager.UserMatchDTO]? = await withCheckedContinuation { continuation in
            APIManager.shared.getUserMatches(userId: uid) { result in
                switch result {
                case .success(let items): continuation.resume(returning: items)
                case .failure: continuation.resume(returning: nil)
                }
            }
        }
        guard let matchRefs, !matchRefs.isEmpty else { return [] }
        
        // 2) For each matched user, fetch their profile dto
        var users: [MatchUser] = []
        for item in matchRefs {
            guard let pId = item.matched_user?.profile?.id else { continue }
            let dto: APIManager.RichProfileDTO? = await withCheckedContinuation { continuation in
                APIManager.shared.getProfile(id: pId) { result in
                    switch result {
                    case .success(let prof): continuation.resume(returning: prof)
                    case .failure: continuation.resume(returning: nil)
                    }
                }
            }
            if let dto {
                users.append(MatchUser(dto: dto))
            }
        }
        return users
    }
}
