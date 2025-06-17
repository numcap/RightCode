//
//  ListCell.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-12.
//

import SwiftUI

struct DrawingCell: View {
    @Environment(\.colorScheme) var colourScheme
    let title: String
    let image: UIImage
    let date: Date
    let language: String
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
                .background(colourScheme == .dark ? Color.white : Color.gray.opacity(0.2))
                .clipShape(.buttonBorder)
            Text(language)
                .font(.title3)
            Spacer()
            VStack (alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title)
                    .bold()
                    Text(date.formatted())
                        .font(.title3)
                        .foregroundStyle(.gray)
            }
        }
        .frame(width: 250, height: 350)
//        .border(.black) // delete
    }
}

#Preview {
    DrawingCell(
        title: MockData.drawings.first!.title,
        image: UIImage(systemName: "lasso")!,
        date: MockData.drawings.first!.createdAt, language: Language.python.rawValue
    )
}
