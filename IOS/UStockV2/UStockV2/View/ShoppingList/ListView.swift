//
//  ListView.swift
//  UStockV2
//
//  Created by Assistant on 20/06/2025.
//

import SwiftUI

// Modèle simple pour un élément de liste
struct ListItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var quantity: Int
    
    init(name: String, quantity: Int = 1) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
    }
}

struct ListView: View {
    @State private var items: [ListItem] = []
    @State private var newItemName: String = ""
    @State private var newItemQuantity: Int = 1
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Titre
                    HStack {
                        Text("MA LISTE")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.leading, 20)
                        
                        Spacer()
                        
                        // Bouton pour ajouter un élément
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color(hex: "156585"))
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 20)
                    
                    // Liste des éléments
                    if items.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Votre liste est vide")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                            
                            Text("Appuyez sur + pour ajouter un produit")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(items.indices, id: \.self) { index in
                                    ListItemRow(
                                        item: items[index],
                                        onQuantityChange: { newQuantity in
                                            items[index].quantity = newQuantity
                                            saveItems()
                                        },
                                        onDelete: {
                                            items.remove(at: index)
                                            saveItems()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSheet) {
                AddItemSheet(
                    itemName: $newItemName,
                    itemQuantity: $newItemQuantity,
                    onAdd: {
                        let newItem = ListItem(name: newItemName, quantity: newItemQuantity)
                        items.append(newItem)
                        saveItems()
                        
                        // Reset des champs
                        newItemName = ""
                        newItemQuantity = 1
                        showingAddSheet = false
                    },
                    onCancel: {
                        newItemName = ""
                        newItemQuantity = 1
                        showingAddSheet = false
                    }
                )
            }
        }
        .onAppear {
            loadItems()
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Sauvegarde et chargement
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "saved_list_items")
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: "saved_list_items"),
           let decoded = try? JSONDecoder().decode([ListItem].self, from: data) {
            items = decoded
        }
    }
}

// MARK: - Composant pour chaque élément de la liste

struct ListItemRow: View {
    let item: ListItem
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            // Nom du produit
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text("Quantité: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Contrôles de quantité
            HStack(spacing: 15) {
                Button(action: {
                    if item.quantity > 1 {
                        onQuantityChange(item.quantity - 1)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "156585"))
                }
                .disabled(item.quantity <= 1)
                
                Text("\(item.quantity)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(minWidth: 30)
                
                Button(action: {
                    onQuantityChange(item.quantity + 1)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "156585"))
                }
                
                // Bouton supprimer
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 2)
        .alert("Supprimer l'élément", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Voulez-vous vraiment supprimer \"\(item.name)\" de votre liste ?")
        }
    }
}

// MARK: - Sheet pour ajouter un élément

struct AddItemSheet: View {
    @Binding var itemName: String
    @Binding var itemQuantity: Int
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Titre
                    Text("Ajouter un produit")
                        .font(.custom("ChauPhilomeneOne-Regular", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 30)
                    
                    VStack(spacing: 20) {
                        // Champ nom du produit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nom du produit")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextField("Ex: Lait, Pain, Œufs...", text: $itemName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 18))
                        }
                        
                        // Sélecteur de quantité
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quantité")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            HStack {
                                Button(action: {
                                    if itemQuantity > 1 {
                                        itemQuantity -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(hex: "156585"))
                                }
                                .disabled(itemQuantity <= 1)
                                
                                Spacer()
                                
                                Text("\(itemQuantity)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Button(action: {
                                    itemQuantity += 1
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(hex: "156585"))
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Boutons d'action
                    VStack(spacing: 15) {
                        Button(action: onAdd) {
                            Text("AJOUTER À LA LISTE")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color(hex: "689FA7"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(radius: 5)
                        }
                        .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal, 30)
                        
                        Button(action: onCancel) {
                            Text("Annuler")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ListView()
}
