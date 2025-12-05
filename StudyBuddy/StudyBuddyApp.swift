//
//  StudyBuddyApp.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 11/24/25.
//

import SwiftUI

@main
struct StudyBuddyApp: App {
    @StateObject private var profile = Profile()
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profile)
                .environmentObject(session)
                .task {
                    await session.restoreOnLaunch()
                }
        }
    }
}
