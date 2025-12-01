//
//  ProfileSetUp.swift
//  StudyBuddy
//
//  Created by Aishah A on 11/25/25.
//

import SwiftUI
import PhotosUI

struct ProfileSetUp: View {
    // MARK: - State
    @State private var name: String = ""
    @State private var major: String = ""
    @State private var favoriteArea: String = ""
    
    // Courses
    @State private var courseInput: String = ""
    @State private var courses: [String] = []
    
    // Study time multi-select
    enum StudyTime: String, CaseIterable, Identifiable {
        case morning, day, night
        var id: String { rawValue }
        
        var systemImage: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .day:     return "sun.max.fill"
            case .night:   return "moon.stars.fill"
            }
        }
        
        var label: String {
            switch self {
            case .morning: return "Morning"
            case .day:     return "Day"
            case .night:   return "Night"
            }
        }
    }
    @State private var selectedTimes: Set<StudyTime> = []
    
    // Photo
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // Styling
    private let brandRed = Color(hex: 0x9E122C)
    private let brandYellow = Color(hex: 0xFBCB77)
    private let fieldBorder = Color(.systemGray3)
    private let placeholderCircle = Color(.systemGray4)
    
    // Favorite study area placeholder options (replace later)
    private let favoriteAreaOptions = [
        "Library",
        "Café",
        "Dorm",
        "Study Hall",
        "Outdoors"
    ]
    
    // Enable Next
    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !major.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !favoriteArea.isEmpty
        && !courses.isEmpty
        && !selectedTimes.isEmpty
    }
    
    // Grid for chips (wraps automatically)
    private var chipColumns: [GridItem] = [
        GridItem(.flexible(minimum: 60), spacing: 12),
        GridItem(.flexible(minimum: 60), spacing: 12),
        GridItem(.flexible(minimum: 60), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Top logo (as in your mock)
                    HStack {
                        Image(.studyBuddyLogo)
                            .renderingMode(.original)
                            .frame(width: 42, height: 48)
                            .accessibilityHidden(true)
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    
                    // Avatar picker
                    VStack {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                if let selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(placeholderCircle)
                                        .frame(width: 140, height: 140)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 28, weight: .semibold))
                                                .foregroundStyle(brandRed)
                                        )
                                }
                            }
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = uiImage
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    
                    // Form fields
                    VStack(spacing: 14) {
                        // Name
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(fieldBorder, lineWidth: 1)
                            )
                        
                        // Major
                        TextField("Major", text: $major)
                            .textContentType(.organizationName)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(fieldBorder, lineWidth: 1)
                            )
                        
                        // Favorite study area (dropdown)
                        Menu {
                            ForEach(favoriteAreaOptions, id: \.self) { option in
                                Button {
                                    favoriteArea = option
                                } label: {
                                    Label(option, systemImage: favoriteArea == option ? "checkmark" : "")
                                }
                            }
                        } label: {
                            HStack {
                                Text(favoriteArea.isEmpty ? "Favorite study area" : favoriteArea)
                                    .foregroundStyle(brandRed)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(fieldBorder, lineWidth: 1)
                            )
                        }
                        
                        // Courses container (input + chips)
                        VStack(alignment: .leading, spacing: 12) {
                            // Input row
                            HStack(spacing: 10) {
                                TextField("Courses", text: $courseInput, onCommit: addCourse)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled(true)
                                
                                Button(action: addCourse) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(brandRed)
                                }
                                .accessibilityLabel("Add course")
                            }
                            
                            // Chips grid (wraps within the container)
                            if !courses.isEmpty {
                                LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 12) {
                                    ForEach(courses, id: \.self) { course in
                                        HStack(spacing: 8) {
                                            Text(course.uppercased())
                                                .font(.subheadline.weight(.bold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Button {
                                                removeCourse(course)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white.opacity(0.9))
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel("Remove \(course)")
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(brandRed)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(fieldBorder, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Study time preference
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Choose study time preference(s)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(brandRed)
                        Text("Select all that applies")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 24) {
                            ForEach(StudyTime.allCases) { time in
                                let isSelected = selectedTimes.contains(time)
                                Button {
                                    toggle(time)
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? brandRed.opacity(0.15) : Color(.systemGray4))
                                            .frame(width: 52, height: 52)
                                        Image(systemName: time.systemImage)
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(isSelected ? brandRed : .secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(time.label)
                                .accessibilityValue(isSelected ? "Selected" : "Not selected")
                            }
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)
                    
                    // Next button
                    Button {
                        // TODO: handle save and navigate forward
                    } label: {
                        Text("Next")
                            .font(.system(size: 20, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.black)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(brandYellow)
                            )
                    }
                    .padding(.horizontal, 24)
                    .opacity(canContinue ? 1.0 : 0.6)
                    .disabled(!canContinue)
                    
                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .navigationTitle("Profile Set Up")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Actions
    private func toggle(_ time: StudyTime) {
        if selectedTimes.contains(time) {
            selectedTimes.remove(time)
        } else {
            selectedTimes.insert(time)
        }
    }
    
    private func addCourse() {
        let trimmed = courseInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Avoid duplicates (case-insensitive)
        if !courses.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            courses.append(trimmed)
        }
        courseInput = "" // keep the field visible, just clear it
    }
    
    private func removeCourse(_ course: String) {
        courses.removeAll { $0.caseInsensitiveCompare(course) == .orderedSame }
    }
}

#Preview {
    ProfileSetUp()
}
