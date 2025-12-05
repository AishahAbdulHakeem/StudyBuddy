//
//  ProfilePage.swift
//  StudyBuddy
//
//  Created by Aishah A on 11/25/25.
//

import SwiftUI

struct ProfilePage: View {
    @EnvironmentObject var profile: Profile

 
    private let brandRed = Color(hex: 0x9E122C)
    private let brandYellow = Color(hex: 0xFBCB77)
    private let fieldBorder = Color(.systemGray3)
    private let placeholderCircle = Color(.systemGray4)

    
    private var displayName: String {
        let trimmed = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Anonymous" : trimmed
    }

    
    private var majorsText: String {
        profile.majors
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var minorsText: String {
        profile.minors
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var collegeText: String {
        profile.college.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var courseList: [String] {
        profile.courses
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

 
    private var timeChips: [Profile.StudyTime] {
        let ordered: [Profile.StudyTime] = [.morning, .day, .night]
        return ordered.filter { profile.selectedTimes.contains($0) }
    }

    private let timeMapping: [Profile.StudyTime: String] = [
        .morning: "9am - 12pm",
        .day: "4pm - 7pm",
        .night: "7pm - 12am"
    ]

  
    private var selectedLocationTiles: [FlexibleTilesRow.Tile] {
        let ordered: [Profile.Location] = [.library, .cafe, .studyHall]
        let chosen = ordered.filter { profile.selectedLocations.contains($0) }
        return chosen.map { .init(title: $0.title, systemImage: $0.systemImage) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
             
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        
                        HStack {
                            Image("StuddyBuddyLogoRed")
                                .font(.system(size: 28, weight: .regular))
                                .foregroundStyle(brandRed)
                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 20)

                        
                        HStack(alignment: .top, spacing: 16) {
                            avatar

                            VStack(alignment: .leading, spacing: 6) {
                                
                                Text(displayName)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.primary)

                                VStack(alignment: .leading, spacing: 2) {
                                    if !majorsText.isEmpty {
                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            Text("Major:")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Text(majorsText)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    if !minorsText.isEmpty {
                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            Text("Minors:")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Text(minorsText)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    if !collegeText.isEmpty {
                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            Text("College:")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Text(collegeText)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 20)

                        
                        if !timeChips.isEmpty {
                            preferredTimesCard
                                .padding(.horizontal, 20)
                        }

                
                        if !courseList.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Courses")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                VStack(alignment: .leading) {
                                    FlexibleChipsView(chips: courseList)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 12)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(fieldBorder, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 20)
                        }

                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Favorite study locations!")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            if selectedLocationTiles.isEmpty {
                                Text("No locations selected yet.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                FlexibleTilesRow(
                                    items: selectedLocationTiles,
                                    brandRed: brandRed
                                )
                                .accessibilityElement(children: .contain)
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 80)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.bottom, 24)
                }

                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink {
                            EditProfilePage()
                                .environmentObject(profile)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(brandYellow)
                                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundStyle(.black)
                            }
                            .frame(width: 57, height: 59)
                            .accessibilityLabel("Edit Profile")
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 80)
                    }
                }
                .allowsHitTesting(false)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            NavigationLink {
                                EditProfilePage()
                                    .environmentObject(profile)
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(brandYellow)
                                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 32, weight: .semibold))
                                        .foregroundStyle(.black)
                                }
                                .frame(width: 57, height: 59)
                                .accessibilityLabel("Edit Profile")
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 80)
                        }
                    }
                )

          
                VStack {
                    Spacer()
                    ZStack {
                        HStack(spacing: 40) {
                            NavigationLink(destination: HomePage()) {
                                Image("StudyBuddyLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
                            }
                            NavigationLink(destination: ExplorePage()) {
                                Image(systemName: "hand.raised.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
                            }
                            NavigationLink(destination: MessagesPage()) {
                                Image(systemName: "message")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
                            }
                            NavigationLink(destination: ProfilePage()) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: 0x9E122C))
                            .frame(width: 400, height: 100)
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private var avatar: some View {
        ZStack {
            if let ui = profile.uiImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(placeholderCircle)
                    .frame(width: 90, height: 90)
            }
        }
    }

    private var preferredTimesCard: some View {
        HStack(alignment: .top) {
            
            HStack(spacing: 24) {
                ForEach(timeChips, id: \.self) { time in
                    let isSelected = profile.selectedTimes.contains(time)
                    ZStack {
                        Circle()
                            .fill(isSelected ? brandRed.opacity(0.15) : Color(.systemGray4))
                            .frame(width: 52, height: 52)
                        Image(systemName: time.systemImage)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isSelected ? brandRed : .secondary)
                    }
                    .accessibilityLabel(time.label)
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                }
            }

            Spacer(minLength: 12)

            // Right: label + ranges (only for selected)
            VStack(alignment: .leading, spacing: 4) {
                Text("Preferred time(s):")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach([Profile.StudyTime.morning, .day, .night], id: \.self) { t in
                    if profile.selectedTimes.contains(t), let label = timeMapping[t] {
                        Text(label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.label).opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Courses chips (two rows, horizontally scrollable)
    struct FlexibleChipsView: View {
        let chips: [String]
        private let brandRed = Color(hex: 0x9E122C)

        private let rows: [GridItem] = [
            GridItem(.fixed(34), spacing: 12, alignment: .center),
            GridItem(.fixed(34), spacing: 12, alignment: .center)
        ]

        init(chips: [String]) {
            self.chips = chips
        }

        var body: some View {
            ScrollView(.horizontal, showsIndicators: true) {
                LazyHGrid(rows: rows, alignment: .center, spacing: 12) {
                    ForEach(chips, id: \.self) { course in
                        Text(course.uppercased())
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(brandRed)
                            )
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(height: 2 * 34 + 12)
        }
    }

    // MARK: - Favorite locations tiles
    struct FlexibleTilesRow: View {
        struct Tile: Identifiable, Hashable {
            let id = UUID()
            let title: String
            let systemImage: String
        }

        static let columns: [GridItem] = [
            GridItem(.flexible(minimum: 80), spacing: 20),
            GridItem(.flexible(minimum: 80), spacing: 20),
            GridItem(.flexible(minimum: 80), spacing: 20)
        ]

        let items: [Tile]
        let brandRed: Color

        var body: some View {
            LazyVGrid(columns: Self.columns, alignment: .center, spacing: 18) {
                ForEach(items) { item in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.label).opacity(0.6), lineWidth: 1.5)
                                .frame(width: 64, height: 64)
                            Image(systemName: item.systemImage)
                                .font(.system(size: 24, weight: .regular))
                                .foregroundStyle(brandRed)
                        }
                        Text(item.title)
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    let p = Profile()
    p.name = ""
    return ProfilePage()
        .environmentObject(p)
}
