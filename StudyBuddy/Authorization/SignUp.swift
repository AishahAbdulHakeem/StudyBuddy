//
//  SignUp.swift
//  StudyBuddy
//
//  Created by Aishah A on 11/25/25.
//

import SwiftUI

struct SignUp: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profile: Profile

    @StateObject private var viewModel = SignUpViewModel()
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var goToEditProfile = false
    
    private let brandRed = Color(hex: 0x9E122C)
    private let fieldBorder = Color(.systemGray3)
    
    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .topLeading) {
                Color(.systemBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo
                        Image("StudyBuddySignUpLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 120)
                            .padding(.top, 40)
                        
                        // Subtitle
                        Text("Ready to lock in?")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        // Form card
                        VStack(spacing: 14) {
                            // Username
                            TextField("Username", text: $username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(fieldBorder, lineWidth: 1)
                                )
                            
                            // Email
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(fieldBorder, lineWidth: 1)
                                )
                            
                            // Password with show/hide
                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                    } else {
                                        SecureField("Password", text: $password)
                                    }
                                }
                                .textContentType(.newPassword)
                                
                                Button {
                                    withAnimation { showPassword.toggle() }
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(fieldBorder, lineWidth: 1)
                            )
                            
                            if let error = viewModel.errorMessage, !error.isEmpty {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(brandRed)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
                            
                            // Have an account? Login
                            HStack {
                                Text("Have an account?")
                                    .foregroundStyle(brandRed)
                                Spacer()
                                NavigationLink(destination: LogIn()) {
                                    Text("Login")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(brandRed)
                                }
                            }
                            .font(.subheadline)
                            .padding(.top, 8)
                            
                            // Hidden NavigationLink triggered by state
                            NavigationLink(
                                destination: ProfileSetUp().environmentObject(profile),
                                isActive: $goToEditProfile
                            ) {
                                EmptyView()
                            }
                            .hidden()
                            
                            // Sign up button
                            Button {
                                Task {
                                    await handleSignUp()
                                }
                            } label: {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text(viewModel.isLoading ? "Creating account..." : "Sign up")
                                        .font(.system(size: 22, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(brandRed)
                                )
                                .shadow(color: brandRed.opacity(0.25), radius: 6, y: 3)
                            }
                            .padding(.top, 12)
                            .disabled(!canSubmit || viewModel.isLoading)
                            .opacity((!canSubmit || viewModel.isLoading) ? 0.7 : 1.0)
                        }
                        .padding(20)
//                        .background(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(fieldBorder, lineWidth: 1)
//                                .fill(Color.clear)
//                        )
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func handleSignUp() async {
        let user = await viewModel.signUp(username: username, email: email, password: password)
        guard user != nil else { return }
        // Populate Profile with username/email for the next screen
        profile.name = username
        profile.email = email
        // Proceed to profile setup
        goToEditProfile = true
    }
}

#Preview {
    SignUp()
        .environmentObject(Profile())
}
