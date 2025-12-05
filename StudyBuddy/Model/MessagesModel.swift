//
//  MessagesModel.swift
//  StudyBuddy
//
//  Created by black dune house loaner on 12/3/25.
//

import SwiftUI
import Combine

class MessagesModel: ObservableObject {
    @Published var matches: [MatchUser] = []
}
