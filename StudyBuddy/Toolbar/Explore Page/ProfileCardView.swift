//
//  ProfileCardView.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/1/25.
//
import SwiftUI

struct ProfileCardView: View {
    let user: MatchUser
    @EnvironmentObject var profile: Profile

    private let brandRed = Color(hex: 0x9E122C)
    private let fieldBorder = Color(.systemGray3)
    private let placeholderCircle = Color(.systemGray4)

    private var handleText: String {
        "@studybuddy_\(user.id)"
    }

    private var majorsText: String {
        user.primaryMajor
    }

    private var timeChips: [Profile.StudyTime] {
        if user.preferredTimes.isEmpty {
            return [.day, .morning]
        }
        return user.preferredTimes
    }

    private let timeMapping: [Profile.StudyTime: String] = [
        .morning: "9am - 12pm",
        .day: "4pm - 7pm",
        .night: "7pm - 12am"
    ]

    private var selectedLocationTiles: [FlexibleTilesRow.Tile] {
        let ordered: [Profile.Location] = [.library, .cafe, .studyHall]
        let chosen = ordered.filter { user.preferredLocations.contains($0) }
        return chosen.map { .init(title: $0.title, systemImage: $0.systemImage) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Image("StuddyBuddyLogoRed")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    Spacer()
                }
                .padding(.top, 4)

                HStack(alignment: .top, spacing: 16) {
                    avatar
                    VStack(alignment: .leading, spacing: 6) {
                        Text(handleText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(user.name)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)

                        VStack(alignment: .leading, spacing: 2) {
                            infoRow("Major:", majorsText)
                            infoRow("Minors:", "Not specified")
                            infoRow("College:", "Not specified")
                        }
                    }
                    Spacer(minLength: 0)
                }

                preferredTimesCard

                VStack(alignment: .leading, spacing: 10) {
                    Text("Courses")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading) {
                        FlexibleChipsView(chips: user.courses)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(fieldBorder, lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Favorite study locations!")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if selectedLocationTiles.isEmpty {
                        Text("No locations shared yet.")
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

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }

    private var avatar: some View {
        ZStack {
            if let img = UIImage(named: user.avatarImageName) {
                Image(uiImage: img)
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

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var preferredTimesCard: some View {
        HStack(alignment: .top) {
            HStack(spacing: 24) {
                ForEach(timeChips, id: \.self) { time in
                    let isSelected = user.preferredTimes.contains(time)
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

            VStack(alignment: .leading, spacing: 4) {
                Text("Preferred time(s):")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach([Profile.StudyTime.morning, .day, .night], id: \.self) { t in
                    if user.preferredTimes.contains(t), let label = timeMapping[t] {
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
    let user = MatchUser(
        dto: APIManager.RichProfileDTO(
            id: 1,
            user_id: 2,
            courses: [APIManager.RichProfileDTO.Course(id: 1, code: "CS2800")],
            majors: [APIManager.RichProfileDTO.Major(id: 2, name: "Computer Science")],
            study_area: APIManager.RichProfileDTO.StudyArea(id: 1, name: "Cafe"),
            study_times: [
                APIManager.RichProfileDTO.StudyTime(id: 1, name: "morning"),
                APIManager.RichProfileDTO.StudyTime(id: 2, name: "day")
            ],
            has_profile_image_blob: false,
            profile_image_blob_base64: nil,
            profile_image_blob_url: nil,
            profile_image_mime: nil
        )
    )
    return ProfileCardView(user: user)
        .environmentObject(p)
}
