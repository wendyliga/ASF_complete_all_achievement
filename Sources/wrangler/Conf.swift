import Foundation
import SwiftKit

struct Conf: Decodable {
  let botNames: [String]
  let ipcServer: String
  let ipcPassword: String?
  let ipcPort: String
  let intervalInHour: Int
  
  enum CodingKeys: String, CodingKey {
    case botNames = "bot_names"
    case ipcServer = "ipc_server"
    case ipcPassword = "ipc_password"
    case ipcPort = "ipc_port"
    case intervalInHour = "interval_in_hour"
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    botNames = try container.decode(Array<String>.self, forKey: .botNames)
    if botNames.isEmpty {
      throw DecodingError.valueNotFound(Array<String>.self, DecodingError.Context(codingPath: [CodingKeys.botNames], debugDescription: "bot_names is empty, at least provide 1", underlyingError: nil))
    }
    
    self.ipcServer = try DefaultValue<String>.validate(
      condition: { $0.isEmpty },
      then: ASF.defaultIpcServer,
      else: try container.decode(String.self, forKey: .ipcServer)
    )
    
    self.ipcPassword = try DefaultValue<Optional<String>>.validate(
      condition: { $0?.isEmpty == true },
      then: nil,
      else: try container.decodeIfPresent(String.self, forKey: .ipcPassword)
    )
    
    self.ipcPort = try DefaultValue<String>.validate(
        condition: { $0.isEmpty || $0 == "0" },
      then: ASF.defaultIpcPort,
      else: try container.decode(String.self, forKey: .ipcPort)
    )
    
    self.intervalInHour = try container.decode(Int.self, forKey: .intervalInHour)
  }
}
