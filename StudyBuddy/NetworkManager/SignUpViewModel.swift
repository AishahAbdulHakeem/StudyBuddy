//
//  SignUpViewModel.swift
//  StudyBuddy
//
//  Created by Aishah A on 12/4/25.
//

import Foundation
import Combine

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signUp(username: String, email: String, password: String) async -> SignupUser? {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        return await withCheckedContinuation { continuation in
            APIManager.shared.signUp(username: username, email: email, password: password) { [weak self] result in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }
                switch result {
                case .success(let res):
                    if res.statusCode == 201 {
                        continuation.resume(returning: res.user)
                    } else {
                        self.errorMessage = "Signup failed."
                        continuation.resume(returning: nil)
                    }
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
