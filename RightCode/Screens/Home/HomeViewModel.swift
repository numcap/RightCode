//
//  HomeViewModel.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-14.
//

import Foundation
import SwiftUI

final class HomeViewModel: ObservableObject {
    @Published var drawings: [Drawing] = []
    @Published var selectedDrawing: Drawing?
    @Published var addSheetIsPresented: Bool = false
    
    @AppStorage("localDrawings") var drawingsData: Data?
    
    func loadDrawings() {
        // this is checking if drawingData is nil, this is because it saves savedData to drawingsData, and if drawingsData is nil the if statement does not proceed
        if let savedData = drawingsData {
            do {
                print("trying to load drawings")
                drawings = try JSONDecoder().decode([Drawing].self, from: savedData)
                print("loaded drawings")
            } catch {
                print("Error loading drawings: \(error)")
            }
        }
    }
    
    func saveDrawing(_ newDrawing: Drawing) {
        
        drawings.append(newDrawing)
        
        do {
            print("trying to save drawings")
            drawingsData = try JSONEncoder().encode(drawings)
            print("saved drawings")
        } catch {
            print("Error saving drawings: \(error)")
        }
    }
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
}
