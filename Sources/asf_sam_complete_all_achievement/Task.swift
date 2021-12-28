import Foundation

enum Task {
  // timer to handle all task
  static var timer = Timer(fire: Date(), interval: 1, repeats: false, block: {_ in})
  
  static func completeAllAchievement(
    ipcServer: String,
    ipcPassword: String?,
    ipcPort: Int,
    botName: String
  ) {
    let startTime = CFAbsoluteTimeGetCurrent()
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
    let finishTime = CFAbsoluteTimeGetCurrent()
    let elapsedTime = String(format: "%.2f", finishTime-startTime)
    print("Finish executing \(gameList!.games.game.count) games in \(elapsedTime) seconds.")
  }
}
