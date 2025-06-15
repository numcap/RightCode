//
//  ListCell.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-12.
//

import SwiftUI

struct DrawingCell: View {
    let title: String
    let image: UIImage
    let date: Date?
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 150)
                .padding()
            
            VStack (alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title)
                    .bold()
                if (date != nil) {
                    Text(date!.formatted())
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
            }
        }
        .frame(width: 225, height: 300)
        .border(.black)
    }
}

#Preview {
    DrawingCell(
        title: MockData.drawings.first!.title,
        image: UIImage(systemName: "lasso")!,
        date: MockData.drawings.first!.createdAt
    )
}
