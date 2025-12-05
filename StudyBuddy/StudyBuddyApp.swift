//
//  StudyBuddyApp.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 11/24/25.
//

import SwiftUI

@main
struct StudyBuddyApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .environmentObject(session.profile)
                .task {
                    await session.restoreOnLaunch()
                }
        }
    }
}
