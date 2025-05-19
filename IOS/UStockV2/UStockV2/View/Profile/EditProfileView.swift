//
//  EditProfileView.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 17/04/2025.
//


import SwiftUI

struct EditProfileView: View {
    @Binding var userName: String
    @Binding var userEmail: String
    @State private var tempUserName: String = ""
    @State private var tempUserEmail: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color(hex: "156585"))
                        .padding(.top, 20)
                    
                    CustomTextField(placeholder: "Nom d'utilisateur", text: $tempUserName)
                    CustomTextField(placeholder: "Email", text: $tempUserEmail)
                    
                    Spacer()
                    
                    Button(action: {
                        userName = tempUserName
                        userEmail = tempUserEmail
                        dismiss()
                    }) {
                        Text("ENREGISTRER")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "689FA7"))
                            .foregroundColor(.black)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
                .padding()
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempUserName = userName
                tempUserEmail = userEmail
            }
        }
    }
}