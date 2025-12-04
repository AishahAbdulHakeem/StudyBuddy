//
//  ProfilePage.swift
//  StudyBuddy
//
//  Created by Aishah A on 11/25/25.
//

import SwiftUI

struct ProfilePage: View {
    // Shared profile (when available). For now we also show sensible placeholders.
    @EnvironmentObject var profile: Profile

    // Branding
    private let brandRed = Color(hex: 0x9E122C)
    private let brandYellow = Color(hex: 0xFBCB77)
    private let fieldBorder = Color(.systemGray3)
    private let placeholderCircle = Color(.systemGray4)

    // Dummy fallbacks (used when profile fields are empty)
    private var handle: String { "@testing_123" }
    private var displayName: String { profile.name.isEmpty ? "Testing" : profile.name }
    private var majorText: String { profile.major.isEmpty ? "Computer Science 28’" : profile.major }
    private var minorsText: String { "Info Sci, Game Design" }
    private var collegeText: String { "Engineering" }
    private var preferredTimeRanges: [String] { ["9am - 11am", "4pm - 7pm"] }

    private var courseList: [String] {
        if profile.courses.isEmpty {
            return ["CS 3110", "CS 2800", "MATH 2930", "CHIN 1109", "INFO 1998"]
        }
        return profile.courses
    }

    // For the chips inside the times card (your mock shows "day" and "noon")
    private var timeChips: [Profile.StudyTime] {
        if profile.selectedTimes.isEmpty {
            return [.day, .morning] // show day + morning to read like “day / noon” in look
        }
        return Array(profile.selectedTimes)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Top icon row
                        HStack {
                            Image("StuddyBuddyLogoRed")
                                .font(.system(size: 28, weight: .regular))
                                .foregroundStyle(brandRed)
                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 20)

                        // Header: avatar + name block
                        HStack(alignment: .top, spacing: 16) {
                            avatar
                            VStack(alignment: .leading, spacing: 6) {
                                Text(handle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Text(displayName)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.primary)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        Text("Major:")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(majorText)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        Text("Minors:")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(minorsText)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
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
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 20)

                        // Preferred times card
                        preferredTimesCard
                            .padding(.horizontal, 20)

                        // Courses section
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

                        // Favorite locations section (updated to match screenshot)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Favorite study locations!")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            // Tiles row (wrap if needed)
                            FlexibleTilesRow(
                                items: [
                                    .init(title: "Library", systemImage: "books.vertical"),
                                    .init(title: "Cafe", systemImage: "cup.and.saucer"),
                                    .init(title: "Study Hall", systemImage: "building.columns")
                                ],
                                brandRed: brandRed
                            )
                            .accessibilityElement(children: .contain)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 24)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.bottom, 24)
                }

                // Floating Edit button (bottom-right over locations area)
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
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                    .accessibilityLabel("Edit Profile")
                }
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
            // Left: icons in circles (match Sign Up)
            HStack(spacing: 24) {
                ForEach(timeChips) { time in
                    // Consider this "selected" if it's actually in the user's selectedTimes set.
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

            // Right: label + bold times
            VStack(alignment: .leading, spacing: 4) {
                Text("Preferred time(s):")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(preferredTimeRanges, id: \.self) { range in
                    Text(range)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
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

        // Two fixed-height rows to keep a consistent two-row look
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
                            .lineLimit(1) // one line per chip
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
            // Give the grid enough height to show two rows
            .frame(height: 2 * 34 + 12) // row height * 2 + spacing between rows
        }
    }

    // MARK: - Favorite locations tiles

    struct FlexibleTilesRow: View {
        struct Tile: Identifiable, Hashable {
            let id = UUID()
            let title: String
            let systemImage: String
        }

        let items: [Tile]
        let brandRed: Color

        // Three equal columns that wrap if needed
        private static let columns: [GridItem] = [
            GridItem(.flexible(minimum: 80), spacing: 20),
            GridItem(.flexible(minimum: 80), spacing: 20),
            GridItem(.flexible(minimum: 80), spacing: 20)
        ]

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
    // Preview with a filled dummy profile so it matches the mock immediately.
    let p = Profile()
    p.name = "Testing"
    p.major = "Computer Science 28’"
    p.courses = ["CS 3110", "CS 2800", "MATH 2930", "CHIN 1109", "INFO 1998", "BIO 1010", "ECON 1120", "HIST 1234"]
    p.selectedTimes = [.day, .morning]
    return ProfilePage()
        .environmentObject(p)
}
