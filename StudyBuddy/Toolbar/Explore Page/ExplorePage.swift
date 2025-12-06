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

    // Candidate model holds both the display user and its profileId for image fetches
    private struct Candidate: Identifiable, Equatable {
        let id: Int            // same as user.id for identity
        let user: MatchUser    // contains user-facing fields (uses user_id)
        let profileId: Int     // dto.id required to fetch /profiles/{id}/image/
        let hasImage: Bool
    }

    @State private var candidates: [Candidate] = []
    @State private var index: Int = 0
    @State private var offset: CGSize = .zero
    @State private var showMatchPopup = false
    @State private var goToMessages = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Cache of downloaded images keyed by profileId
    @State private var images: [Int: UIImage] = [:]

    private let brandRed = Color(hex: 0x9E122C)

    private var currentCandidate: Candidate? {
        guard !candidates.isEmpty, index >= 0, index < candidates.count else { return nil }
        return candidates[index]
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if isLoading {
                    ProgressView()
                } else if let cand = currentCandidate {
                    SwipeCardContainer(
                        offset: $offset,
                        isMatched: $showMatchPopup,
                        onSwipeLeft: handleReject,
                        onSwipeRight: handleMatchAndNavigate
                    ) {
                        ProfileCardView(
                            user: cand.user,
                            remoteImage: images[cand.profileId]
                        )
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

                if let cand = currentCandidate {
                    MatchPopup(
                        user: cand.user,
                        visible: $showMatchPopup,
                        remoteImage: images[cand.profileId]
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
                        HStack(spacing: 60) {
                            NavigationLink(destination: HomePage()) {
                                Image(.homeInactive)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
                            }

                            NavigationLink(destination: ExplorePage()) {
                                Image(.matchActive)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))

                            }
                            
                            NavigationLink(destination: MessagesPage()) {
                                Image(.messagesInactive)
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
            .task {
                await loadMatches()
            }
            .navigationBarBackButtonHidden(true) // Disable back button on Explore page
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

            // Filter candidates and keep profileId + hasImage flag
            let filtered = dtos.compactMap { dto -> Candidate? in
                guard let uid = dto.user_id else { return nil }
                if let currentId = session.userId, uid == currentId { return nil }

                let otherCourses = Set(
                    (dto.courses ?? [])
                        .compactMap { $0.code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                        .filter { !$0.isEmpty }
                )
                let intersects = !myCourses.intersection(otherCourses).isEmpty
                guard !myCourses.isEmpty && intersects else { return nil }

                let user = MatchUser(dto: dto)
                guard let profileId = dto.id else { return nil }
                let hasImage = dto.has_profile_image_blob == true
                return Candidate(id: user.id, user: user, profileId: profileId, hasImage: hasImage)
            }

            await MainActor.run {
                self.candidates = filtered
                self.index = 0
            }

            // Kick off image fetches for those with images
            await fetchImagesIfNeeded(for: filtered)

        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load profiles."
            }
        }
    }

    private func fetchImagesIfNeeded(for list: [Candidate]) async {
        for cand in list {
            guard cand.hasImage else { continue }
            // Skip if already cached
            if images[cand.profileId] != nil { continue }

            if let img = await APIManager.shared.fetchProfileImage(profileId: cand.profileId) {
                await MainActor.run {
                    images[cand.profileId] = img
                }
            }
        }
    }

    private func handleMatchAndNavigate() {
        guard let cand = currentCandidate else { return }
        guard let me = session.userId else { return }

        print("[Swipe] Attempt LIKE me=\(me) target(userId)=\(cand.user.id)")

        APIManager.shared.recordSwipe(swiperId: me, targetId: cand.user.id, status: "LIKE") { result in
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
                    if !self.messages.matches.contains(cand.user) {
                        self.messages.matches.append(cand.user)
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
        if let me = session.userId, let cand = currentCandidate {
            print("[Swipe] Attempt DISLIKE me=\(me) target(userId)=\(cand.user.id)")
            APIManager.shared.recordSwipe(swiperId: me, targetId: cand.user.id, status: "DISLIKE") { result in
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
        if candidates.isEmpty { return }
        index = (index + 1) % candidates.count
        offset = .zero
        showMatchPopup = false
        print("[Explore] Advanced to index \(index) / \(candidates.count)")
    }
}

#Preview {
    ExplorePage()
        .environmentObject(MessagesModel())
        .environmentObject(Profile())
        .environmentObject(SessionStore())
}
