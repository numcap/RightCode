//
//  Drawing.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-12.
//

import SwiftUI
import PencilKit

@Observable class Drawing: Identifiable, Codable {
    var id = UUID()
    var title: String = ""
    var language: Language = .python
    var createdAt: Date = Date()
    var drawing: PKDrawing = PKDrawing()
    
    init(id: UUID = UUID(), title: String, date: Date, language: Language) {
        self.id = id
        self.title = title
        self.createdAt = date
        self.language = language
    }
    
    init(id: UUID = UUID(), title: String, date: Date, language: Language, drawing: PKDrawing) {
        self.id = id
        self.title = title
        self.createdAt = date
        self.language = language
        self.drawing = drawing
    }
    
    func createImage() -> UIImage {
        return drawing.image(from: CGRect(x: 0, y: 0, width: 1000, height: 1050), scale: 3)
    }
    
    init() {
    }
}

struct MockData {
    static var drawings: [Drawing] = [
        Drawing(
            title: "hello",
            date: Date(),
            language: .python,
        ),
        Drawing(
            title: "trash",
            date: Date(),
            language: .java
        ),
        Drawing(
            title: "folder",
            date: Date(),
            language: .java
        ),
    ]

    static var aLotOfDrawings: [Drawing] =
        [
            Drawing(
                title: "hello",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "trash",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "folder",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "hello",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "trash",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "folder",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "hello",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "trash",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "folder",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "hello",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "trash",
                date: Date(),
                language: .java
            ),
            Drawing(
                title: "folder",
                date: Date(),
                language: .java
            ),
        ]

}
