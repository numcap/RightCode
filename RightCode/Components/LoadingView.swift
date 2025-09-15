//
//  LoadingView.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-09-07.
//

import SwiftUI

struct LoadingView: View {
    let text: String
    
    var body: some View {
        ZStack{
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView {
                    Text("Scanning File")
                }
                .tint(.white)
                .scaleEffect(2, anchor: .center)
                .foregroundStyle(.white)
            }
            .padding(.vertical, 90)
            .padding(.horizontal, 120)
            .background(Color.black.opacity(0.8))
            .clipShape(.buttonBorder)
            
        }
        .allowsHitTesting(true)
    }
}

#Preview {
    LoadingView(text: "Scanning File")
}
