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
    @ObservedObject var viewModel: HomeViewModel
    @State var renameIsPresented: Bool = false
    @State var newTitle: String = ""
    @State var errorAlert: Bool = false

    var body: some View {
        ForEach(notes) { note in
            NavigationLink {
                DrawingCanvas(note: $viewModel.selectedNote, viewModel: viewModel)
                    .border(.black)
                    .navigationTitle(viewModel.selectedNote.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        NoteToolbar(viewModel: viewModel)
                    }
                    .overlay {
                        if viewModel.isLoading {
                            LoadingView(text: "Scanning File")
                        }
                    }
            } label: {
                NoteCell(
                    title: note.title,
                    image: note.drawing.image(from: CGRect(x:0, y:0, width: 1100, height: 1000), scale: 1),
                    date: note.createdAt,
                    language: note.language.rawValue
                )
                .padding(15)
                .tint(Color(.label))
            }
            .simultaneousGesture(
                TapGesture().onEnded({
                    print(note.title)  // delete
                    viewModel.selectedNote = note
                    print(viewModel.selectedNote)  // delete
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

