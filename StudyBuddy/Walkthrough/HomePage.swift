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
            VStack {
                Spacer()
                
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
                .padding (.top, 40)
                
                Spacer()
                
                ZStack {
                    HStack(spacing: 40) {
                            
                            NavigationLink(destination: HomePage()) {
                                Image("StudyBuddyLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
//                                    .padding(.bottom)

                            }
                            
                            NavigationLink(destination: CalendarPage()) {
                                Image(systemName: "calendar")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
//                                    .padding(.bottom)

                            }
                            
                            NavigationLink(destination: ExplorePage()) {
                                Image(systemName: "hand.raised.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
//                                    .padding(.bottom)

                            }
                            
                            NavigationLink(destination: MessagesPage()) {
                                Image(systemName: "message")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color(.white))
//                                    .padding(.bottom)

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
                .fill(Color(hex: 0x9E122C))
                .frame(width: 400, height: 100)
                      )
            }
            .ignoresSafeArea()
        }
    }
}
    #Preview {
        HomePage()
    }
    
    
