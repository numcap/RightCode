//
//  ContentView.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-05-14.
//

import SwiftUI

struct HomeView: View {
    @State var drawings: [Drawing] = MockData.aLotOfDrawings
    @State var selectedDrawing: Drawing?
    @State var addSheetIsPresented: Bool = false
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center) {
                    ForEach(drawings) { drawing in
                        NavigationLink {
                            Text("asdjkhkahs")
                        } label: {
                            DrawingCell(
                                title: drawing.title,
                                image: drawing.image,
                                date: drawing.date
                            )
                            .padding(.all, 30)
                            .border(Color.gray, width: 1)
                            .onTapGesture {
                                selectedDrawing = drawing
                                print(drawing.title)
                            }
                            .tint(.black)
                        }
                    }

                    DrawingCell(
                        title: "New",
                        image: UIImage(systemName: "plus")!,
                        date: nil
                    )
                    .onTapGesture {
                        addSheetIsPresented = true
                    }
                }
            }
            .navigationTitle("RightCode")
        }
        .sheet(isPresented: $addSheetIsPresented) {
            AddNewForm(addSheetIsPresented: $addSheetIsPresented)
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
