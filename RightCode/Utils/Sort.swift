//
//  Sort.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-17.
//

enum Sort: String, Codable, CaseIterable {
    case name = "Name"
    case date = "Date"
    case language = "Language"
}

struct SortingPreferences: Codable {
    var sortingMethod: Sort
    var sortingOrderASC: Bool
}
