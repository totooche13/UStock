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
                DatePicker("Sélectionnez une date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                
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

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }
}

