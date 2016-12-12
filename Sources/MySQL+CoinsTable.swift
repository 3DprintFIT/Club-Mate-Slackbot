
import MySQL

extension MySQL.Database {
    func addMate(for user: String) throws -> Int {
        _ = try create()
        let command = "INSERT INTO mates (user, count) VALUES(?, 1) ON DUPLICATE KEY UPDATE count = count + 1;"
        do {
            try execute(command, [user])
        }catch {
            print(error)
        }
        return try matesCount(for: user)
    }
    
    func removeMate(for user: String) throws -> Int {
        _ = try create()
        let command = "INSERT INTO mates (user, count) VALUES(?, 1) ON DUPLICATE KEY UPDATE count = count - 1;"
        try execute(command, [user])
        return try matesCount(for: user)
    }

    func matesCount(for user: String) throws -> Int {
        _ = try create()
        return try execute("SELECT count FROM mates WHERE user = ?;", [user])
            .first?["count"]?
            .int
            ?? 0
    }

    func top(limit: Int) throws -> [[String: Node]] {
        _ = try create()
        return try execute("SELECT * FROM mates ORDER BY count DESC ;")
    }

    func set(mates: Int, for user: String) throws -> Int {
        _ = try create()
        let command = "INSERT INTO mates (user, count) VALUES(?, ?) ON DUPLICATE KEY UPDATE count = ?;"
        try execute(command, [user, mates, mates])
        return try matesCount(for: user)
    }
    
    func addAmount(mates: Int, for user: String) throws -> Int {
        _ = try create()
        let command = "INSERT INTO mates (user, count) VALUES(?, ?) ON DUPLICATE KEY UPDATE count = count + ?;"
        try execute(command, [user, mates, mates])
        return try matesCount(for: user)
    }
    
    func removeAmount(mates: Int, for user: String) throws -> Int {
        _ = try create()
        let command = "INSERT INTO mates (user, count) VALUES(?, ?) ON DUPLICATE KEY UPDATE count = count - ?;"
        try execute(command, [user, mates, mates])
        return try matesCount(for: user)
    }
    
    func drop() throws -> String {
        let command = "DROP TABLE mates;"
        do {
            try execute(command)
        }catch{
            return error.localizedDescription
        }
        return try create()
    }
    
    func create() throws -> String {
        let command = "CREATE TABLE IF NOT EXISTS mates (user VARCHAR(45) NOT NULL, count INT NULL, PRIMARY KEY (user));"
        do {
            try execute(command)
        }catch{
            return error.localizedDescription
        }
        return "Database created"
    }
}
