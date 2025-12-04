//
//  Explore.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/1/25.
//

import SwiftUI

struct ExplorePage: View {
    @EnvironmentObject var messages: MessagesModel
    @EnvironmentObject var profile: Profile

    @State private var users = dummyUsers
    @State private var index = 0

    @State private var offset: CGSize = .zero
    @State private var showMatchPopup = false
    @State private var goToMessages = false

    // Branding
    private let brandRed = Color(hex: 0x9E122C)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                // MARK: - Swipe Container + Card
                SwipeCardContainer(
                    offset: $offset,
                    isMatched: $showMatchPopup,
                    onSwipeLeft: handleReject,
                    onSwipeRight: handleMatchAndNavigate
                ) {
                    ProfileCardView(
                        user: users[index]
                    )
                    .environmentObject(profile)
                    .padding(.horizontal, 16)
//                    .padding(.top, 12)
                }
                .padding(.bottom, 140) // leave space for big buttons and bottom bar

                // MARK: - Match popup (optional visual)
                MatchPopup(
                    user: users[index],
                    visible: $showMatchPopup
                )

                // MARK: - Big action buttons (X and Check) like the mock
                HStack {
                    Button {
                        withAnimation { offset = CGSize(width: -600, height: 0) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            handleReject()
                            offset = .zero
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(brandRed)
                                .frame(width: 68, height: 68)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 6)
                            Image(systemName: "xmark")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    Button {
                        handleMatchAndNavigate()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(brandRed, lineWidth: 4)
                                .frame(width: 68, height: 68)
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
                            Image(systemName: "checkmark")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(brandRed)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 60) // sits above your bottom nav bar

                // Hidden programmatic navigation to Messages
                NavigationLink(destination: MessagesPage()
                    .environmentObject(messages),
                               isActive: $goToMessages) {
                    EmptyView()
                }
                .hidden()

                // Bottom bar (reuse your existing style if you want it here)
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
                            .fill(brandRed)
                            .frame(width: 400, height: 100)
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Swipe Logic
    private func handleMatchAndNavigate() {
        let matchedUser = users[index]
        if !messages.matches.contains(matchedUser) {
            messages.matches.append(matchedUser)
        }
        showMatchPopup = true

        // Small delay for feedback, then go to Messages
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            goToMessages = true
            loadNext()
        }
    }

    private func handleReject() {
        loadNext()
    }

    private func loadNext() {
        index = (index + 1) % users.count
        offset = .zero
        showMatchPopup = false
    }
}

#Preview {
    ExplorePage()
        .environmentObject(MessagesModel())
        .environmentObject(Profile())
}
