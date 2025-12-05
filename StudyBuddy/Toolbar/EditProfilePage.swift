//
//  EditProfilePage.swift
//  StudyBuddy
//
//  Created by Aishah A on 11/25/25.
//

import SwiftUI
import PhotosUI

struct EditProfilePage: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profile: Profile
    @EnvironmentObject var session: SessionStore

    // Branding
    private let brandRed = Color(hex: 0x9E122C)
    private let brandYellow = Color(hex: 0xFBCB77)
    private let fieldBorder = Color(.systemGray3)
    private let placeholderCircle = Color(.systemGray4)

    // Local editable copies (initialize from profile)
    @State private var name: String = ""
    @State private var handle: String = "@testing_123"
    @State private var majorInput: String = ""
    @State private var minorInput: String = ""
    @State private var courseInput: String = ""
    @State private var college: String = ""

    @State private var majors: [String] = []
    @State private var minors: [String] = []
    @State private var courses: [String] = []

    // Study times/locations
    @State private var selectedTimes: Set<Profile.StudyTime> = []
    @State private var selectedLocations: Set<Profile.Location> = []

    // Photo picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    // Saving state
    @State private var isSaving: Bool = false
    @State private var saveError: String?

    // Bottom bar height spacing
    private let bottomBarHeight: CGFloat = 100
    private let bottomBarPadding: CGFloat = 16

    // Derived preferred ranges based on selected time icons
    private var preferredRangesFromSelection: [(time: Profile.StudyTime, range: String)] {
        let order: [Profile.StudyTime] = [.morning, .day, .night]
        let mapping: [Profile.StudyTime: String] = [
            .morning: "9am - 12pm",
            .day: "4pm - 7pm",
            .night: "7pm - 12am"
        ]
        return order.compactMap { t in
            guard selectedTimes.contains(t), let r = mapping[t] else { return nil }
            return (time: t, range: r)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {

                    // Top row: logo + invisible back chevron (layout match)
                    HStack {
                        Image("StuddyBuddyLogoRed")
                            .font(.system(size: 28))
                            .foregroundStyle(brandRed)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        .opacity(0) // placeholder
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Avatar with floating "+"
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                            } else if let ui = profile.uiImage {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Circle()
                                    .fill(placeholderCircle)
                            }
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())

                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(brandYellow)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            .padding(6)
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                profile.photoData = data
                            }
                        }
                    }

                    VStack(spacing: 14) {
                        // Name
                        field(text: $name, placeholder: "Name")

                        // Handle (not persisted to backend yet; purely UI/branding)
                        field(text: $handle, placeholder: "@handle")

                        // College
                        field(text: $college, placeholder: "College (e.g., Engineering)")

                        // Major(s)
                        addableField(title: "Major(s)", text: $majorInput, onAdd: addMajor)
                        chipsGrid(majors).padding(.top, 4)

                        // Minor(s)
                        addableField(title: "Minor(s)", text: $minorInput, onAdd: addMinor)
                        chipsGrid(minors).padding(.top, 4)

                        // Courses (two-row horizontal, with delete)
                        addableField(title: "Courses", text: $courseInput, onAdd: addCourse)
                        EditableTwoRowChipsView(chips: $courses, brandRed: brandRed)
                            .padding(.top, 4)

                        // Study time preference
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Choose study time preference(s)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(brandRed)
                            Text("Select all that applies")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 24) {
                                ForEach(Profile.StudyTime.allCases) { time in
                                    let isSelected = selectedTimes.contains(time)
                                    Button {
                                        toggleTime(time)
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .stroke(isSelected ? brandRed : Color(.label).opacity(0.5), lineWidth: 2)
                                                .background(
                                                    Circle().fill(isSelected ? brandRed.opacity(0.15) : Color.clear)
                                                )
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
                        .padding(.top, 4)

                        // Preferred ranges blocks (dynamic based on selectedTimes)
                        VStack(spacing: 12) {
                            ForEach(preferredRangesFromSelection, id: \.time) { pair in
                                rangeField(title: pair.range, trailingTag: tag(for: pair.time))
                            }
                        }

                        // Study location preference
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Choose study location(s)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(brandRed)
                            Text("Select all that applies")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 24) {
                                ForEach(Profile.Location.allCases) { loc in
                                    let isSelected = selectedLocations.contains(loc)
                                    Button {
                                        toggleLocation(loc)
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? brandRed : Color(.label).opacity(0.5), lineWidth: 2)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(isSelected ? brandRed.opacity(0.15) : Color.clear)
                                                )
                                                .frame(width: 64, height: 64)
                                            Image(systemName: loc.systemImage)
                                                .font(.system(size: 22, weight: .regular))
                                                .foregroundStyle(isSelected ? brandRed : .secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(loc.title)
                                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                                }
                            }
                            .padding(.top, 6)
                        }
                        .padding(.top, 4)

                        if let saveError {
                            Text(saveError)
                                .font(.footnote)
                                .foregroundStyle(brandRed)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: bottomBarHeight + bottomBarPadding)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.bottom, 16)
            }

            // Bottom bar
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
                        NavigationLink(destination: CalendarPage()) {
                            Image(systemName: "calendar")
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
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadFromProfile)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await handleSave() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .font(.body.weight(.semibold))
                    }
                }
                .disabled(isSaving)
            }
        }
    }

    // MARK: - Save flow

    private func handleSave() async {
        saveError = nil
        isSaving = true
        defer { isSaving = false }

        // 1) Update local Profile model (UI state)
        saveToProfileLocally()

        // 2) Push to backend
        let ok = await session.syncProfileToBackend()
        if ok {
            dismiss()
        } else {
            saveError = session.errorMessage ?? "Failed to save changes to the server."
        }
    }

    private func saveToProfileLocally() {
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.majors = majors
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        profile.minors = minors
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        profile.college = college.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.courses = courses
        profile.selectedTimes = selectedTimes
        profile.selectedLocations = selectedLocations
        
        // keep legacy major in sync
        profile.major = profile.majors.first ?? ""
    }

    // MARK: - Subviews

    private func field(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(fieldBorder, lineWidth: 1)
            )
    }

    private func addableField(title: String, text: Binding<String>, onAdd: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            TextField(title, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)

            Button(action: onAdd) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(brandRed)
            }
            .accessibilityLabel("Add \(title)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(fieldBorder, lineWidth: 1)
        )
    }

    // Flexible chips that wrap to multiple lines and size to content
    private func chipsGrid(_ items: [String]) -> some View {
        FlowLayout(items: items, spacing: 12, rowSpacing: 12) { item in
            HStack(spacing: 8) {
                Text(item)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                Button {
                    remove(item, from: items)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(item)")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(brandRed)
            )
        }
        .background(Color.clear)
    }

    private func rangeField(title: String, trailingTag: some View) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            trailingTag
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(fieldBorder, lineWidth: 1)
        )
    }

    private func tag(for time: Profile.StudyTime) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.label), lineWidth: 2)
                .frame(width: 34, height: 34)
            Image(systemName: time.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Actions
    private func loadFromProfile() {
        name = profile.name
        majors = profile.majors
        minors = profile.minors
        college = profile.college
        courses = profile.courses
        selectedTimes = profile.selectedTimes
        selectedLocations = profile.selectedLocations
    }

    private func toggleTime(_ time: Profile.StudyTime) {
        if selectedTimes.contains(time) {
            selectedTimes.remove(time)
        } else {
            selectedTimes.insert(time)
        }
    }

    private func toggleLocation(_ loc: Profile.Location) {
        if selectedLocations.contains(loc) {
            selectedLocations.remove(loc)
        } else {
            selectedLocations.insert(loc)
        }
    }

    private func addMajor() {
        let t = majorInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        if !majors.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) {
            majors.append(t)
        }
        majorInput = ""
    }

    private func addMinor() {
        let t = minorInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        if !minors.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) {
            minors.append(t)
        }
        minorInput = ""
    }

    private func addCourse() {
        let t = courseInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        if !courses.contains(where: { $0.caseInsensitiveCompare(t) == .orderedSame }) {
            courses.append(t)
        }
        courseInput = ""
    }

    private func remove(_ value: String, from list: [String]) {
        if let idx = majors.firstIndex(of: value) { majors.remove(at: idx); return }
        if let idx = minors.firstIndex(of: value) { minors.remove(at: idx); return }
        if let idx = courses.firstIndex(of: value) { courses.remove(at: idx); return }
    }
}

// MARK: - Two-row horizontal editable chips for Courses
private struct EditableTwoRowChipsView: View {
    @Binding var chips: [String]
    let brandRed: Color

    private let rows: [GridItem] = [
        GridItem(.fixed(34), spacing: 12, alignment: .center),
        GridItem(.fixed(34), spacing: 12, alignment: .center)
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHGrid(rows: rows, alignment: .center, spacing: 12) {
                ForEach(chips, id: \.self) { course in
                    HStack(spacing: 8) {
                        Text(course.uppercased())
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Button {
                            remove(course)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.95))
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
            .padding(.vertical, 2)
        }
        .frame(height: 2 * 34 + 12)
    }

    private func remove(_ course: String) {
        chips.removeAll { $0.caseInsensitiveCompare(course) == .orderedSame }
    }
}

// MARK: - FlowLayout (content-sized chips with wrapping, stable height)
private struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let rowSpacing: CGFloat
    let content: (Item) -> Content

    init(items: [Item], spacing: CGFloat = 8, rowSpacing: CGFloat = 8, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.spacing = spacing
        self.rowSpacing = rowSpacing
        self.content = content
    }

    var body: some View {
        _FlowLayout(items: items, spacing: spacing, rowSpacing: rowSpacing, content: content)
    }

    private struct _FlowLayout: View {
        let items: [Item]
        let spacing: CGFloat
        let rowSpacing: CGFloat
        let content: (Item) -> Content

        @State private var sizes: [Item: CGSize] = [:]
        @State private var totalWidth: CGFloat = 0

        var body: some View {
            VStack(alignment: .leading, spacing: rowSpacing) {
                ForEach(rows(in: totalWidth), id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(row, id: \.self) { item in
                            content(item)
                                .readSize { size in
                                    sizes[item] = size
                                }
                        }
                    }
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { totalWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { new in totalWidth = new }
                }
            )
        }

        private func rows(in availableWidth: CGFloat) -> [[Item]] {
            guard availableWidth > 0 else { return [items] }
            var result: [[Item]] = [[]]
            var currentRowWidth: CGFloat = 0

            for item in items {
                let itemWidth = sizes[item]?.width ?? 0
                let nextWidth = (result.last!.isEmpty ? 0 : currentRowWidth + spacing) + itemWidth

                if nextWidth > availableWidth, !result.last!.isEmpty {
                    result.append([item])
                    currentRowWidth = itemWidth
                } else {
                    result[result.count - 1].append(item)
                    currentRowWidth = nextWidth
                }
            }
            return result
        }
    }
}

private struct SizeReader: ViewModifier {
    let onChange: (CGSize) -> Void
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        modifier(SizeReader(onChange: onChange))
    }
}

#Preview {
    let p = Profile()
    p.name = "Testing"
    p.majors = ["Computer Science 28’"]
    p.minors = ["Game Design"]
    p.college = "Engineering"
    p.courses = ["CS 3110", "CS 2800", "MATH 2930", "CHIN 1109", "INFO 1998"]
    p.selectedTimes = [.day, .morning]
    p.selectedLocations = [.library, .studyHall]
    let session = SessionStore()
    return EditProfilePage()
        .environmentObject(p)
        .environmentObject(session)
}
