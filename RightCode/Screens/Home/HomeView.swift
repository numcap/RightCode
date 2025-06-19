//
//  ContentView.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-05-14.
//

import SwiftUI

struct HomeView: View {

    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                SortingHeader(viewModel: viewModel)
                LazyVGrid(columns: viewModel.columns, alignment: .center) {
                    NewNoteButton(
                        addSheetIsPresented: $viewModel.addSheetIsPresented
                    )
                    NoteLinks(notes: $viewModel.notes, selectedNote: $viewModel.selectedNote, viewModel: viewModel)
                }
            }
            .navigationTitle("RightCode")
        }
        .sheet(isPresented: $viewModel.addSheetIsPresented) {
            AddNewForm(addSheetIsPresented: $viewModel.addSheetIsPresented, viewModel: viewModel)
        }
        .onAppear(perform: viewModel.loadNotes)
    }
}

#Preview {
    HomeView()
}
