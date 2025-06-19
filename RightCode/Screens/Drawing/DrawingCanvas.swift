//
//  CanvasView.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-05-19.
//

import SwiftUI
import PencilKit

// Version WITH coordinator - only needed if you want to:
// 1. Save drawing changes back to your @State
// 2. React to drawing changes in real-time
// 3. Implement undo/redo functionality
// 4. Sync drawings across views
struct DrawingCanvas: UIViewRepresentable {
    @Binding var note: Note
    @ObservedObject var viewModel: HomeViewModel
    @State private var toolPicker = PKToolPicker(toolItems: [PKToolPickerInkingItem(type: .pen), PKToolPickerInkingItem(type: .monoline), PKToolPickerScribbleItem(), PKToolPickerEraserItem(type: .vector), PKToolPickerLassoItem(), PKToolPickerRulerItem()])
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        // For Testing
        #if targetEnvironment(simulator)
        canvasView.drawingPolicy = .anyInput
        #else
        canvasView.drawingPolicy = .pencilOnly
        #endif
        canvasView.backgroundColor = .systemBackground
        canvasView.drawing = note.drawing
        canvasView.contentSize = CGSize(
            width: UIScreen.current?.bounds.width ?? 2000,
            height: note.drawing.bounds.height > UIScreen.current?.bounds
                .height ?? 1000
                ? note.drawing.bounds.maxY + 500
                : UIScreen.current?.bounds.height ?? 1000
        )

        // Only add delegate if you need to sync changes back
        canvasView.delegate = context.coordinator
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != note.drawing {
            uiView.drawing = note.drawing
        }
        
        DispatchQueue.main.async {
            if uiView.window != nil && !toolPicker.isVisible {
                toolPicker.setVisible(true, forFirstResponder: uiView)
                toolPicker.addObserver(uiView)
                uiView.becomeFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: DrawingCanvas
        
        init(_ parent: DrawingCanvas) {
            self.parent = parent
        }
        
        // This is WHY you'd want a coordinator - to get notified of changes
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Without this, your @State drawing won't update when user draws
            parent.note.drawing = canvasView.drawing
            parent.viewModel.saveNotes()

            let drawingBounds = canvasView.drawing.bounds
            let currentHeight = canvasView.contentSize.height

            if drawingBounds.maxY + 400 > currentHeight {
                let newHeight = drawingBounds.maxY + 500
                
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                    canvasView.contentSize = CGSize(
                        width: canvasView.contentSize.width,
                        height: newHeight
                    )
                })

            }

        }
    }
}


// Replace 'let window  = UIApplication.shared.windows.first' with 'UIApplication.shared.windows.first != nil'
// 'windows' was deprecated in iOS 15.0: Use UIWindowScene.windows on a relevant window scene instead
