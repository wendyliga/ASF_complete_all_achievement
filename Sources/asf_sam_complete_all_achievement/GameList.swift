import Foundation

struct GamesList: Codable {
  var steamId64: Int64
  var steamId: String
  var games: Games
  
  enum CodingKeys: String, CodingKey {
    case steamId64 = "steamID64"
    case steamId = "steamID"
    case games
  }
}

struct Games: Codable {
  var game: [Game]
}

struct Game: Codable {
  var appId: Int
  
  enum CodingKeys: String, CodingKey {
    case appId = "appID"
  }
}
