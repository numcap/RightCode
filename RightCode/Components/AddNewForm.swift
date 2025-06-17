//
//  AddNewForm.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-13.
//

import SwiftUI

public struct AddNewForm: View {
    @Binding var addSheetIsPresented: Bool
    @State var title: String = ""
    @State var language: Language = .python
    @State var viewModel: HomeViewModel
    
    public var body: some View {
        Text("Add a New Note")
            .font(.headline)
            .padding(.top, 10)
        Form {
            HStack (spacing: 20) {
                Text("Title")
                TextField("New Note", text: $title)
            }
            Picker("Language", selection: $language) {
                Text("Python").tag(Language.python)
                Text("Swift").tag(Language.swift)
                Text("JavaScript").tag(Language.javascript)
                Text("Java").tag(Language.java)
            }
            Button("Create") {
                print(language)  // delete
                addSheetIsPresented = false
                viewModel.addDrawing(Drawing(title: title, date: Date(), language: language))
            }
        }
        .formStyle(.automatic)
    }
}

//#Preview {
//    AddNewForm(
//        addSheetIsPresented: .constant(true), viewModel:
//    )
//}
