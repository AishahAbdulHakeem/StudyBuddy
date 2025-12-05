//
//  SwipeCardContainer.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/1/25.
//
import SwiftUI

struct SwipeCardContainer<Content: View>: View {
    @Binding var offset: CGSize
    @Binding var isMatched: Bool

    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let content: () -> Content

    var body: some View {
        ZStack {
            content()
                .scaleEffect(scaleAmount)
                .blur(radius: blurAmount)
                .rotationEffect(.degrees(Double(offset.width / 15)))
                .shadow(radius: shadowAmount)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            offset = gesture.translation
                        }
                        .onEnded { _ in
                            handleSwipe()
                        }
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: offset)

            if offset.width > 80 {
                matchStamp("MATCH", color: .green)
                    .offset(x: -80, y: -200)
                    .opacity(Double((offset.width - 80) / 120))
            }

            if offset.width < -80 {
                matchStamp("NO THANKS", color: .red)
                    .offset(x: 80, y: -200)
                    .opacity(Double((-offset.width - 80) / 120))
            }
        }
    }

    private var scaleAmount: CGFloat {
        let distance = abs(offset.width)
        return max(0.9, 1 - distance / 1500)
    }

    private var blurAmount: CGFloat {
        let distance = abs(offset.width)
        return distance / 80
    }

    private var shadowAmount: CGFloat {
        let distance = abs(offset.width)
        return distance / 15
    }

    private func handleSwipe() {
        if offset.width > 120 {
            withAnimation(.spring()) {
                offset = CGSize(width: 600, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onSwipeRight()
                isMatched = true
                offset = .zero
            }
        } else if offset.width < -120 {
            withAnimation(.spring()) {
                offset = CGSize(width: -600, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onSwipeLeft()
                offset = .zero
            }
        } else {
            offset = .zero
        }
    }

    private func matchStamp(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.largeTitle.bold())
            .padding(12)
            .background(color.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 4)
            )
            .foregroundColor(color)
            .rotationEffect(.degrees(-20))
    }
}

#Preview {
    SwipeCardContainer(
        offset: .constant(.zero),
        isMatched: .constant(false),
        onSwipeLeft: {},
        onSwipeRight: {}
    ) {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 300, height: 400)
    }
}
