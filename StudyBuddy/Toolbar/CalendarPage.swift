//
//  Calendar.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/1/25.
//

import SwiftUI

struct CalendarPage: View {
    @EnvironmentObject var profile: Profile
    
    // Branding
    private let brandRed = Color(hex: 0x9E122C)
    private let brandYellow = Color(hex: 0xFBCB77)
    private let border = Color(.label).opacity(0.35)
    
    // Calendar state
    @State private var displayedMonth: Date = Date()
    @State private var isEditing: Bool = false
    @State private var sheetDay: DayID? = nil
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1 // Sunday
        return cal
    }
    
    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.calendar = calendar
        fmt.locale = .current
        fmt.dateFormat = "LLLL"
        return fmt.string(from: displayedMonth)
    }
    
    private var yearTitle: String {
        let comps = calendar.dateComponents([.year], from: displayedMonth)
        return String(comps.year ?? 0)
    }
    
    private var daysInGrid: [DateValue] {
        makeMonthGrid(for: displayedMonth, using: calendar)
    }
    
    // Events in the displayed month (for the list section)
    private var eventsInDisplayedMonth: [StudySessionEvent] {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let start = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: start),
              let end = calendar.date(byAdding: .day, value: range.count, to: start)
        else { return [] }
        // Collect events for each day in the month
        var all: [StudySessionEvent] = []
        var day = start
        while day < end {
            all.append(contentsOf: profile.events[calendar.startOfDay(for: day)] ?? [])
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? end
        }
        return all
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        
                        // Top icon + title row like mock
                        HStack {
                            Image("StuddyBuddyLogoRed")
                                .font(.system(size: 28))
                                .foregroundStyle(brandRed)
                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                        
                        Text(isEditing ? "Editing your availability" : "Your calendar")
                            .font(.headline.weight(.semibold))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 4)
                        
                        // Calendar card
                        VStack(spacing: 8) {
                            header
                            weekdayHeader
                            grid
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(border, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // Edit button or legend
                        if !isEditing {
                            HStack {
                                Spacer()
                                Button {
                                    isEditing = true
                                } label: {
                                    Text("Edit availability")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(brandRed)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            legend.padding(.horizontal, 20)
                        }
                        
                        // Events section (pulls from profile.events for displayed month)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Events")
                                .font(.headline)
                            if eventsInDisplayedMonth.isEmpty {
                                Text("No events this month yet.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(eventsInDisplayedMonth) { ev in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(ev.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Text("Participants: \(ev.participants.joined(separator: ", "))")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                            Text(eventWhenLabel(ev))
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(border, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                            .accessibilityHidden(true)
                    }
                    .padding(.bottom, 16)
                }
                
                // Bottom bar (reuse style)
                bottomBar
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Done") { isEditing = false }
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .sheet(item: $sheetDay) { dayID in
                AvailabilitySheet(
                    date: dayID.date,
                    allowed: Profile.AvailabilityWindow.allowed(for: profile.selectedTimes),
                    current: profile.availability[dateOnly(dayID.date)] ?? [],
                    brandRed: brandRed
                ) { newSelection in
                    profile.availability[dateOnly(dayID.date)] = newSelection.isEmpty ? nil : Set(newSelection)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack {
            Text("\(monthTitle) \(yearTitle)")
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                withAnimation { displayedMonth = monthOffset(-1, from: displayedMonth) }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.primary)
            }
            Button {
                withAnimation { displayedMonth = monthOffset(1, from: displayedMonth) }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }
    
    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols // ["Sun","Mon",...]
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { idx in
                Text(symbols[idx])
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(daysInGrid) { value in
                dayCell(value)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(border, lineWidth: 1)
        )
    }
    
    private func dayCell(_ value: DateValue) -> some View {
        let isCurrentMonth = value.isCurrentMonth
        let day = value.day
        let date = value.date
        let key = dateOnly(date)
        let isToday = calendar.isDateInToday(date)
        let hasAvailability = (profile.availability[key]?.isEmpty == false)
        let windows = profile.availability[key] ?? []
        let hasEvents = !(profile.events[key]?.isEmpty ?? true)
        
        return ZStack {
            // Today indicator: circular badge behind the number
            if isToday, day > 0, isCurrentMonth {
                Circle()
                    .fill(brandYellow.opacity(0.9))
                    .frame(width: 24, height: 24)
                    .offset(y: -2)
            }
            
            VStack(spacing: 2) {
                // Day number
                Text(day > 0 ? String(day) : "")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isCurrentMonth ? Color.primary : Color.secondary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .zIndex(1)
                
                // Availability icons
                if !windows.isEmpty, day > 0, isCurrentMonth {
                    availabilityPreview(for: windows)
                        .padding(.top, 0)
                }
                
                // Event badge (tiny dot) if there are events that day
                if hasEvents, day > 0, isCurrentMonth {
                    Circle()
                        .fill(brandRed)
                        .frame(width: 5, height: 5)
                        .padding(.top, 1)
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .overlay(
            // Red outline when availability exists
            RoundedRectangle(cornerRadius: 0)
                .stroke(hasAvailability ? brandRed : Color.clear, lineWidth: hasAvailability ? 2 : 0)
                .padding(2)
        )
        .frame(height: 40)
        .overlay(
            Rectangle()
                .stroke(border.opacity(0.6), lineWidth: 0.5)
        )
        .onTapGesture {
            guard isEditing, isCurrentMonth, day > 0 else { return }
            sheetDay = DayID(id: key)
        }
    }
    
    // Small icon row summarizing selected windows
    // size parameter lets us reuse it for both compact cells and larger legend
    private func availabilityPreview(for windows: Set<Profile.AvailabilityWindow>, size: CGFloat = 9, spacing: CGFloat = 3) -> some View {
        let ordered: [Profile.AvailabilityWindow] = [.morning9to11, .day4to7, .night7to12]
        let selected = ordered.filter { windows.contains($0) }
        return HStack(spacing: spacing) {
            ForEach(selected, id: \.self) { win in
                Image(systemName: win.icon)
                    .font(.system(size: size))
                    .foregroundStyle(brandRed)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func eventWhenLabel(_ ev: StudySessionEvent) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let day = df.string(from: ev.date)
        if let start = ev.startTime {
            if let end = ev.endTime {
                let st = df.string(from: start)
                let et = df.string(from: end)
                return "When: \(day) • \(st) – \(et)"
            } else {
                let st = df.string(from: start)
                return "When: \(day) • \(st)"
            }
        } else {
            return "When: \(day)"
        }
    }
    
    private var legend: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(brandRed, lineWidth: 2)
                    .frame(width: 18, height: 18)
                Text("available")
                    .font(.subheadline)
            }
            HStack(spacing: 10) {
                Circle()
                    .fill(brandYellow.opacity(0.9))
                    .frame(width: 18, height: 18)
                Text("today's date")
                    .font(.subheadline)
            }
            HStack(spacing: 10) {
                availabilityPreview(for: [.morning9to11, .day4to7, .night7to12], size: 18, spacing: 6)
                Text("selected windows")
                    .font(.subheadline)
            }
            HStack(spacing: 10) {
                Circle()
                    .fill(brandRed)
                    .frame(width: 6, height: 6)
                Text("event on this day")
                    .font(.subheadline)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(border, lineWidth: 1)
                )
        )
    }
    
    private var bottomBar: some View {
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
    
    // MARK: - Calendar building
    
    private struct DateValue: Identifiable {
        let id = UUID()
        let day: Int          // 1...31 or 0 for filler cells
        let date: Date
        let isCurrentMonth: Bool
    }
    
    private func makeMonthGrid(for month: Date, using cal: Calendar) -> [DateValue] {
        guard
            let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month)),
            let range = cal.range(of: .day, in: .month, for: firstOfMonth)
        else { return [] }
        
        let firstWeekday = cal.component(.weekday, from: firstOfMonth) // 1...7
        var result: [DateValue] = []
        
        // Leading blanks
        for _ in 0..<(firstWeekday - cal.firstWeekday + 7) % 7 {
            result.append(DateValue(day: 0, date: firstOfMonth, isCurrentMonth: false))
        }
        
        // Actual days
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                result.append(DateValue(day: day, date: d, isCurrentMonth: true))
            }
        }
        
        // Trailing to complete rows of 7
        while result.count % 7 != 0 {
            if let last = result.last?.date,
               let next = cal.date(byAdding: .day, value: 1, to: last) {
                result.append(DateValue(day: cal.component(.day, from: next), date: next, isCurrentMonth: false))
            } else {
                result.append(DateValue(day: 0, date: month, isCurrentMonth: false))
            }
        }
        return result
    }
    
    private func monthOffset(_ delta: Int, from base: Date) -> Date {
        calendar.date(byAdding: DateComponents(month: delta), to: startOfMonth(base)) ?? base
    }
    
    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
    
    private func dateOnly(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
}

// MARK: - Availability selection sheet

private struct AvailabilitySheet: View {
    let date: Date
    let allowed: [Profile.AvailabilityWindow]
    let current: Set<Profile.AvailabilityWindow>
    let brandRed: Color
    var onChange: (Set<Profile.AvailabilityWindow>) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<Profile.AvailabilityWindow> = []
    
    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .full
        return fmt.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Choose your availability")) {
                    ForEach(allowed) { window in
                        let isOn = selection.contains(window)
                        Button {
                            toggle(window)
                        } label: {
                            HStack {
                                Image(systemName: window.icon)
                                    .foregroundStyle(isOn ? brandRed : .secondary)
                                Text(window.label)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if isOn {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(brandRed)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(dateLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onChange(selection)
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear { selection = current }
        }
    }
    
    private func toggle(_ w: Profile.AvailabilityWindow) {
        if selection.contains(w) { selection.remove(w) } else { selection.insert(w) }
    }
}

// Identifiable wrapper for Date for use with sheet(item:)
private struct DayID: Identifiable, Equatable {
    let id: Date
    var date: Date { id }
}

#Preview {
    let p = Profile()
    p.selectedTimes = [.morning, .day]
    // Example seeded event for preview
    let today = Calendar.current.startOfDay(for: Date())
    p.events[today] = [
        StudySessionEvent(date: today, participants: ["You", "Winnie Chan"], course: "CS 3110", startTime: Date())
    ]
    return CalendarPage().environmentObject(p)
}
