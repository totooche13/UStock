import SwiftUI

struct CustomDatePicker: View {
    var placeholder: String
    @Binding var date: Date
    @State private var showDatePicker = false

    var body: some View {
        Button(action: {
            showDatePicker.toggle()
        }) {
            HStack {
                Text("\(placeholder) : \(formattedDate)")
                    .foregroundColor(Color.black.opacity(0.6)) // 🔹 Texte grisé comme les autres
                    .padding(15)

                Spacer()

                Image(systemName: "calendar")
                    .foregroundColor(.black)
                    .padding(.trailing, 15)
            }
            .background(Color(hex: "689FA7")) // 🔹 Même couleur que les autres champs
            .cornerRadius(25)
            .padding(.horizontal, 30)
        }
        .sheet(isPresented: $showDatePicker) {
            VStack {
                Text("Sélectionnez une date")
                    .font(.headline)
                    .padding(.top)
                
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .environment(\.locale, Locale(identifier: "fr_FR")) // 🔹 Interface en français
                
                Button("Valider") {
                    showDatePicker = false
                }
                .padding(15)
                .background(Color(hex: "689FA7"))
                .cornerRadius(25)
                .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.clear, lineWidth: 1))
                .foregroundColor(.black)
                .padding(.horizontal, 30)
            }
            .padding()
        }
    }

    // 🔹 NOUVEAU : Format français complet
    private var formattedDate: String {
        return date.fullFrenchString
    }
}
