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
    @Binding var drawing: PKDrawing
    @State private var toolPicker = PKToolPicker(toolItems: [PKToolPickerInkingItem(type: .pen), PKToolPickerInkingItem(type: .monoline), PKToolPickerScribbleItem(), PKToolPickerEraserItem(type: .vector), PKToolPickerLassoItem(), PKToolPickerRulerItem()])
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = .pencilOnly
        canvasView.backgroundColor = .gray
        canvasView.drawing = drawing
        canvasView.contentSize = CGSize(width: 1000, height: 500)
        
        // Only add delegate if you need to sync changes back
        canvasView.delegate = context.coordinator
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
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
            parent.drawing = canvasView.drawing
        }
    }
}


// Replace 'let window  = UIApplication.shared.windows.first' with 'UIApplication.shared.windows.first != nil'
// 'windows' was deprecated in iOS 15.0: Use UIWindowScene.windows on a relevant window scene instead
