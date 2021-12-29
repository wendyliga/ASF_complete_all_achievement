import ArgumentParser
import Foundation
import PathKit

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@main
struct Entry {
    static func main() {
        // check if user use config.conf as set up source
        syntesize_argument_from_config_file: do {
            let confPath = Path.current + Path("config.conf")
            
            if confPath.exists {
                do {
                    let data = try confPath.read()
                    let conf = try JSONDecoder().decode(Conf.self, from: data)
                    
                    var arguments: [String] = conf.botNames + [
                        "--ipc-server",
                        conf.ipcServer,
                        "--ipc-port",
                        conf.ipcPort,
                        "--execution-interval",
                        String(conf.intervalInHour)
                    ]
                    
                    if let password = conf.ipcPassword {
                        arguments.append(contentsOf: ["--ipc-password", password])
                    }
                    
                    // programatically synthesize argument based on conf file
                    CommandLine.arguments.append(contentsOf: arguments)
                } catch {
                    print(error)
                }
            }
        }
        
        // read from environment
        syntesize_argument_from_environment: do {
            if let botNames = ProcessInfo.processInfo.environment["BOT_NAMES"] {
                let botNames = botNames.split(separator: ",").map(String.init)
                CommandLine.arguments.append(contentsOf: botNames)
            }
            
            if let ipcServer = ProcessInfo.processInfo.environment["IPC_SERVER"] {
                CommandLine.arguments.append(contentsOf: ["--ipc-server", ipcServer])
            }
            
            if let ipcPort = ProcessInfo.processInfo.environment["IPC_PORT"] {
                CommandLine.arguments.append(contentsOf: ["--ipc-port", ipcPort])
            }
            
            if let ipcPassword = ProcessInfo.processInfo.environment["IPC_PASSWORD"] {
                CommandLine.arguments.append(contentsOf: ["--ipc-password", ipcPassword])
            }
            
            if let executionInterval = ProcessInfo.processInfo.environment["EXECUTION_INTERVAL"] {
                CommandLine.arguments.append(contentsOf: ["--execution-interval", executionInterval])
            }
        }
        
        // run command instead
        Main.main()
    }
}

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
    var ipcPort: String = "1242"
    
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
            ipcServer = ASF.defaultIpcServer
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
