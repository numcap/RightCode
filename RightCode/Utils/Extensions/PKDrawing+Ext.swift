//
//  PKDrawing+Ext.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-09-06.
//

import PencilKit

extension PKDrawing {
    func toUIImage(padding: CGFloat = 20, scale: CGFloat = 1) -> UIImage {
        let rect = bounds.insetBy(dx: -padding, dy: -padding)
        return image(from: rect, scale: scale)
    }
}
