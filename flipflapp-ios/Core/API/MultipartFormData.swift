import Foundation

nonisolated struct AvatarUpload: Sendable {
    let data: Data
    let filename: String
    let mimeType: String

    static func jpeg(_ data: Data, filename: String = "avatar.jpg") -> AvatarUpload {
        AvatarUpload(data: data, filename: filename, mimeType: "image/jpeg")
    }
}

nonisolated struct MultipartFormData: Sendable {
    let boundary: String
    private(set) var body = Data()

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    mutating func appendField(name: String, value: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }

    mutating func appendFile(name: String, filename: String, mimeType: String, data: Data) {
        append("--\(boundary)\r\n")
        append(
            "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n"
        )
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        append("\r\n")
    }

    mutating func finish() {
        append("--\(boundary)--\r\n")
    }

    private mutating func append(_ string: String) {
        body.append(Data(string.utf8))
    }
}
