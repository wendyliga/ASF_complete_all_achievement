import ArgumentParser
import Foundation
import XMLCoder

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif


@main
struct Main: ParsableCommand {
  @Option
  var botName: String
  
  @Option
  var ipcPassword: String?
  
  @Option
  var ipcServer: String!
  
  @Option
  var ipcPort: Int!
  
  mutating func validate() throws {
    if ipcPort == nil {
      ipcPort = 1242
    }
    
    if ipcServer == nil || ipcServer == "localhost" {
      ipcServer = "127.0.0.1"
    }
  }
  
  @available(macOS 12.0.0, *)
  func run() async throws {
//    let (data, response) = try await URLSession.shared.data(from: url)
//    let decoder = XMLDecoder()
//
//    do {
//      let note = try decoder.decode(GamesList.self, from: data)
//      print(">>>", note)
//    } catch {
//      print(">>>", error)
//    }
  }
  
  func run() throws {
    let groupDispatch = DispatchGroup()
    var steamId: String?
    var gameList: GamesList?
    
    // fetch steam id from asf bot
    groupDispatch.enter()
    getSteamId(botName: botName, ipcPassword: ipcPassword) { result in
      steamId = result
      print("steam id fetched")
      groupDispatch.leave()
    }
    groupDispatch.wait()
    
    // fetch account game list from steam
    groupDispatch.enter()
    guard let _steamId = steamId else { Darwin.exit(1) }
    getGameList(steamId: _steamId) { list in
      gameList = list
      print("gamelist fetched")
      groupDispatch.leave()
    }
    groupDispatch.wait()
    
    // communicate with asf, to execute command
    groupDispatch.enter()
    guard let _gameList = gameList else { Darwin.exit(1) }
    let commands = _gameList.games.game.map { "aset \(botName) \($0.appId) *" }
    let executeCommandGroupDispatch = DispatchGroup()
    // execute each command by queue
    commands.forEach { command in
      executeCommandGroupDispatch.enter()
      executeCommandToASF(command: command) { result in
        print(result)
        executeCommandGroupDispatch.leave()
      }
      executeCommandGroupDispatch.wait()
    }
    groupDispatch.leave()
    groupDispatch.wait()
    Darwin.exit(0)
  }
  
  func createUrlRequest(url: URL) -> URLRequest {
    var urlRequest = URLRequest(url: url)
    urlRequest.setValue("application/json", forHTTPHeaderField: "accept")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // if call outside localhost
    if let ipcPassword = ipcPassword {
      urlRequest.setValue(ipcPassword, forHTTPHeaderField: "Authentication")
    }
    
    return urlRequest
  }
  
  func getSteamId(botName: String, ipcPassword: String? = nil, completion: @escaping (String) -> Void) {
    let url = URL(string: "http://\(ipcServer!):\(ipcPort!)/Api/Bot/\(botName)")!
    var urlRequest = createUrlRequest(url: url)
    urlRequest.httpMethod = "GET"
    
    URLSession.shared.dataTask(with: urlRequest) { [completion] (data, response, error) in
      guard let data = data else { return }
      
      do {
        // use serialization as one of the json object is the botname
        let serialization = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        let result = serialization?["Result"] as? [String: Any]
        let botData = result?[botName] as? [String: Any]
        guard let steamId = botData?["s_SteamID"] as? String else {
          Darwin.exit(1)
        }
        
        completion(steamId)
      } catch {
        print(error)
        Darwin.exit(1)
      }
    }.resume()
  }
  
  func getGameList(steamId: String, completion: @escaping (GamesList) -> Void) {
    let url = URL(string: "https://steamcommunity.com/profiles/\(steamId)/games?tab=all&xml=1")!
    URLSession.shared.dataTask(with: url) { [completion] (data, response, error) in
      guard let data = data else { return }
      let decoder = XMLDecoder()
      
      do {
        let list = try decoder.decode(GamesList.self, from: data)
        completion(list)
      } catch {
        print(error)
        Darwin.exit(1)
      }
    }.resume()
  }
  
  func executeCommandToASF(command: String, completion: @escaping (String) -> Void) {
    let session = URLSession(configuration: .default)
    let url = URL(string: "http://\(ipcServer!):\(ipcPort!)/Api/Command")!
    var urlRequest = createUrlRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = {
      """
      {
        "Command": "\(command)"
      }
      """.data(using: .utf8)!
    }()
    
    session.dataTask(with: urlRequest) { [completion] (data, response, error) in
      guard let data = data else { return }
      do {
        // use serialization as one of the json object is the botname
        let serialization = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        let result = serialization?["Result"] as? String
        completion(result ?? "empty")
      } catch {
        print(error)
        Darwin.exit(1)
      }
    }.resume()
  }
}
