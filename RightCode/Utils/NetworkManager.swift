//
//  NetworkManager.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-09-03.
//
import UIKit

final class NetworkManager {

    static let shared = NetworkManager()

    static let baseURL = "http://144.217.10.22:8000"
    private let processFileURL = baseURL + "/ocr"
    private let getOCRTaskURL = baseURL + "/ocr/"
    private let getStreamedOCRTaskURL = baseURL + "/ocr/stream/"
    private let executeCodeURL = baseURL + "/execute"
    private let getExecuteCodeURL = baseURL + "/execute/"
    private let getStreamedExecuteCodeURL = baseURL + "/execute/stream/"

    private init() {}

    func getOCRTask(task_id: String) async throws -> getOCRTaskReturnValue {
        guard let url = URL(string: getOCRTaskURL + task_id) else {
            throw Errors.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        print("response\n", response)
        print("data\n", data)
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(getOCRTaskReturnValue.self, from: data)
        } catch {
            throw Errors.invalidData
        }
    }

    func getStreamedOCRTask(
        task_id: String,
        onEvent: @escaping (SSEEventOCR) -> Void
    ) async throws
    {
        guard let url = URL(string: getStreamedOCRTaskURL + task_id) else {
            throw Errors.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200
        else {
            throw URLError(.badServerResponse)
        }

        for await event in try await parseEventsForOCR(fromLines: bytes.lines) {
            onEvent(event)
        }
    }

    func postOCRImage(language: String, title: String, drawing: UIImage)
        async throws -> getOCRTaskReturnValue
    {
        guard let url = URL(string: processFileURL) else {
            throw URLError(.badURL)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let boundary = UUID().uuidString
            request.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )
            
            let params: [String: String] = [
                "title": title,
                "language": language,
            ]
            
            var body = Data()
            let boundaryPrefix = "\r\n--\(boundary)\r\n"
            
            for (key, value) in params {
                body.append(boundaryPrefix.data(using: .utf8)!)
                body.append(
                    "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(
                        using: .utf8
                    )!
                )
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
            
            body.append(boundaryPrefix.data(using: .utf8)!)
            body.append(
                "Content-Disposition: form-data; name=\"drawing\"; filename=\"drawing\"\r\n"
                    .data(using: .utf8)!
            )
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(drawing.jpegData(compressionQuality: 1.0)!)
            
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            session.uploadTask(with:request, from: body) { responseData, response, error in
                if let error = error {
                    print("\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let responseData = responseData else {
                    print("No Response Data")
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                if let responseString = String(data: responseData, encoding: .utf8) {
                    print("uploaded to: \(responseString)")
                }
                
                //            let jsonData = try? JSONSerialization.jsonObject(with: responseData, options: .fragmentsAllowed)
                do {
                    let decoded = try JSONDecoder().decode(getOCRTaskReturnValue.self, from: responseData)
                    continuation.resume(returning: decoded)
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        }
    }
    
    
    func postExecuteCode(code: String, language: String) async throws -> postExeTaskReturnValue {
        guard let url = URL(string: executeCodeURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        let body: [String: String] = [
            "code": code,
            "language": language,
        ]

        let data: Data = try JSONEncoder().encode(body)

        let (responseData, response) = try await URLSession.shared.upload(
            for: request,
            from: data
        )
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            print("Not 200")
            throw URLError(.badServerResponse)
        }

        let resData = try JSONDecoder().decode(
            postExeTaskReturnValue.self,
            from: responseData
        )
        print(resData)
        
        return resData
    }
    
    func getStreamedExecuteTask(
        task_id: String,
        onEvent: @escaping (SSEEventExecution) -> Void
    ) async throws {
        guard let url = URL(string: getStreamedExecuteCodeURL + task_id) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let res = response as? HTTPURLResponse, res.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        for await event in try await parseEventsForExe(fromLines: bytes.lines) {
            onEvent(event)
        }
        
    }

}
