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
            if let img = UIImage(named: user.avatarImageName) {
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

#Preview {
    let dto = APIManager.RichProfileDTO(
        id: 1,
        user_id: 2,
        courses: [],
        majors: [],
        study_area: nil,
        study_times: [],
        has_profile_image_blob: false,
        profile_image_blob_base64: nil,
        profile_image_blob_url: nil,
        profile_image_mime: nil
    )
    let mu = MatchUser(dto: dto)
    return MatchPopup(user: mu, visible: .constant(true))
}
