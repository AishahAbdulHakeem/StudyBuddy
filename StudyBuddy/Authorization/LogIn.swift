//
//  LogIn.swift
//  StudyBuddy
//
//  Created by Aishah A on 11/25/25.
//

import SwiftUI

struct LogIn: View {
    @EnvironmentObject var session: SessionStore
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var gotoPreExplorePage  = false
    
    private let brandRed = Color(hex: 0x9E122C)
    private let fieldBorder = Color(.systemGray3)
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .topLeading) {
                Color(.systemBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Image("StudyBuddySignUpLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 120)
                            .padding(.top, 40)
                        Text("Welcome Back!")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 14) {
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
                            if let err = session.errorMessage {
                                Text(err)
                                    .font(.footnote)
                                    .foregroundStyle(brandRed)
                            }
                            
                            // Forgot Password removed (no backend)
                            HStack {
                                Text("Forgot Password?")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .font(.subheadline)
                            .padding(.top, 8)
                            
                            HStack{
                                NavigationLink(destination: SignUp()) {
                                Text("Don't have an account?")
                                    .foregroundStyle(brandRed)
                                Spacer()
                                    
                                }
                                .font(.subheadline)
                                .padding(.top, 8)
                            }
                            
                            NavigationLink(
                                destination: PreExplore(),
                                isActive: $gotoPreExplorePage
                            ) { EmptyView() }
                            .hidden()
                            
                            Button {
                                Task {
                                    let ok = await session.login(username: username, password: password)
                                    if ok { gotoPreExplorePage = true }
                                }
                            } label: {

                                HStack {
                                    if session.isLoading { ProgressView().tint(.white) }
                                    Text(session.isLoading ? "Logging In..." : "Log In")
                                        .font(.system(size: 22, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(brandRed)
                                )

                            }
                            .disabled(session.isLoading || username.isEmpty || password.isEmpty)
                        }
                        .padding(.top, 12)
                    }
                    .padding(20)
                    .padding(.horizontal, 24)
                    Spacer(minLength: 20)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    LogIn().environmentObject(SessionStore())
}
