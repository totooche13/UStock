//
//  CustomSecureField.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 19/03/2025.
//

import SwiftUI


struct CustomSecureField: View {
    var placeholder: String
    @Binding var text: String
    @Binding var isPasswordVisible: Bool

    var body: some View {
        HStack {
            if isPasswordVisible {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
            }

            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.black)
                    .font(.title2)
            }
        }
        .padding(15)
        .background(Color(hex: "689FA7"))
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.clear, lineWidth: 1))
        .foregroundColor(.black)
        .padding(.horizontal, 30)
    }
}
