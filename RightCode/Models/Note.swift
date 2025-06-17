//
//  Note.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-12.
//

import SwiftUI
import PencilKit

@Observable class Note: Identifiable, Codable {
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
    static var drawings: [Note] = [
        Note(
            title: "hello",
            date: Date(),
            language: .python,
        ),
        Note(
            title: "trash",
            date: Date(),
            language: .java
        ),
        Note(
            title: "folder",
            date: Date(),
            language: .java
        ),
    ]

    static var aLotOfDrawings: [Note] =
        [
            Note(
                title: "hello",
                date: Date(),
                language: .java
            ),
            Note(
                title: "trash",
                date: Date(),
                language: .java
            ),
            Note(
                title: "folder",
                date: Date(),
                language: .java
            ),
            Note(
                title: "hello",
                date: Date(),
                language: .java
            ),
            Note(
                title: "trash",
                date: Date(),
                language: .java
            ),
            Note(
                title: "folder",
                date: Date(),
                language: .java
            ),
            Note(
                title: "hello",
                date: Date(),
                language: .java
            ),
            Note(
                title: "trash",
                date: Date(),
                language: .java
            ),
            Note(
                title: "folder",
                date: Date(),
                language: .java
            ),
            Note(
                title: "hello",
                date: Date(),
                language: .java
            ),
            Note(
                title: "trash",
                date: Date(),
                language: .java
            ),
            Note(
                title: "folder",
                date: Date(),
                language: .java
            ),
        ]

}
