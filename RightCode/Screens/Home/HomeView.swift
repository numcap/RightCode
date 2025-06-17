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
                    DrawingLinks(drawings: $viewModel.drawings, selectedDrawing: $viewModel.selectedDrawing)
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
    @Binding var selectedDrawing: Drawing?

    var body: some View {
        ForEach(drawings) { drawing in
            NavigationLink {
                // TODO: Add Drawing View here
            } label: {
                DrawingCell(
                    title: drawing.title,
                    //                    image: drawing.createImage(),
                    image: UIImage(systemName: "lasso")!,
                    date: drawing.createdAt
                )
                .padding(30)
                .border(Color.gray, width: 1)
                .containerShape(Rectangle())
                .tint(.black)
            }
            .onTapGesture {
                selectedDrawing = drawing
                print(drawing.title)
            }
        }
    }
}
