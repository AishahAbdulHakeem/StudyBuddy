//
//  Find Your Match.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 11/24/25.
//

import SwiftUI

struct FindYourMatch: View {
    var body: some View {
        NavigationStack{
            ZStack {
                Color(hex: 0x9E122C)
                    .ignoresSafeArea()
                Image(.findYourMatchImg)
                    .resizable()
                    .scaledToFit()
                    .frame(alignment: .bottom)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea()
                
                Image(.findYourMatch)
                    .padding(.bottom, 320)
                    .frame(width: 256, height: 256)
                
                VStack {
                    Spacer()
                    Text("Find Your Match")
                        .bold()
                        .font(.system(size: 24))
                    Text("Connect with other students taking the same course, with similar study times as you!")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding (.vertical, 20)
                        .padding(.horizontal, 56)
                        .foregroundStyle(Color(hex: 0x9E122C))
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor((Color(hex: 0x9E122C)))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor((Color(hex: 0xB4B4B4)))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor((Color(hex: 0x9E122C)))
                    }
                    .padding(.bottom, 20)
                    NavigationLink(destination: SetUpStudySessions()) {
                        Text("Next")
                            .font(.system(size: 20))
                            .bold()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color(hex: 0xFBCB77))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 86)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                VStack {
                    HStack {
                        Image(.studyBuddyLogo)
                            .renderingMode(.original)
                            .frame(width: 42, height: 48)
                            .accessibilityHidden(true)
                            .padding(.bottom, )
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
        FindYourMatch()
    }
}
