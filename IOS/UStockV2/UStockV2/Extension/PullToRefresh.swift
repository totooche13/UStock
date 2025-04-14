//
//  PullToRefresh.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 20/03/2025.
//


import SwiftUI

struct PullToRefresh: View {
    var coordinateSpaceName: String
    var onRefresh: () -> Void
    
    @State private var pullDistance: CGFloat = 0
    @State private var animatingIndicator = false
    @State private var shouldRefresh = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Spacer()
                    if animatingIndicator {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .rotationEffect(.degrees(pullDistance > 0 ? 0 : 180))
                            .opacity(pullDistance > 0 ? 1 : 0)
                    }
                    Spacer()
                }
                .frame(height: 50)
                .offset(y: -50 + min(pullDistance, 50))
            }
            .onChange(of: geometry.frame(in: .named(coordinateSpaceName)).minY) { oldValue, newValue in
                pullDistance = max(0, newValue)
                
                // Vérifier si nous devons déclencher le rafraîchissement
                if pullDistance > 50 && !animatingIndicator && !shouldRefresh {
                    shouldRefresh = true
                }
            }
            .onChange(of: shouldRefresh) { _, newValue in
                if newValue {
                    animatingIndicator = true
                    onRefresh()
                    
                    // Utiliser un timer pour réinitialiser les états
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                        animatingIndicator = false
                        shouldRefresh = false
                    }
                }
            }
        }
        .frame(height: 0)
    }
}
