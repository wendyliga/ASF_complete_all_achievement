import ArgumentParser
import Foundation

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
  @Argument(
    help: ArgumentHelp("ASF bot names", discussion: "", valueName: "string", shouldDisplay: true)
  )
  var botNames: [String]
  
  @Option(
    help: ArgumentHelp(
      "IP where ASF is hosted(with http protocol)",
      discussion: "only supply this if you run your ASF on a server or docker.Learn more https://github.com/JustArchiNET/ArchiSteamFarm/wiki/IPC",
      valueName: "http://127.0.0.1",
      shouldDisplay: true
    )
  )
  var ipcServer: String = "http://127.0.0.1"
  
  @Option(
    help: ArgumentHelp(
      "Password for IPC",
      discussion: "ASF by default doesn't use any password for IPC, but if you do, you need to supply it here.Learn more https://github.com/JustArchiNET/ArchiSteamFarm/wiki/IPC#authentication",
      valueName: "password",
      shouldDisplay: true
    )
  )
  var ipcPassword: String?
  
  @Option(
    help: ArgumentHelp(
      "Port for IPC",
      discussion: "ASF use 1242 by default, if you use custom port forwarding on your server or docker, you need to supply it here",
      valueName: "1242",
      shouldDisplay: true
    )
  )
  var ipcPort: Int = 1242
  
  @Option(
    help: ArgumentHelp(
      "How often to execute the task",
      discussion: "how often to check the check and complete all achievement. if you don't want to check it periodically, set it to 0",
      valueName: "12",
      shouldDisplay: true
    )
  )
  var executionInterval: Int = 12
  
  mutating func validate() throws {
    if ipcServer.isEmpty || ipcServer.lowercased().contains("localhost") {
      ipcServer = "http://127.0.0.1"
    }
  }
  
  /**
   need to wait for swift-argument-parser to support executing `run()` with async
   */
  @available(macOS 12.0.0, *)
  func execute() async throws {
//    let steamId = try await getSteamId()
//    let gameList = try await getGameList(steamId: steamId)
//    let commands = gameList.games.game.map { "aset \(botName) \($0.appId) *" }
//    await withThrowingTaskGroup(of: Void.self, body: { group in
//      for command in commands {
//        group.addTask {
//          let result = try await executeCommandToASF(command: command)
//          print(result)
//        }
//      }
//    })
  }
  
  func run() throws {
    // execution
    guard executionInterval != 0 else {
      print("Execution: run once only")

      for botName in botNames {
        Task.completeAllAchievement(ipcServer: ipcServer, ipcPassword: ipcPassword, ipcPort: ipcPort, botName: botName)
      }

      print("Finish.")
      return
    }
    
    print("Execution: periodically every \(executionInterval) hour(s)")
    Task.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(executionInterval * 60 * 360), repeats: true, block: { _ in
      for botName in botNames {
        Task.completeAllAchievement(ipcServer: ipcServer, ipcPassword: ipcPassword, ipcPort: ipcPort, botName: botName)
      }

      print("Sleeping, waiting for next cycle")
    })
    
    // start
    Task.timer.fire()
    
    // run indefinitely
    RunLoop.main.run()
  }
}
