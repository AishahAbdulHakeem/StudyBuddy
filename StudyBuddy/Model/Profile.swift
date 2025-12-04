//
//  ProfileModel.swift
//  StudyBuddy
//
//  Created by You on 12/3/25.
//

import SwiftUI
import Combine

// MARK: - Study Session Event Model
struct StudySessionEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date            // Calendar day (start-of-day key)
    var title: String         // e.g., "Study session"
    var participants: [String] // names or user IDs
    var course: String?       // optional
    var location: String?     // optional
    var startTime: Date?      // optional precise time
    var endTime: Date?        // optional precise time
    var notes: String?        // optional

    init(
        id: UUID = UUID(),
        date: Date,
        title: String = "Study session",
        participants: [String],
        course: String? = nil,
        location: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.participants = participants
        self.course = course
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }
}

final class Profile: ObservableObject {
    enum StudyTime: String, CaseIterable, Identifiable, Codable, Hashable {
        case morning, day, night
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .morning: return "Morning"
            case .day:     return "Day"
            case .night:   return "Night"
            }
        }
        
        var systemImage: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .day:     return "sun.max.fill"
            case .night:   return "moon.stars.fill"
            }
        }
    }
    
    enum Location: String, CaseIterable, Identifiable, Codable, Hashable {
        case library
        case cafe
        case studyHall
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .library:   return "Library"
            case .cafe:      return "Cafe"
            case .studyHall: return "Study Hall"
            }
        }
        
        var systemImage: String {
            switch self {
            case .library:   return "books.vertical"
            case .cafe:      return "cup.and.saucer"
            case .studyHall: return "building.columns"
            }
        }
    }
    
    // MARK: Availability model
    enum AvailabilityWindow: String, CaseIterable, Identifiable, Codable, Hashable {
        case morning9to11
        case day4to7
        case night7to12
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .morning9to11: return "9–11am"
            case .day4to7:      return "4–7pm"
            case .night7to12:   return "7–12am"
            }
        }
        
        var icon: String {
            switch self {
            case .morning9to11: return StudyTime.morning.systemImage
            case .day4to7:      return StudyTime.day.systemImage
            case .night7to12:   return StudyTime.night.systemImage
            }
        }
        
        static func allowed(for selectedTimes: Set<StudyTime>) -> [AvailabilityWindow] {
            var result: [AvailabilityWindow] = []
            if selectedTimes.contains(.morning) { result.append(.morning9to11) }
            if selectedTimes.contains(.day)     { result.append(.day4to7) }
            if selectedTimes.contains(.night)   { result.append(.night7to12) }
            return result
        }
    }
    
    // Legacy single fields (kept for compatibility if you still use them somewhere)
    @Published var name: String = ""
    @Published var major: String = "" // optional: can set to majors.first if you want a "primary" major
    @Published var favoriteArea: String = ""
    
    // New multi-value fields
    @Published var majors: [String] = []
    @Published var minors: [String] = []
    
    // College (single)
    @Published var college: String = ""
    
    // Courses and preferences
    @Published var courses: [String] = []
    @Published var selectedTimes: Set<StudyTime> = []
    @Published var selectedLocations: Set<Location> = []
    
    // Availability per day (keyed by start-of-day Date in current calendar)
    @Published var availability: [Date: Set<AvailabilityWindow>] = [:]
    
    // Events per day (keyed by start-of-day Date in current calendar)
    @Published var events: [Date: [StudySessionEvent]] = [:]
    
    // Photo
    @Published var photoData: Data? = nil

    // Account info
    @Published var email: String = ""
    
    // Convenience
    var hasPhoto: Bool { photoData != nil }
    var uiImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Events CRUD (Messages can call these later)
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal
    }
    private func dateOnly(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    func addEvent(_ event: StudySessionEvent) {
        let key = dateOnly(event.date)
        var list = events[key] ?? []
        list.append(event)
        // Sort by start time if present; otherwise by title for stable order
        list.sort {
            let l = $0.startTime ?? $0.date
            let r = $1.startTime ?? $1.date
            if l != r { return l < r }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        events[key] = list
    }
    
    func updateEvent(_ updated: StudySessionEvent) {
        removeEvent(withID: updated.id)
        addEvent(updated)
    }
    
    func removeEvent(withID id: UUID) {
        for (key, list) in events {
            let newList = list.filter { $0.id != id }
            events[key] = newList.isEmpty ? nil : newList
        }
    }
    
    func events(on date: Date) -> [StudySessionEvent] {
        events[dateOnly(date)] ?? []
    }
}
