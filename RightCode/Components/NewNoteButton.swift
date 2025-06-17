//
//  NewDrawingButton.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-17.
//

import SwiftUI

struct NewNoteButton: View {
    @Binding var addSheetIsPresented: Bool

    var body: some View {
        Button {
            addSheetIsPresented = true
        } label: {
            VStack{
                Image(systemName: "plus.rectangle.portrait")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 130)
                    .padding()
                
                VStack (alignment: .leading, spacing: 5) {
                    Text("new")
                        .font(.title)
                        .bold()
                }
            }
            .frame(width: 250, height: 350)
//            .border(.black)
            .tint(Color(.label))
        }
    }
}
