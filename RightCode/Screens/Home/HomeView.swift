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
                LazyVGrid(columns: viewModel.columns, alignment: .center) {
                    NewDrawingButton(
                        addSheetIsPresented: $viewModel.addSheetIsPresented
                    )
                    DrawingLinks(drawings: $viewModel.drawings, selectedDrawing: $viewModel.selectedDrawing, viewModel: viewModel)
                }
            }
            .navigationTitle("RightCode")
        }
        .sheet(isPresented: $viewModel.addSheetIsPresented) {
            AddNewForm(addSheetIsPresented: $viewModel.addSheetIsPresented, viewModel: viewModel)
        }
        .onAppear(perform: viewModel.loadDrawings)
    }
}

#Preview {
    HomeView()
}

struct NewDrawingButton: View {
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

struct DrawingLinks: View {
    @Binding var drawings: [Drawing]
    @Binding var selectedDrawing: Drawing
    @State var viewModel: HomeViewModel
    @State var renameIsPresented: Bool = false
    @State var newTitle: String = ""
    @State var errorAlert: Bool = false
    
    var body: some View {
        ForEach(drawings) { drawing in
            NavigationLink {
                DrawingCanvas(drawing: $selectedDrawing, viewModel: viewModel)
                    .border(.black)
                    .navigationTitle(selectedDrawing.title)
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                DrawingCell(
                    title: drawing.title,
                    image: drawing.createImage(),
                    date: drawing.createdAt, language: drawing.language.rawValue
                )
                .padding(30)
                .tint(Color(.label))
            }
            .simultaneousGesture(
                TapGesture().onEnded({
                    print(drawing.title)  // delete
                    selectedDrawing = drawing
                    print(selectedDrawing) // delete
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
                    viewModel.duplicateDrawing(drawing)
                    print("Duplicate tapped")
                }
                Button(role: .destructive) {
                    // TODO: Handle delete
                    viewModel.deleteDrawing(drawing)
                    print("Delete tapped")
                } label: {
                    Text("Delete")
                }
            }
            .alert("Enter The New Title", isPresented: $renameIsPresented) {
                TextField("New Title", text: $newTitle)
                Button("OK") {
                    let result = viewModel.renameDrawing(newTitle, drawing)
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
