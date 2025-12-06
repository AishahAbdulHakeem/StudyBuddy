//
//  EditProfileSetUp.swift
//  ProfileSetUp.swift
//  StudyBuddy
//
//  Created by Aishah A on 11/25/25.
//

import SwiftUI
import PhotosUI

struct ProfileSetUp: View {
    @EnvironmentObject var session: SessionStore

    // MARK: - State
    // Removed local name state. We bind directly to session.profile.name now.
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
    @State private var selectedTimes: Set<StudyTime> = Set()
    
    // Photo
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // Navigation
    @State private var goToPreExplore = false
    @State private var submitError: String?

    // Styling
    private let brandRed = Color(hex: 0x9E122C)
    private let brandYellow = Color(hex: 0xFBCB77)
    private let fieldBorder = Color(.systemGray3)
    private let placeholderCircle = Color(.systemGray4)
    
    // Favorite study area options (match backend names exactly)
    private let favoriteAreaOptions = [
        "Library",
        "Cafe",
        "Study Hall"
    ]
    
    // Enable Next
    private var canContinue: Bool {
        !session.profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !major.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !favoriteArea.isEmpty
        && studyAreaId != nil
        && !courses.isEmpty
        && !selectedTimes.isEmpty
        && session.userId != nil
    }
    
    // Grid for chips
    private var chipColumns: [GridItem] = [
        GridItem(.flexible(minimum: 60), spacing: 12),
        GridItem(.flexible(minimum: 60), spacing: 12),
        GridItem(.flexible(minimum: 60), spacing: 12)
    ]
    
    // Study areas 
    private var studyAreaId: Int? {
        switch favoriteArea {
        case "Library":    return 3
        case "Cafe":       return 1
        case "Study Hall": return 2
        default:           return nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                   
                    HStack {
                        Image(.studyBuddyLogo)
                            .renderingMode(.original)
                            .frame(width: 42, height: 48)
                            .accessibilityHidden(true)
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    
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
                        TextField("Name", text: $session.profile.name)
                            .textContentType(.name)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(fieldBorder, lineWidth: 1)
                            )
                        
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
                        
                        // Courses container
                        VStack(alignment: .leading, spacing: 12) {
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

                    if let submitError {
                        Text(submitError)
                            .font(.footnote)
                            .foregroundStyle(brandRed)
                            .padding(.horizontal, 24)
                    }
                 
                    NavigationLink(destination: PreExplore(), isActive: $goToPreExplore) {
                        EmptyView()
                    }
                    .hidden()
                    
                    // Next button
                    Button {
                        Task {
                            await submitProfile()
                        }
                    } label: {
                        Text(session.isLoading ? "Saving..." : "Next")
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
                    .disabled(!canContinue || session.isLoading)
                    
                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .navigationTitle("Profile Set Up")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Actions
    private func submitProfile() async {
        submitError = nil
        guard let uid = session.userId else {
            submitError = "Missing user id."
            return
        }
        guard !session.profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            submitError = "Please enter your name."
            return
        }
        guard let areaId = studyAreaId else {
            submitError = "Please select a study area."
            return
        }
        
        guard let majorID = await session.resolveMajorID(from: major) else {
            submitError = "Please enter a valid major."
            return
        }
        
        let courseIDs = await session.resolveCourseIDs(from: courses)
        if courseIDs.isEmpty {
            submitError = "Please add at least one valid course (e.g., CS3110)."
            return
        }
        
        let timeIDs = session.resolveStudyTimeIDs(from: selectedTimes)
        if timeIDs.isEmpty {
            submitError = "Please select at least one study time."
            return
        }
        
        let payload = APIManager.CreateProfileRequest(
            user_id: uid,
            study_area_id: areaId,
            course_ids: courseIDs,
            study_time_ids: timeIDs,
            major_ids: [majorID],
            name: session.profile.name,
            college_id: nil
        )
        let ok = await session.createOrUpdateProfile(setup: payload)
        if ok {
            await session.fetchAndPopulateProfileForCurrentUser()
            if let pid = session.profileBackendId, let img = selectedImage {
                let uploaded = await APIManager.shared.uploadProfileImage(profileId: pid, image: img)
                if uploaded {
                    await MainActor.run {
                        session.profileImage = img
                    }
                }
            }

            goToPreExplore = true
        } else {
            submitError = session.errorMessage ?? "Failed to save profile."
        }
    }

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
        if !courses.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            courses.append(trimmed)
        }
        courseInput = ""
    }
    
    private func removeCourse(_ course: String) {
        courses.removeAll { $0.caseInsensitiveCompare(course) == .orderedSame }
    }
}

#Preview {
    ProfileSetUp().environmentObject(SessionStore())
}
