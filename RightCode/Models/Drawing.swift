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
    var drawing: PKDrawing?
    
    init(id: UUID = UUID(), title: String, date: Date, language: Language) {
        self.id = id
        self.title = title
        self.createdAt = date
        self.language = language
    }
    
    func createImage() -> UIImage {
//        UIGraphicsBeginImageContextWithOptions(CGSize(width: 100, height: 100), false, 0.0)
//        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        
        if let drawing = self.drawing {
            return drawing.image(from: CGRect(x: 0, y: 0, width: 100, height: 100), scale: 1)
        }
        return UIImage()
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
