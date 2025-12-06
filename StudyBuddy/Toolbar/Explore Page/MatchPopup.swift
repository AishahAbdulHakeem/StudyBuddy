//
//  MatchPopUp.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/1/25.
//

import SwiftUI

struct MatchPopup: View {
    let user: MatchUser
    @Binding var visible: Bool
    var remoteImage: UIImage? = nil

    private let brandRed = Color(hex: 0x9E122C)

    var body: some View {
        if visible {
            ZStack {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()

                VStack(spacing: 22) {
                    Text("It’s a Match!")
                        .font(.largeTitle.bold())
                        .foregroundColor(.black)

                    avatar

                    Text(user.name)
                        .font(.title.bold())
                        .foregroundColor(.black)

                    Button("Go to Messages") {
                        visible = false
                    }
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(brandRed)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.vertical, 35)
                .padding(.horizontal, 40)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: .black.opacity(0.25), radius: 20)
                .transition(.scale)
            }
            .animation(.easeOut, value: visible)
        }
    }

    private var avatar: some View {
        ZStack {
            if let remoteImage {
                Image(uiImage: remoteImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 6)
            } else if let img = UIImage(named: user.avatarImageName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 6)
            } else {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 120, height: 120)
                    .shadow(radius: 6)
            }
        }
    }
}


