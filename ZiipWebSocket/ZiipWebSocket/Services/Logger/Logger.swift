//
//  Logger.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation
import SwiftyBeaver

public protocol LoggerProtocol: class {
    func loggerDidUpdated()
}

public class Logger {

    private let file: RotateFileDestination = RotateFileDestination()

    public static weak var delegate: LoggerProtocol?

    public init() {
        configurate()
    }

    public var logFileURL:URL? {
        return file.logFileURL
    }

    public func clearLogs() -> Bool {
        return file.deleteLogFile()
    }

    public func configurate() {

        file.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $L: $M" //to do move to config file
        SwiftyBeaver.addDestination(file)

        #if DEBUG
            // log to Xcode Console
            let console = ConsoleDestination()
            console.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $L: $M"
            SwiftyBeaver.addDestination(console)
        #endif
    }

    public class func verbose(_ message: String = "", function: String = #function, filePath: String = #file, fileLine: Int = #line) {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        SwiftyBeaver.verbose("\(fileName).\(function)[\(fileLine)]: \(message)")
        self.delegate?.loggerDidUpdated()
    }

    public class func debug(_ message: String = "", function: String = #function, filePath: String = #file, fileLine: Int = #line) {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        SwiftyBeaver.debug("\(fileName).\(function)[\(fileLine)]: \(message)")
        self.delegate?.loggerDidUpdated()
    }

    public class func info(_ message: String = "") {
        SwiftyBeaver.info(message)
        self.delegate?.loggerDidUpdated()
    }

    public class func warning(_ message: String = "") {
        SwiftyBeaver.warning(message)
        self.delegate?.loggerDidUpdated()
    }

    public class func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        SwiftyBeaver.error("\(fileName).\(function)[\(line)]: \(error)")
        self.delegate?.loggerDidUpdated()
    }
}

