import Foundation

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

enum Task {
  // timer to handle all task
  static var timer = Timer(fire: Date(), interval: 1, repeats: false, block: {_ in})
  
  static func completeAllAchievement(
    ipcServer: String,
    ipcPassword: String?,
    ipcPort: Int,
    botName: String
  ) {
    var startTime = timespec()
    clock_gettime(CLOCK_MONOTONIC, &startTime)
    
    // confirmation
    print("Botname:", botName)
    print("IPC server:", ipcServer)
    print("IPC port:", ipcPort)
    print("IPC password: \(ipcPassword == nil ? "null" : "supplied")")
    
    let groupDispatch = DispatchGroup()
    var steamId: String?
    var gameList: Steam.GamesList?
    let asfClient = ASF(
      ipcServer: ipcServer,
      ipcPassword: ipcPassword,
      ipcPort: ipcPort,
      botName: botName
    )
    
    // fetch steam id from asf bot
    groupDispatch.enter()
    asfClient.getSteamId { result in
      switch result {
      case let .success(_steamId):
        print("SteamID: \(_steamId)")
        steamId = _steamId
      case let .failure(error):
        print(error.localizedDescription)
      }
      groupDispatch.leave()
    }
    groupDispatch.wait()
    
    // fetch account game list from steam
    groupDispatch.enter()
    // stop if no steam id is found, means previous operation is end with failure
    guard let _steamId = steamId else { return }
    Steam.getGameList(steamId: _steamId) { result in
      switch result {
      case let .success(list):
        print("Found \(list.games.game.count) games")
        gameList = list
      case let .failure(error):
        print(error.localizedDescription)
      }
      groupDispatch.leave()
    }
    groupDispatch.wait()
    
    // communicate with asf, to execute command
    groupDispatch.enter()
    // stop if no game list is found, means previous operation is end with failure
    guard let _gameList = gameList else { return }
    let executeCommandGroupDispatch = DispatchGroup()
    
    // execute each command by queue
    for game in _gameList.games.game {
      executeCommandGroupDispatch.enter()
      let command = "aset \(botName) \(game.appId) *"
      print("Executing: \(game.name)(\(game.appId))")
      asfClient.executeCommandToASF(command: command) { result in
        switch result {
        case let .success(response):
          print(response)
        case let .failure(error):
          print(error.localizedDescription)
        }
        
        executeCommandGroupDispatch.leave()
      }
      executeCommandGroupDispatch.wait()
    }
    groupDispatch.leave()
    
    // calculating elapsed time
    var finishTime = timespec()
    clock_gettime(CLOCK_MONOTONIC, &finishTime)
    let elapsedTime = Double(finishTime.tv_sec-startTime.tv_sec) + Double((finishTime.tv_nsec-startTime.tv_nsec)/1000000000)
    print("Finish executing \(gameList!.games.game.count) games in \(String(format: "%.2f", elapsedTime)) seconds.")
  }
  
//https://gist.githubusercontent.com/C4illin/e8c5cf365d816f2640242bf01d8d3675/raw/9c64ec3e1c614856e444e69a7b9d4a70dfc6a76f/Steam%2520Codes
}
