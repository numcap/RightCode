//
//  ReturnValues.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-09-03.
//

import Foundation

struct getOCRTaskReturnValue: Codable {
    let task_id: String?
    let status: String
    let result: String?
    let error: String?
    let cached: Bool?
    let execution_time: Double?
}

struct postExeTaskReturnValue: Codable {
    let task_id: String
    let status: String
}

struct executionResult: Codable {
    let success: Bool
    let output: String?
    let errors: String?
    let stage: String?
    let exit_code: Int?
    let execution_time: Double?
    let language: String?
    let worker: String?
}
