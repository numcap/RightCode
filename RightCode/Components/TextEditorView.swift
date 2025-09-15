//
//  TextEditor.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-09-04.
//

import SwiftUI

struct TextEditorView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        TextEditor(text: $viewModel.selectedNote.scannedCode)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.all, 25)
            .background(Color(.secondarySystemBackground) ,in: .rect)
//            .border(.tint)
    }
}

#Preview {
    TextEditorView(viewModel: HomeViewModel())
}
