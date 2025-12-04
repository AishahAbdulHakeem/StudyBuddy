//
//  StudyBuddyApp.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 11/24/25.
//

import SwiftUI

@main
struct StudyBuddyApp: App {
    // Shared profile instance for the entire app
    @StateObject private var profile = Profile()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profile)
                .task {
                    // TODO: Load the current user's profile from your API here.
                    await loadProfile()
                }
        }
    }

    // MARK: - Networking placeholder
    private func loadProfile() async {
        // Replace with your real network call.
        // Example stub to show where to assign:
        await MainActor.run {
            profile.name = "Your Name"
            profile.major = "Your Major"
            profile.favoriteArea = "Library"
            profile.courses = ["CS 101", "MATH 221"]
            profile.selectedTimes = [.morning, .night]
            // profile.photoData = ... // assign from API if available
        }
    }
}
