//
//  NoteLinks.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-17.
//

import SwiftUI

struct NoteLinks: View {
    @Binding var notes: [Note]
    @Binding var selectedNote: Note
    @State var viewModel: HomeViewModel
    @State var renameIsPresented: Bool = false
    @State var newTitle: String = ""
    @State var errorAlert: Bool = false
    
    var body: some View {
        ForEach(notes) { note in
            NavigationLink {
                DrawingCanvas(note: $selectedNote, viewModel: viewModel)
                    .border(.black)
                    .navigationTitle(selectedNote.title)
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                NoteCell(
                    title: note.title,
                    image: note.createImage(),
                    date: note.createdAt, language: note.language.rawValue
                )
                .padding(30)
                .tint(Color(.label))
            }
            .simultaneousGesture(
                TapGesture().onEnded({
                    print(note.title)  // delete
                    selectedNote = note
                    print(selectedNote) // delete
                })
            )
            .contextMenu {
                Button("Rename") {
                    // TODO: Handle rename
                    renameIsPresented = true
                    print("Rename tapped")
                }
                Button("Duplicate") {
                    // TODO: Handle duplication
                    viewModel.duplicateNote(note)
                    print("Duplicate tapped")
                }
                Button(role: .destructive) {
                    // TODO: Handle delete
                    viewModel.deleteNote(note)
                    print("Delete tapped")
                } label: {
                    Text("Delete")
                }
            }
            .alert("Enter The New Title", isPresented: $renameIsPresented) {
                TextField("New Title", text: $newTitle)
                Button("OK") {
                    let result = viewModel.renameNote(newTitle, note)
                    print(result)
                    errorAlert = result ? false : true
                    renameIsPresented = false
                }
            }
            .alert("Unable to Rename", isPresented: $errorAlert) {
                
            } message: {
                Text("Please enter a valid title.")
            }
        }
        
    }
}
