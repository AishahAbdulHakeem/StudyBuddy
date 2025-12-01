//
//  HomePage.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/1/25.
//

import SwiftUI

struct HomePage: View {
    var body: some View {
        NavigationStack {
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
            
            ZStack {
                HStack {
                    NavigationLink(destination: CalendarPage()) {
                        Image("StuddyBuddyIcon")
                    }
                    NavigationLink(destination: CalendarPage()) {
                        Image("CalendarIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color(.white))
                    }
                    NavigationLink(destination: ExplorePage()) {
                        Image("ExploreIcon")
                            .resizable()
                    }
                    NavigationLink(destination: MessagesPage()) {
                        Image(systemName: "message")
                            .resizable()
                    }
                    NavigationLink(destination: ProfilePage()) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color(.white))
                    }
                }
            }
        }
    }
}
#Preview {
    HomePage()
}

//Color(hex: 0x9E122C)
//    .ignoresSafeArea()
// Profile, Messages, Explore, Calendar, Home
