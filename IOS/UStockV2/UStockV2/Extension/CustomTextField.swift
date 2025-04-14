//
//  CustomTextField.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 19/03/2025.
//


import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(15)
            .background(Color(hex: "689FA7"))
            .cornerRadius(25)
            .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.clear, lineWidth: 1))
            .foregroundColor(.black)
            .padding(.horizontal, 30)
    }
}
