//
//  Swipe Through Profiles.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 11/24/25.
//

import SwiftUI

struct SwipeThroughProfiles: View {
    var body: some View {
        NavigationStack{
            ZStack {
                Color(hex: 0x9E122C)
                    .ignoresSafeArea()
                Image(.swipeThroughImg)
                    .resizable()
                    .scaledToFit()
                    .frame(alignment: .bottom)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea()
                
                VStack {
                    Image(.findYourMatch)
                    Spacer()
                    Text("Swipe Through Profiles")
                        .bold()
                        .font(.system(size: 24))
                    Text("Discover new people taking the same courses to study with!")
                        .font(.system(size: 16))
                        .padding (.vertical, 20)
                        .padding(.horizontal, 56)
                        .foregroundStyle(Color(hex: 0x9E122C))
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor((Color(hex: 0xB4B4B4)))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor((Color(hex: 0x9E122C)))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor((Color(hex: 0x9E122C)))
                    }
                    
                    NavigationLink(destination: FindYourMatch()) {
                        Text("Next")
                            .font(.system(size: 20))
                            .bold()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color(hex: 0xFBCB77))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity, alignment: .center)
                
                VStack {
                    HStack {
                        Image(.studyBuddyLogo)
                            .renderingMode(.original)
                            .frame(width: 42, height: 48)
                            .accessibilityHidden(true)
                        Spacer()
                    }
                    .padding(.top, 30)
                    .padding(.leading, 30)
                    
                    Spacer()
                }
                .ignoresSafeArea(.keyboard)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    NavigationStack {
        SwipeThroughProfiles()
    }
}
