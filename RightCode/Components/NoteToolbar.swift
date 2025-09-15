//
//  NoteToolbar.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-09-02.
//

import SwiftUI

struct NoteToolbar: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        HStack {
            Button {
                print("scanning the file")
                viewModel.postOCRTask(currentNote: viewModel.selectedNote)
            } label: {
                Image(systemName: "document.viewfinder.fill")
            }
            .disabled(viewModel.isLoading)

            if viewModel.selectedNote.hasBeenScanned {
                Button {
                    print("running")
                    viewModel.postExecuteTask(
                        currentNote: viewModel.selectedNote
                    )
                } label: {
                    Image(systemName: "play.fill")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $viewModel.editorIsPresented) {
            NavigationStack {
                TextEditorView(
                    viewModel: viewModel
                )
                .navigationTitle("Verify The Scanned Code Below")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Verify") {
                            viewModel.editorIsPresented = false
                            viewModel.saveNotes()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.codePopupIsPresented) {
            NavigationStack {
                CodeResultView(viewModel: viewModel)
                    .navigationTitle("Code Execution Results")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                viewModel.codePopupIsPresented = false
                            }
                        }
                    }
            }
        }
    }
}
//
//#Preview {
//    NoteToolbar(viewModel: HomeViewModel())
//}
