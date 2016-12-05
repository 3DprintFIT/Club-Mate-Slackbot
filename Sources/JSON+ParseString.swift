import JSON

extension JSON {
    static func parseString(_ str: String) throws -> JSON {
        return try JSON(bytes: str.utf8.array)
    }
}
