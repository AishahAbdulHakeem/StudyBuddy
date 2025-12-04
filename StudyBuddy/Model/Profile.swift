//
//  ProfileModel.swift
//  StudyBuddy
//
//  Created by You on 12/3/25.
//

import SwiftUI
import Combine

final class Profile: ObservableObject {
    enum StudyTime: String, CaseIterable, Identifiable, Codable {
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
    
    @Published var name: String = ""
    @Published var major: String = ""
    @Published var favoriteArea: String = ""
    @Published var courses: [String] = []
    @Published var selectedTimes: Set<StudyTime> = []
    
    // Store photo as Data so it’s lightweight and portable between views.
    @Published var photoData: Data? = nil
    
    // Convenience
    var hasPhoto: Bool { photoData != nil }
    var uiImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
}
