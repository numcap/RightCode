//
//  Drawing.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-12.
//

import SwiftUI
import PencilKit

@Observable class Drawing: Identifiable {
    var id = UUID()
    var title: String = ""
    var language: String = ""
    var date: Date = Date()
    var image: UIImage = UIImage()
    var drawing: PKDrawing?
    
    init(id: UUID = UUID(), title: String, date: Date, image: UIImage) {
        self.id = id
        self.title = title
        self.date = date
        self.image = image
    }
    
    init() {
    }
}

struct MockData {
    static var drawings: [Drawing] = [
        Drawing(
            title: "hello",
            date: Date(),
            image: UIImage(systemName: "lasso")!
        ),
        Drawing(
            title: "trash",
            date: Date(),
            image: UIImage(systemName: "trash")!
        ),
        Drawing(
            title: "folder",
            date: Date(),
            image: UIImage(systemName: "folder")!
        ),
    ]

    static var aLotOfDrawings: [Drawing] =
        [
            Drawing(
                title: "hello",
                date: Date(),
                image: UIImage(systemName: "lasso")!
            ),
            Drawing(
                title: "trash",
                date: Date(),
                image: UIImage(systemName: "trash")!
            ),
            Drawing(
                title: "folder",
                date: Date(),
                image: UIImage(systemName: "folder")!
            ),
            Drawing(
                title: "hello",
                date: Date(),
                image: UIImage(systemName: "lasso")!
            ),
            Drawing(
                title: "trash",
                date: Date(),
                image: UIImage(systemName: "trash")!
            ),
            Drawing(
                title: "folder",
                date: Date(),
                image: UIImage(systemName: "folder")!
            ),
            Drawing(
                title: "hello",
                date: Date(),
                image: UIImage(systemName: "lasso")!
            ),
            Drawing(
                title: "trash",
                date: Date(),
                image: UIImage(systemName: "trash")!
            ),
            Drawing(
                title: "folder",
                date: Date(),
                image: UIImage(systemName: "folder")!
            ),
            Drawing(
                title: "hello",
                date: Date(),
                image: UIImage(systemName: "lasso")!
            ),
            Drawing(
                title: "trash",
                date: Date(),
                image: UIImage(systemName: "trash")!
            ),
            Drawing(
                title: "folder",
                date: Date(),
                image: UIImage(systemName: "folder")!
            ),
        ]

}
