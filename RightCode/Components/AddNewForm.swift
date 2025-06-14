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
    
    public var body: some View {
        Text("Add a New Note")
            .font(.headline)
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
                print(language)
                addSheetIsPresented = false
            }
        }
        .formStyle(.automatic)
    }
    
    enum Language: String, CaseIterable {
        case swift
        case python
        case javascript
        case java
    }
}

#Preview {
    AddNewForm(addSheetIsPresented: .constant(true))
}
