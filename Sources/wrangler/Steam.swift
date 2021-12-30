import Foundation
import XMLCoder

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum Steam {
    private static let queue = DispatchQueue(label: "com.wendyliga.wrangler.steam", qos: .background)
    private static let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .current)
    
    private static func getGameListUrl(for steamId: String) -> URL? {
        URL(string: "https://steamcommunity.com/profiles/\(steamId)/games?tab=all&xml=1")
    }
    
    static func getGameList(steamId: String, completion _completion: @escaping (Result<GamesList, Steam.Error>) -> Void) {
        let completion: (Result<GamesList, Steam.Error>) -> Void = { result in
            DispatchQueue.main.async {
                _completion(result)
            }
        }
        
        let url = getGameListUrl(for: steamId)!
        queue.async { [completion] in
            session.dataTask(with: url) { [completion] (data, response, error) in
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
    }
    
    static func getFreeGameList(completion _completion: @escaping (Result<[String], Steam.Error>) -> Void) {
        let completion: (Result<[String], Steam.Error>) -> Void = { result in
            DispatchQueue.main.async {
                _completion(result)
            }
        }
        
        let url = URL(string: "https://gist.githubusercontent.com/C4illin/e8c5cf365d816f2640242bf01d8d3675/raw/9c64ec3e1c614856e444e69a7b9d4a70dfc6a76f/Steam%2520Codes")!
        
        queue.async { [completion] in
            session.dataTask(with: url) { [completion] (data, response, error) in
                if let error = error {
                    completion(.failure(.invalidFreeGameList(detail: error.localizedDescription)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.invalidFreeGameList(detail: "response is empty")))
                    return
                }
                
                guard let rawString = String(data: data, encoding: .utf8) else {
                    completion(.failure(.invalidFreeGameList(detail: "fail reading data")))
                    return
                }
                
                let gameIds = rawString.split(separator: "\n").map(String.init)
                
                guard gameIds.isNotEmpty else {
                    completion(.failure(.invalidFreeGameList(detail: "empty game ids")))
                    return
                }
                
                completion(.success(gameIds))
            }.resume()
        }
    }

}

extension Steam {
    enum Error: LocalizedError {
        case invalidGameList(detail: String?)
        case invalidFreeGameList(detail: String?)
        
        var errorDescription: String? {
            switch self {
            case let .invalidGameList(detail):
                return "Invalid game list response, fail to decode.(detail \(detail ?? "null"))"
            case let .invalidFreeGameList(detail):
                return "Invalid fetching free game list response, fail to decode.(detail \(detail ?? "null"))"
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
