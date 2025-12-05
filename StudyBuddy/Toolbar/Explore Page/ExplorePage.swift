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
    @EnvironmentObject var session: SessionStore

    @State private var matches: [MatchUser] = []
    @State private var index: Int = 0
    @State private var offset: CGSize = .zero
    @State private var showMatchPopup = false
    @State private var goToMessages = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let brandRed = Color(hex: 0x9E122C)

    private var currentUser: MatchUser? {
        guard !matches.isEmpty, index >= 0, index < matches.count else { return nil }
        return matches[index]
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if isLoading {
                    ProgressView()
                } else if let user = currentUser {
                    SwipeCardContainer(
                        offset: $offset,
                        isMatched: $showMatchPopup,
                        onSwipeLeft: handleReject,
                        onSwipeRight: handleMatchAndNavigate
                    ) {
                        ProfileCardView(user: user)
                            .environmentObject(profile)
                            .padding(.horizontal, 10)
                            .padding(.top, 12)
                    }
                    .padding(.bottom, 160)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Text("No matches yet. Try adding more courses to your profile.")
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 60)
                }

                if let user = currentUser {
                    MatchPopup(
                        user: user,
                        visible: $showMatchPopup
                    )
                }

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
                .padding(.horizontal, 24)
                .padding(.bottom, 70)

                NavigationLink(
                    destination: MessagesPage(),
                    isActive: $goToMessages
                ) { EmptyView() }
                .hidden()

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
            .task {
                await loadMatches()
            }
        }
    }

    private func loadMatches() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: "http://34.21.81.90/profiles/") else {
            errorMessage = "Invalid profiles URL."
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let dtos = try decoder.decode([APIManager.RichProfileDTO].self, from: data)

            let myCourses = Set(
                profile.courses
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                    .filter { !$0.isEmpty }
            )
            print("[Explore] My courses (normalized): \(Array(myCourses))")

            let filtered = dtos.filter { dto in
                guard let uid = dto.user_id else { return false }
                if let currentId = session.userId, uid == currentId { return false }
                let otherCourses = Set(
                    (dto.courses ?? [])
                        .compactMap { $0.code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                        .filter { !$0.isEmpty }
                )
                let intersects = !myCourses.intersection(otherCourses).isEmpty
                if intersects {
                    print("[Explore] Candidate user_id=\(uid) shares courses: \(Array(otherCourses))")
                }
                return !myCourses.isEmpty && intersects
            }

            let mapped = filtered
                .map { MatchUser(dto: $0) }
                .filter { $0.id > 0 }
            
            await MainActor.run {
                self.matches = mapped
                self.index = 0
            }


        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load profiles."
            }
        }
    }

    private func handleMatchAndNavigate() {
        guard let user = currentUser else { return }
        guard let me = session.userId else { return }

        print("[Swipe] Attempt LIKE me=\(me) target(userId)=\(user.id)")

        APIManager.shared.recordSwipe(swiperId: me, targetId: user.id, status: "LIKE") { result in
            switch result {
            case .success(let res):
                let matched = res.match_found ?? false
                print("[Swipe] LIKE result match_found=\(matched), new_match_id=\(res.new_match_id ?? -1)")
                guard matched else {
                    DispatchQueue.main.async {
                        print("[Swipe] Not a mutual match yet; advancing to next card")
                        self.loadNext()
                    }
                    return
                }
                DispatchQueue.main.async {
                    if !self.messages.matches.contains(user) {
                        self.messages.matches.append(user)
                        print("[Swipe] Added to MessagesModel.matches (count=\(self.messages.matches.count))")
                    }
                    self.showMatchPopup = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.goToMessages = true
                        self.loadNext()
                    }
                }
            case .failure(let err):
                print("[Swipe] LIKE failed: \(err.localizedDescription)")
                DispatchQueue.main.async {
                    self.loadNext()
                }
            }
        }
    }

    private func handleReject() {
        if let me = session.userId, let user = currentUser {
            print("[Swipe] Attempt DISLIKE me=\(me) target(userId)=\(user.id)")
            APIManager.shared.recordSwipe(swiperId: me, targetId: user.id, status: "DISLIKE") { result in
                if case .failure(let err) = result {
                    print("[Swipe] DISLIKE failed: \(err.localizedDescription)")
                } else {
                    print("[Swipe] DISLIKE recorded")
                }
            }
        }
        loadNext()
    }

    private func loadNext() {
        if matches.isEmpty { return }
        index = (index + 1) % matches.count
        offset = .zero
        showMatchPopup = false
        print("[Explore] Advanced to index \(index) / \(matches.count)")
    }
}

#Preview {
    ExplorePage()
        .environmentObject(MessagesModel())
        .environmentObject(Profile())
        .environmentObject(SessionStore())
}
