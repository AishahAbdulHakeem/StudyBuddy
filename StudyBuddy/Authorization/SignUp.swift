//
//  SignUp.swift
//  StudyBuddy
//
//  Created by Aishah A on 11/25/25.
//

import SwiftUI

struct SignUp: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    
    private let brandRed = Color(hex: 0x9E122C)
    private let fieldBorder = Color(.systemGray3)
    
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
                            
                            // Sign up button
                            Button {
                                // TODO: Hook up sign-up action
                            } label: {
                                Text("Sign up")
                                    .font(.system(size: 22, weight: .bold))
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
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(fieldBorder, lineWidth: 1)
                                .fill(Color.clear)
                        )
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
        }
    }
}

#Preview {
   
        SignUp()

}
