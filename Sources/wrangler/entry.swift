import ArgumentParser
import Foundation

// disable pathkit on windows as there're no any windows equivalent of `glob` used on pathkit
#if !os(Windows)
import PathKit
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@main
struct Entry {
    static func main() {
        #if !os(Windows)
        // check if user use config.conf as set up source
        syntesize_argument_from_config_file: do {
            let confPath = Path.current + Path("config.json")
            
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
                    
                    if conf.claimFreeGame {
                        arguments.append("--claim-free-game")
                    }
                    
                    // programatically synthesize argument based on conf file
                    CommandLine.arguments.append(contentsOf: arguments)
                } catch {
                    Log.error(error)
                }
            }
        }
        #endif
            
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
            
            if let claimFreeGame = ProcessInfo.processInfo.environment["CLAIM_FREE_GAME"], claimFreeGame.lowercased() == "true" {
                CommandLine.arguments.append("--claim-free-game")
            }
        }
        
        // run command instead
        Main.main()
    }
}

struct Main: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "",
            abstract: "ArchiSteamFarm helper to complete all achievement on library and Claim free games",
            version: version
        )
    }
    
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
            valueName: "24",
            shouldDisplay: true
        )
    )
    var executionInterval: Int = 24
    
    @Flag(help: "Use this flag to automatically claim free game from https://gist.githubusercontent.com/C4illin/e8c5cf365d816f2640242bf01d8d3675/raw/9c64ec3e1c614856e444e69a7b9d4a70dfc6a76f/Steam%2520Codes")
    var claimFreeGame: Bool = false
    
    mutating func validate() throws {
        if ipcServer.isEmpty || ipcServer.lowercased().contains("localhost") {
            ipcServer = ASF.defaultIpcServer
        }
    }
    
    func run() throws {
        Log.info("Botname: " + botNames.joined(separator: ", "))
        Log.info("IPC server: " + ipcServer)
        Log.info("IPC port: " + ipcPort)
        Log.info("IPC password: \(ipcPassword == nil ? "null" : "supplied")")
        Log.info("Execution: " + (executionInterval == 0 ? "run once only" : "periodically every \(executionInterval) hour(s)"))
        Log.info("Claim Free Game: " + (claimFreeGame ? "yes" : "no"))
        
        Task.timer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(executionInterval * 60 * 360),
            repeats: executionInterval != 0,
            block: { _ in
                for botName in botNames {
                    DispatchQueue.global(qos: .background).async {
                        Task.completeAllAchievement(ipcServer: ipcServer, ipcPassword: ipcPassword, ipcPort: ipcPort, botName: botName)
                    }
                    
                    if claimFreeGame {
                        // run it concurrently
                        DispatchQueue.global(qos: .background).async {
                            Task.claimFreeGame(
                                ipcServer: ipcServer,
                                ipcPassword: ipcPassword,
                                ipcPort: ipcPort,
                                botName: botName
                            )
                        }
                    }
                }
            }
        )
        
        // start
        Task.timer.fire()
        
        // run indefinitely
        RunLoop.main.run()
    }
}
