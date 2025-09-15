//
//  SSEHelper.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-09-03.
//

import Foundation

struct SSEEventOCR : Codable{
    var status: String
    var task_id: String
    var result: getOCRTaskReturnValue?
}


func parseEventsForOCR(fromLines lines: AsyncLineSequence<URLSession.AsyncBytes>)
    async throws -> AsyncStream<SSEEventOCR>
{
    AsyncStream { continuation in
        Task {
            do {
                for try await line in lines {
                    print("RAW:", line) // delete
                    if line.hasPrefix("data:") {
                        let value = String(
                            line.dropFirst(5).trimmingCharacters(
                                in: .whitespaces
                            )
                        )
                        if let data = value.data(using: .utf8) {
                            do {
                                let event = try JSONDecoder().decode(SSEEventOCR.self, from: data)
                                continuation.yield(event)
                            }
                            catch {
                                print("Failed to decode:", error, value)
                            }
                        }
                    }

                }
            } catch {
                continuation.finish()
            }
        }
    }
}


struct SSEEventExecution : Codable{
    var status: String
    var task_id: String
    var result: executionResult?
}


func parseEventsForExe(fromLines lines: AsyncLineSequence<URLSession.AsyncBytes>)
    async throws -> AsyncStream<SSEEventExecution>
{
    AsyncStream { continuation in
        Task {
            do {
                for try await line in lines {
                    print("RAW:", line) // delete
                    if line.hasPrefix("data:") {
                        let value = String(
                            line.dropFirst(5).trimmingCharacters(
                                in: .whitespaces
                            )
                        )
                        if let data = value.data(using: .utf8) {
                            do {
                                let event = try JSONDecoder().decode(SSEEventExecution.self, from: data)
                                continuation.yield(event)
                            }
                            catch {
                                print("Failed to decode:", error, value)
                            }
                        }
                    }

                }
            } catch {
                continuation.finish()
            }
        }
    }
}
