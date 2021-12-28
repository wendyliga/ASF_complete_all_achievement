import Foundation
import XMLCoder

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum Steam {
  private static func getGameListUrl(for steamId: String) -> URL? {
    URL(string: "https://steamcommunity.com/profiles/\(steamId)/games?tab=all&xml=1")
  }
  
  static func getGameList(steamId: String, completion: @escaping (Result<GamesList, Steam.Error>) -> Void) {
    let url = getGameListUrl(for: steamId)!
    URLSession.shared.dataTask(with: url) { [completion] (data, response, error) in
      if let error = error {
        completion(.failure(.invalidGameList(detail: error.localizedDescription)))
        return
      }
      
      guard let data = data else {
        completion(.failure(.invalidGameList(detail: "response is empty")))
        return
      }
      
      let decoder = XMLDecoder()
      
      do {
        let list = try decoder.decode(GamesList.self, from: data)
        completion(.success(list))
      } catch {
        completion(.failure(.invalidGameList(detail: error.localizedDescription)))
      }
    }.resume()
  }
  #if os(macOS)
  @available(macOS 12.0.0, *)
  static func getGameList(steamId: String) async throws -> GamesList {
    let url = getGameListUrl(for: steamId)!
    
    let (data,_) = try await URLSession.shared.data(from: url)
    let decoder = XMLDecoder()
    return try decoder.decode(GamesList.self, from: data)
  }
  #endif
}

extension Steam {
  enum Error: LocalizedError {
    case invalidGameList(detail: String?)
    
    var errorDescription: String? {
      switch self {
      case let .invalidGameList(detail):
        return "Invalid game list response, fail to decode.(detail \(detail ?? "null"))"
      }
    }
  }
  
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
    var name: String
    
    enum CodingKeys: String, CodingKey {
      case appId = "appID"
      case name
    }
  }
}
