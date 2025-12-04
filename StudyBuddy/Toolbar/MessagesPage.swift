//
//  Messages.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/1/25.
//

import SwiftUI

struct MessagesPage: View {
    @EnvironmentObject var messages: MessagesModel

    private let brandRed = Color(hex: 0x9E122C)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content
                VStack(alignment: .leading, spacing: 16) {

                    // Logo
                    HStack {
                        Image("StudyBuddyLogoRed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                    // Horizontal strip of matches (avatars)
                    if !messages.matches.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(messages.matches) { user in
                                    VStack(spacing: 6) {
                                        avatar(for: user)
                                            .frame(width: 64, height: 64)
                                        Text(user.name.split(separator: " ").first.map(String.init) ?? user.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                    } else {
                        Text("No matches yet. Swipe right in Explore!")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                    }

                    // Vertical list (placeholder conversations = matches)
                    List {
                        ForEach(messages.matches) { user in
                            HStack(spacing: 16) {
                                avatar(for: user)
                                    .frame(width: 48, height: 48)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text("Say hi 👋")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)

                    Spacer(minLength: 120) // leave space so content isn't under the bar
                }
                .padding(.top, 8)

                // Bottom bar (matches HomePage/ProfilePage/CalendarPage)
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
                            // Current page highlighted (filled icon)
                            Image(systemName: "message.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(Color(.white))
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
                            .fill(brandRed)
                            .frame(width: 400, height: 100)
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func avatar(for user: DummyUser) -> some View {
        Group {
            if let ui = UIImage(named: user.avatar) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Circle().fill(Color(.systemGray4))
            }
        }
    }
}

#Preview {
    let model = MessagesModel()
    model.matches = [
        DummyUser(name: "Alice Chen", major: "CS 2027", avatar: "avatar1"),
        DummyUser(name: "Brian Lee", major: "ECE 2026", avatar: "avatar2"),
        DummyUser(name: "Carla Kim", major: "Info Sci 2025", avatar: "avatar3")
    ]
    return MessagesPage().environmentObject(model)
}
