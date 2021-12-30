import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private let queue = DispatchQueue(label: "com.wendyliga.wrangler.asf", qos: .background)
struct ASF {
    static let defaultIpcServer: String = "http://127.0.0.1"
    static let defaultIpcPort: String = "1242"
    
    let ipcServer: String
    let ipcPassword: String?
    let ipcPort: String
    let botName: String
    
    private let session = URLSession(configuration: .default)
    
    
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
    
    func getSteamId(completion _completion: @escaping (Result<String, ASF.Error>) -> Void) {
        let completion: (Result<String, ASF.Error>) -> Void = { result in
            DispatchQueue.main.async {
                _completion(result)
            }
        }
        
        var urlRequest = createUrlRequest(url: botInfoUrl)
        urlRequest.httpMethod = "GET"
        
        queue.async { [completion] in
            session.dataTask(with: urlRequest) { [completion] (data, response, error) in
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
        
    }
    
    func executeCommandToASF(command: String, completion _completion: @escaping (Result<String, ASF.Error>) -> Void) {
        let completion: (Result<String, ASF.Error>) -> Void = { result in
            DispatchQueue.main.async {
                _completion(result)
            }
        }
        
        var urlRequest = createUrlRequest(url: botCommandUrl)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = {
      """
      {
        "Command": "\(command)"
      }
      """.data(using: .utf8)!
        }()
        
        queue.async { [completion] in
            session.dataTask(with: urlRequest) { [completion] (data, response, error) in
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
