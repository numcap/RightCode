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
    @Published var selectedDrawing: Drawing = Drawing()
    @Published var addSheetIsPresented: Bool = false
    
    @AppStorage("localDrawings") var drawingsData: Data?
    
    func loadDrawings() {
        // this is checking if drawingData is nil, this is because it saves savedData to drawingsData, and if drawingsData is nil the if statement does not proceed
        if let savedData = drawingsData {
            do {
                print("trying to load drawings")
                drawings = try JSONDecoder().decode([Drawing].self, from: savedData).sorted(by: { $0.createdAt > $1.createdAt })
                print("loaded drawings")
            } catch {
                print("Error loading drawings: \(error)")
            }
        }
    }
    
    func addDrawing(_ newDrawing: Drawing) {
        
        drawings.append(newDrawing)
        
        do {
            print("trying to save drawings")
            drawingsData = try JSONEncoder().encode(drawings)
            loadDrawings()
            print("saved drawings")
        } catch {
            print("Error saving drawings: \(error)")
        }
    }
    
    func saveDrawing() {
        do {
            for (index, drawing) in drawings.enumerated() {
                if (drawing.id == selectedDrawing.id) {
                    drawings[index] = selectedDrawing
                    drawingsData = try JSONEncoder().encode(drawings)
                    print("saved drawing")
                    return
                }
                print("No drawing to save")
            }
        }
        catch {
            
        }
    }
    
    func saveDrawing(_ selectedDrawing: Drawing) {
        do {
            for (index, drawing) in drawings.enumerated() {
                if (drawing.id == selectedDrawing.id) {
                    drawings[index] = selectedDrawing
                    drawingsData = try JSONEncoder().encode(drawings)
                    print("saved drawing")
                    return
                }
                print("No drawing to save")
            }
        }
        catch {
            
        }
    }
    
    func duplicateDrawing(_ selectedDrawing: Drawing) {
        let newDrawing = Drawing(title: selectedDrawing.title + "-copy", date: Date(), language: selectedDrawing.language, drawing: selectedDrawing.drawing)
        addDrawing(newDrawing)
    }
    
    func deleteDrawing(_ selectedDrawing: Drawing) {
        drawings.removeAll { $0.id == selectedDrawing.id }
        do {
            drawingsData = try JSONEncoder().encode(drawings)
            loadDrawings()
            print("saved drawings")
        } catch {
            print("Error saving drawings: \(error)")
        }
    }
    
    func renameDrawing(_ newTitle: String, _ selectedDrawing: Drawing) -> Bool {
        
        if (drawings.contains(where: { $0.title == newTitle })) {
            return false
        }
        
        selectedDrawing.title = newTitle
        saveDrawing(selectedDrawing)
        loadDrawings()
        return true
    }
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)
}
