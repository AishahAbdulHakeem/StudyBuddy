//
//  ContentView.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 11/24/25.
//

import SwiftUI


struct LoadingIndicatorView: View {
    var body: some View {
        ZStack {
            Color(hex: 0xB40023)
                .ignoresSafeArea()
            VStack {
                Image(.studyBuddyLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 85)
                    .foregroundStyle(Color(.white))
                Image(.studyBuddy) // A standard SwiftUI progress indicator
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .foregroundStyle(Color(.white))
            }
        }
    }
}
struct LoadedContentView: View {
    var body: some View {
        ZStack {
            Color(hex: 0xB40023)
                .ignoresSafeArea()
//            Text("Welcome to StudyBuddy!")
//                .font(.title)
            SwipeThroughProfiles()
        }
    }
}
struct ContentView: View {
    @State private var isLoading = true
            var body: some View {
                VStack {
                    if isLoading {
                        LoadingIndicatorView() // A custom view for the loading state
                    } else {
                        LoadedContentView() // The actual content to display after loading
                    }
                }
                .onAppear {
                    // Simulate a network request or data fetching
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        isLoading = false // Set to false when loading is complete
                    }
                }
            }
        }


#Preview {
    // Provide all EnvironmentObjects that any descendant may need
    let profile = Profile()
    let messages = MessagesModel()

    // Seed some optional preview data if you like
    profile.name = "Preview User"
    profile.majors = ["Computer Science 28’"]
    profile.selectedTimes = [.day, .morning]
    profile.selectedLocations = [.library]

    messages.matches = [
        DummyUser(name: "Alice Chen", major: "CS 2027", avatar: "avatar1")
    ]

    return ContentView()
        .environmentObject(profile)
        .environmentObject(messages)
}
