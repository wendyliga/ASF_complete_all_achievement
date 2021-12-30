import Foundation

enum Task {
    // timer to handle all task
    static var timer = Timer(fire: Date(), interval: 1, repeats: false, block: {_ in})
    
    static func completeAllAchievement(
        ipcServer: String,
        ipcPassword: String?,
        ipcPort: String,
        botName: String
    ) {
        #if !os(Windows)
        var startTime = timespec()
        clock_gettime(CLOCK_MONOTONIC, &startTime)
        #endif
        
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
                Log.info("SteamID: \(_steamId)", prefix: "\(botName) achievement")
                steamId = _steamId
            case let .failure(error):
                Log.error(error.localizedDescription, prefix: "\(botName) achievement")
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
                Log.info("Found \(list.games.game.count) games", prefix: "\(botName) achievement")
                gameList = list
            case let .failure(error):
                Log.error(error.localizedDescription, prefix: "\(botName) achievement")
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
            Log.info("Executing: \(game.name)(\(game.appId))", prefix: "\(botName) achievement")
            asfClient.executeCommandToASF(command: command) { result in
                switch result {
                case let .success(response):
                    Log.info(response, prefix: "\(botName) achievement")
                case let .failure(error):
                    Log.error(error, prefix: "\(botName) achievement")
                }
                
                executeCommandGroupDispatch.leave()
            }
            executeCommandGroupDispatch.wait()
        }
        groupDispatch.leave()
        
        #if !os(Windows)
        // calculating elapsed time
        var finishTime = timespec()
        clock_gettime(CLOCK_MONOTONIC, &finishTime)
        let elapsedTime = Double(finishTime.tv_sec-startTime.tv_sec) + Double((finishTime.tv_nsec-startTime.tv_nsec)/1000000000)
        Log.info("Finish executing \(gameList!.games.game.count) games in \(String(format: "%.2f", elapsedTime)) seconds.", prefix: "\(botName) achievement")
        #else
        Log.info("Finish executing \(gameList!.games.game.count) games.", prefix: "\(botName) achievement")
        #endif
    }
    
    static func claimFreeGame(
        ipcServer: String,
        ipcPassword: String?,
        ipcPort: String,
        botName: String
    ) {
        let groupDispatch = DispatchGroup()
        let asfClient = ASF(
            ipcServer: ipcServer,
            ipcPassword: ipcPassword,
            ipcPort: ipcPort,
            botName: botName
        )
        var freeGameIds = [String]()
        
        // fetch free game list
        groupDispatch.enter()
        Steam.getFreeGameList { result in
            switch result {
            case let .success(gameIds):
                Log.info("Free games total is \(gameIds.count)", prefix: "\(botName) claim free game")
                freeGameIds = gameIds
            case let .failure(error):
                Log.error(error.localizedDescription, prefix: "\(botName) claim free game")
            }
            groupDispatch.leave()
        }
        groupDispatch.wait()
        
        // communicate with asf, to execute command
        groupDispatch.enter()
        // stop if no game list is empty, means previous operation is end with failure
        guard freeGameIds.isNotEmpty else { return }
        
        // propagate gameids to a group of 50 item
        // as steam has limitation to claim 50 games an hour
        var count = 0
        var temp = [String]()
        var commands = [String]()
        var delay = false
        for gameId in freeGameIds {
            temp.append(gameId)
            
            if count == 50 {
                commands.append(temp.joined(separator: ","))
                count = 0
                temp.removeAll()
            } else {
                count += 1
            }
        }
        
        let executeCommandGroupDispatch = DispatchGroup()
        func execute(command: String) {
            Log.info("Executing \(command)", prefix: "\(botName) claim free game")
            asfClient.executeCommandToASF(command: command) { result in
                switch result {
                case let .success(response):
                    Log.info(response, prefix: "\(botName) claim free game")
                case let .failure(error):
                    Log.error(error, prefix: "\(botName) claim free game")
                }

                executeCommandGroupDispatch.leave()
            }
        }
        
        // execute each command by queue
        for command in commands {
            executeCommandGroupDispatch.enter()
            let fullCommand = "addlicense \(botName) \(command)"
            
            if delay {
                Log.info("Waiting 1 Hour...", prefix: "\(botName) claim free game")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3600) {
                    execute(command: fullCommand)
                }
            } else {
                delay = true
                execute(command: fullCommand)
            }
            
            executeCommandGroupDispatch.wait()
        }
        groupDispatch.leave()
        Log.info("finish", prefix: "\(botName) claim free game")
    }
}
