import HTTP
import Vapor
import Foundation
import MySQL
import TLS

setupClient()


let MATE = "<@u3akys3uk>"
//let MATE = "<@U3DTN6U4V>".lowercased()
let MATE_CHANNEL = "C3BD0BAFQ"

let configDirectory = workingDirectory + "Config/"
let config = try Settings.Config(
    prioritized: [
        .commandLine,
        .directory(root: configDirectory + "secrets"),
        .directory(root: configDirectory + "production")
    ]
)

// Config variables
guard let token = config["bot-config", "token"]?.string else { throw BotError.missingConfig }

guard let user = config["mysql", "user"]?.string, let pass = config["mysql", "pass"]?.string else { throw BotError.missingMySQLCredentials }

guard
    let host = config["mysql", "host"]?.string,
    let port = config["mysql", "port"]?.string
    else { throw BotError.missingMySQLDatabaseUrl }

guard let databaseName = config["mysql", "database"]?.string else { throw BotError.missingMySQLDatabaseName }

let mysql = try MySQL.Database(
    host: host,
    user: user,
    password: pass,
    database: databaseName
)

// WebSocket Init
let rtmResponse = try BasicClient.loadRealtimeApi(token: token)

guard let validChannels = rtmResponse.data["channels", "id"]?.array?.flatMap({ $0.string }) else { throw BotError.unableToLoadChannels }

guard let webSocketURL = rtmResponse.data["url"]?.string else { throw BotError.invalidResponse }

try WebSocket.connect(to: webSocketURL) { ws in
    print("Connected ...")

    ws.onText = { ws, text in
        let event = try JSON(bytes: text.utf8.array)
        
        let last3Seconds = NSDate().timeIntervalSince1970 - 3
        guard
            var channel = event["channel"]?.string,
            var message = event["text"]?.string,
            var fromId = event["user"]?.string else {
                return
        }
        
        message = message.trimmedWhitespace()
        message = message.lowercased()
        
        var toUser: String?

        
        if channel != MATE_CHANNEL {
            if !message.hasPrefix(MATE) {
                return
            }
            
            message = message.replacingOccurrences(of: MATE, with: "")
            if message.contains("<@") {
                if let user = message.components(separatedBy: "<@").last?.components(separatedBy: ">").first {
                    fromId = user.uppercased()
                }
            }
        }
        
        print(fromId)
        
        if message.hasSuffix("++") {
            let result = try mysql.addMate(for: fromId)
            let response = SlackMessage(to: channel, text: "<@\(fromId)> has \(result) :club-mate:")
            try ws.send(response)
        }
        
        if message.hasSuffix("--") {
            let result = try mysql.removeMate(for: fromId)
            let response = SlackMessage(to: channel, text: "<@\(fromId)> has \(result) :club-mate:")
            try ws.send(response)
        }
        
        if message.contains("top") {
            let limit = message.components(separatedBy: " ")
                                .last
                                .flatMap { Int($0) }
                                ?? 10
                            let top = try mysql.top(limit: limit).map { "<@\($0["user"]?.string ?? "?")>: \($0["count"]?.int ?? 0):club-mate:" } .joined(separator: "\n")
                            let response = SlackMessage(to: channel, text: "Stats: \n\n\(top)")
                            try ws.send(response)
        }
        
        if message.contains("+") {
            if let range = message.range(of: "+") {
                let count = message.substring(from: range.upperBound)
                if let count = Int(count) {
                    if count < 0  {
                        let response = SlackMessage(to: channel, text: "You could not consume \(count) :club-mate:")
                        try ws.send(response)
                        return
                    } else {
                        let result = try mysql.addAmount(mates: count, for: fromId)
                        let response = SlackMessage(to: channel, text: "<@\(fromId)> has \(result) :club-mate:")
                        try ws.send(response)
                        return
                    }
                }
                
            }
        }
        
        if message.contains("-") {
            if let range = message.range(of: "-") {
                let count = message.substring(from: range.upperBound)
                if let count = Int(count) {
                    let result = try mysql.removeAmount(mates: count, for: fromId)
                    let response = SlackMessage(to: channel, text: "<@\(fromId)> has \(result) :club-mate:")
                    try ws.send(response)
                    return
                }
                
            }
        }
        
        if message.contains("=") {
            if let range = message.range(of: "=") {
                let count = message.substring(from: range.upperBound)
                if let count = Int(count) {
                    if count < 0  {
                        let response = SlackMessage(to: channel, text: "You could not consume \(count) :club-mate:")
                        try ws.send(response)
                        return
                    } else {
                        let result = try mysql.set(mates: count, for: fromId)
                        let response = SlackMessage(to: channel, text: "<@\(fromId)> has \(result) :club-mate:")
                        try ws.send(response)
                        return
                    }
                }
            }
        }
        
        if message.contains("!drop"){
            let result = try mysql.drop()
            let response = SlackMessage(to: channel, text: "<@\(fromId)> has \(result) :club-mate:")
            try ws.send(response)
        }
        
        if (message.contains("help")) {
            let response = SlackMessage(to: channel, text: "HELP\nHi! I am Club-Mate counter\nHere is how you can use me in <#\(MATE_CHANNEL)> anywhere alse use prefix \(MATE.uppercased())\n- `++`  --- Add one mate to your count\n- `--`  --- Remove one mate from your count\n- `+X`  --- Add specific amount(X) to your count\n- `-X`  --- Remove specific amount(X) of from your count\n- `=50` --- Set your mate consumtion to 50\n- `top` --- List mate drinkes stats\n- In case you would like to add mate to someone else just tag him like this `@user` and use standard commands")
            try ws.send(response)
        }
    }

    ws.onClose = { ws, _, _, _ in
        print("\n[CLOSED]\n")
    }
}

func checkForAddition(message: String) {
    
}
