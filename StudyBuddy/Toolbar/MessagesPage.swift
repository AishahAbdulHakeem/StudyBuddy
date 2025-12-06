import SwiftUI

struct MessagesPage: View {
    @EnvironmentObject var messages: MessagesModel
    @EnvironmentObject var session: SessionStore

    private let brandRed = Color(hex: 0x9E122C)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image("StudyBuddyLogoRed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

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

                    Spacer(minLength: 120)
                }
                .padding(.top, 8)

                VStack {
                    Spacer()
                    ZStack {
                        HStack(spacing: 60) {
                            NavigationLink(destination: HomePage()) {
                                Image(.homeInactive)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
                            }

                            NavigationLink(destination: ExplorePage()) {
                                Image(.matchInactive)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))

                            }

                            
                            NavigationLink(destination: MessagesPage()) {
                                Image(.messagesActive)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))

                            }

                            NavigationLink(destination: ProfilePage()) {
                                Image(.profileInactive)
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
            .navigationBarBackButtonHidden(true) // Disable back button on Messages page
        }
        .task {
            let loaded = await session.fetchMatches()
            messages.matches = loaded
        }
    }

    private func avatar(for user: MatchUser) -> some View {
        Group {
            if let ui = UIImage(named: user.avatarImageName) {
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
