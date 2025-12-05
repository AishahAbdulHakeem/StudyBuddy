//
//  ContentView.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 11/24/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        Group {
            if session.isAuthenticated {
                SwipeThroughProfiles()
            } else {
                SwipeThroughProfiles()
            }
        }
    }
}

#Preview {
    let session = SessionStore()
    return ContentView()
        .environmentObject(session)
        .environmentObject(session.profile)
}
