//
//  PreExplore.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/1/25.
//

import SwiftUI

struct LoadingPreExploreView: View {
    var body: some View {
        
//            Color(hex: 0xFFFFFF)
//                .ignoresSafeArea()
            HStack {
                Image(.studyBuddyLogoRed)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 64)
                    .foregroundStyle(Color(.white))
                Image(.studyBuddyTextRed) // A standard SwiftUI progress indicator
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 41)
                    .foregroundStyle(Color(.white))

        }
            .padding (386)
    }
}
struct LoadedPreExploreView: View {
    var body: some View {
        ZStack {
            Color(hex: 0xFFFFFF)
                .ignoresSafeArea()
//            ExplorePage()
            HomePage()
        }
    }
}
struct PreExplore: View {
    @State private var isLoading = true
            var body: some View {
                VStack {
                    if isLoading {
                        LoadingPreExploreView() // A custom view for the loading state
                    } else {
                        LoadedPreExploreView() // The actual content to display after loading
                    }
                }
                .onAppear {
                    // Simulate a network request or data fetching
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false // Set to false when loading is complete
                    }
                }
            }
        }


#Preview {
    PreExplore()
}
