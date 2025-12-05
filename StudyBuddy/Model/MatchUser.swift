import Foundation
import SwiftUI

struct MatchUser: Identifiable, Equatable {
    let id: Int                 // This is the USER ID (preferred), not profile id
    let name: String
    let primaryMajor: String
    let courses: [String]
    let preferredTimes: [Profile.StudyTime]
    let preferredLocations: [Profile.Location]
    let avatarImageName: String

    init(dto: APIManager.RichProfileDTO) {
        // Prefer the backend user_id for swipe/match APIs; fallback to profile id if missing
        self.id = dto.user_id ?? dto.id ?? 0

        // No username present in RichProfileDTO; placeholder for now
        self.name = "Unknown User"

        // Primary major
        self.primaryMajor = (dto.majors ?? [])
            .first?.name?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "N/A"

        // Courses
        self.courses = (dto.courses ?? [])
            .compactMap { $0.code?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Preferred times
        self.preferredTimes = (dto.study_times ?? []).compactMap { st in
            switch st.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "morning": return .morning
            case "day":     return .day
            case "night":   return .night
            default:        return nil
            }
        }

        // Preferred locations
        if let area = dto.study_area?.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            let loc: Profile.Location? = {
                switch area {
                case "library":    return .library
                case "cafe":       return .cafe
                case "study hall": return .studyHall
                default:           return nil
                }
            }()
            self.preferredLocations = loc.map { [$0] } ?? []
        } else {
            self.preferredLocations = []
        }

        // Placeholder avatar for now
        self.avatarImageName = "defaultAvatar"
    }
}
