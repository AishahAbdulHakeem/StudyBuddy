//
//  ResetPw.swift
//  StudyBuddy
//
//  Created by Aishah A on 11/25/25.
//

import SwiftUI

struct ResetPw: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var username: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    // Validation UI
    @State private var errorMessage: String? = nil
    @State private var didAttemptSubmit = false
    
    // Navigation to LogIn after success
    @State private var goToLogin = false
    
    private let brandRed = Color(hex: 0x9E122C)
    private let fieldBorder = Color(.systemGray3)
    private let brandGreen = Color(.systemGreen)
    
    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    private var meetsLength: Bool { newPassword.count >= 10 }
    private var hasUppercase: Bool { newPassword.range(of: "[A-Z]", options: .regularExpression) != nil }
    private var hasNumber: Bool { newPassword.range(of: "[0-9]", options: .regularExpression) != nil }
    private var meetsAllRules: Bool { meetsLength && hasUppercase && hasNumber }
    
    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && meetsAllRules
        && passwordsMatch
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hidden NavigationLink to LogIn
                    NavigationLink(destination: LogIn(), isActive: $goToLogin) {
                        EmptyView()
                    }
                    .hidden()
                    
                    // Logo
                    Image("StudyBuddySignUpLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 120)
                        .padding(.top, 24)
                    
                    // Titles
                    VStack(spacing: 6) {
                        Text("Change your password")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Enter a new password below to change a password")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 28)
                    }
                    
                    // Form
                    VStack(spacing: 14) {
                        // Username or Email
                        TextField("Username or Email", text: $username)
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(fieldBorder, lineWidth: 1)
                            )
                        
                        // New Password
                        HStack {
                            Group {
                                if showNewPassword {
                                    TextField("New password", text: $newPassword)
                                        .onChange(of: newPassword) { _ in clearErrorsIfResolved() }
                                } else {
                                    SecureField("New password", text: $newPassword)
                                        .onChange(of: newPassword) { _ in clearErrorsIfResolved() }
                                }
                            }
                            .textContentType(.newPassword)
                            
                            Button {
                                withAnimation { showNewPassword.toggle() }
                            } label: {
                                Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(fieldBorder, lineWidth: 1)
                        )
                        
                        // Confirm Password
                        HStack {
                            Group {
                                if showConfirmPassword {
                                    TextField("Re-enter new password", text: $confirmPassword)
                                        .onChange(of: confirmPassword) { _ in clearErrorsIfResolved() }
                                } else {
                                    SecureField("Re-enter new password", text: $confirmPassword)
                                        .onChange(of: confirmPassword) { _ in clearErrorsIfResolved() }
                                }
                            }
                            .textContentType(.newPassword)
                            
                            Button {
                                withAnimation { showConfirmPassword.toggle() }
                            } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(fieldBorder, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Requirements
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password must contain:")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("At least 10 characters")
                                .foregroundStyle(meetsLength ? brandGreen : brandRed)
                            Text("At least one uppercase letter (A–Z)")
                                .foregroundStyle(hasUppercase ? brandGreen : brandRed)
                            Text("At least one number (0–9)")
                                .foregroundStyle(hasNumber ? brandGreen : brandRed)
                        }
                        .animation(.easeInOut(duration: 0.2), value: meetsLength)
                        .animation(.easeInOut(duration: 0.2), value: hasUppercase)
                        .animation(.easeInOut(duration: 0.2), value: hasNumber)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    
                    // Reset Button
                    Button {
                        didAttemptSubmit = true
                        validateAndSubmit()
                    } label: {
                        Text("Reset password")
                            .font(.system(size: 20, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(brandRed)
                            )
                            .shadow(color: brandRed.opacity(0.2), radius: 6, y: 3)
                            .opacity(canSubmit ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, 24)
                    .disabled(!canSubmit)
                    
                    // Error message (below the button)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(brandRed)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func clearErrorsIfResolved() {
        if passwordsMatch && meetsAllRules {
            withAnimation { errorMessage = nil }
        } else if errorMessage != nil && passwordsMatch == false {
            // keep showing mismatch error until resolved
        }
    }
    
    private func validateAndSubmit() {
        // Order: ensure fields filled, rules, then match
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            withAnimation { errorMessage = "Please enter your username or email." }
            return
        }
        if !meetsAllRules {
            withAnimation { errorMessage = "Password does not meet the requirements." }
            return
        }
        if !passwordsMatch {
            withAnimation { errorMessage = "The passwords must match**" }
            return
        }
        
        // Clear error and proceed with reset flow
        withAnimation { errorMessage = nil }
        // TODO: Trigger your reset request here
        
        // Navigate back to LogIn screen
        goToLogin = true
    }
}

#Preview {
    ResetPw()
}
