import Foundation

nonisolated struct MultipartFormData: Sendable {
    let boundary: String
    let body: Data
    let contentType: String

    init(boundary: String = UUID().uuidString, parts: [Part]) {
        self.boundary = boundary
        var data = Data()
        for part in parts {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(part.name)\"".data(using: .utf8)!)
            if let filename = part.filename {
                data.append("; filename=\"\(filename)\"".data(using: .utf8)!)
            }
            data.append("\r\n".data(using: .utf8)!)
            if let mimeType = part.mimeType {
                data.append("Content-Type: \(mimeType)\r\n".data(using: .utf8)!)
            } else {
                data.append("\r\n".data(using: .utf8)!)
            }
            data.append(part.data)
            data.append("\r\n".data(using: .utf8)!)
        }
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        body = data
        contentType = "multipart/form-data; boundary=\(boundary)"
    }

    nonisolated struct Part: Sendable {
        let name: String
        let filename: String?
        let mimeType: String?
        let data: Data

        static func field(name: String, value: String) -> Part {
            Part(name: name, filename: nil, mimeType: nil, data: Data(value.utf8))
        }

        static func file(name: String, filename: String, mimeType: String, data: Data) -> Part {
            Part(name: name, filename: filename, mimeType: mimeType, data: data)
        }
    }
}
