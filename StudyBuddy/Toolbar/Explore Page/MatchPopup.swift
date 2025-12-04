//
//  MatchPopup.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/3/25.
//

import SwiftUI

struct MatchPopup: View {
    let user: DummyUser
    @Binding var visible: Bool

    var body: some View {
        if visible {
            ZStack {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("It’s a Match!")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Image(user.avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())

                    Text(user.name)
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Button("Go to Messages") {
                        visible = false
                        // Navigate to messages
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(radius: 30)
                .transition(.scale)
            }
            .animation(.easeOut, value: visible)
        }
    }
}
