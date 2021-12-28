import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ASF {
  internal let ipcServer: String
  internal let ipcPassword: String?
  internal let ipcPort: Int
  internal let botName: String
  
  var botInfoUrl: URL! {
    URL(string: "\(ipcServer):\(ipcPort)/Api/Bot/\(botName)")!
  }
  
  var botCommandUrl: URL! {
    URL(string: "\(ipcServer):\(ipcPort)/Api/Command")!
  }
}

extension ASF {
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
  
  func getSteamId(completion: @escaping (Result<String, ASF.Error>) -> Void) {
    var urlRequest = createUrlRequest(url: botInfoUrl)
    urlRequest.httpMethod = "GET"
    
    URLSession.shared.dataTask(with: urlRequest) { [completion] (data, response, error) in
      if let error = error {
        completion(.failure(.invalidBotInfoResponse(detail: error.localizedDescription)))
        return
      }
      
      guard let data = data else {
        completion(.failure(.invalidBotInfoResponse(detail: "response is empty")))
        return
      }
      
      do {
        // use serialization as one of the json object is the botname
        guard let serialization = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          completion(.failure(.invalidBotInfoResponse(detail: "fail initialize json serialization")))
          return
        }
        
        guard let result = serialization["Result"] as? [String: Any] else {
          completion(.failure(.invalidBotInfoResponse(detail: "missing 'Result' key")))
          return
        }
        
        guard let botData = result[botName] as? [String: Any] else {
          completion(.failure(.invalidBotInfoResponse(detail: "missing '\(botName)' key")))
          return
        }
        
        guard let steamId = botData["s_SteamID"] as? String else {
          completion(.failure(.invalidBotInfoResponse(detail: "missing 's_SteamID' key")))
          return
        }
        
        completion(.success(steamId))
      } catch {
        completion(.failure(.invalidBotInfoResponse(detail: error.localizedDescription)))
      }
    }.resume()
  }
  
  @available(macOS 12.0.0, *)
  func getSteamId() async throws -> String {
    var urlRequest = createUrlRequest(url: botInfoUrl)
    urlRequest.httpMethod = "GET"
    
    let (data,_) = try await URLSession.shared.data(for: urlRequest)
    
    guard let serialization = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      throw ASF.Error.invalidBotInfoResponse(detail: "fail initialize json serialization")
    }
    
    guard let result = serialization["Result"] as? [String: Any] else {
      throw ASF.Error.invalidBotInfoResponse(detail: "missing 'Result' key")
    }
    
    guard let botData = result[botName] as? [String: Any] else {
      throw ASF.Error.invalidBotInfoResponse(detail: "missing '\(botName)' key")
    }
    
    guard let steamId = botData["s_SteamID"] as? String else {
      throw ASF.Error.invalidBotInfoResponse(detail: "missing 's_SteamID' key")
    }
    
    return steamId
  }
  
  func executeCommandToASF(command: String, completion: @escaping (Result<String, ASF.Error>) -> Void) {
    var urlRequest = createUrlRequest(url: botCommandUrl)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = {
      """
      {
        "Command": "\(command)"
      }
      """.data(using: .utf8)!
    }()
    
    URLSession.shared.dataTask(with: urlRequest) { [completion] (data, response, error) in
      if let error = error {
        completion(.failure(.invalidBotExecutionResponse(detail: error.localizedDescription)))
        return
      }
      
      guard let data = data else {
        completion(.failure(.invalidBotExecutionResponse(detail: "response is empty")))
        return
      }
      
      do {
        guard let serialization = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          completion(.failure(ASF.Error.invalidBotExecutionResponse(detail: "fail initialize json serialization")))
          return
        }
        
        guard let result = serialization["Result"] as? String else {
          completion(.failure(.invalidBotExecutionResponse(detail: "'Result' is not valid string")))
          return
        }
        
        completion(.success(result))
      } catch {
        completion(.failure(.invalidBotExecutionResponse(detail: error.localizedDescription)))
      }
    }.resume()
  }
  
  @available(macOS 12.0.0, *)
  func executeCommandToASF(command: String) async throws -> String {
    var urlRequest = createUrlRequest(url: botCommandUrl)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = {
      """
      {
        "Command": "\(command)"
      }
      """.data(using: .utf8)!
    }()
    
    let (data,_) = try await URLSession.shared.data(for: urlRequest)
    guard let serialization = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      throw ASF.Error.invalidBotExecutionResponse(detail: "fail initialize json serialization")
    }
    
    guard let result = serialization["Result"] as? String else {
      throw ASF.Error.invalidBotExecutionResponse(detail: "'Result' is not valid string")
    }
    
    return result
  }
}

extension ASF {
  enum Error: LocalizedError {
    case invalidBotInfoResponse(detail: String?)
    case invalidBotExecutionResponse(detail: String?)
    
    var errorDescription: String? {
      switch self {
      case let .invalidBotInfoResponse(detail):
        return "Invalid bot info response, fail to decode.(detail \(detail ?? "null"))"
      case let .invalidBotExecutionResponse(detail):
        return "Invalid bot execution feedback response, fail to decode.(detail \(detail ?? "null"))"
      }
    }
  }
}
