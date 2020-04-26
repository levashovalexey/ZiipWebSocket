//
//  RotateFileDestination.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation
import SwiftyBeaver

public class RotateFileDestination: BaseDestination {

    public var logFileURL: URL?

    override public var defaultHashValue: Int { return 2 }
    private let fileManager = FileManager.default
    private var fileHandle: FileHandle?

    private let maxLogFilesize = (5 * 1024 * 1024) // 5MB

    private let noOfLogFiles = 2 // Number of log files used in rotation

    public override init() {
        // platform-dependent logfile directory default
        var baseURL: URL?
        #if os(OSX)
        if let url = fileManager.urls(for:.cachesDirectory, in: .userDomainMask).first {
            baseURL = url
            // try to use ~/Library/Caches/APP NAME instead of ~/Library/Caches
            if let appName = Bundle.main.object(forInfoDictionaryKey: kCFBundleExecutableKey as String) as? String {
                do {
                    if let appURL = baseURL?.appendingPathComponent(appName, isDirectory: true) {
                        try fileManager.createDirectory(at: appURL,
                                                        withIntermediateDirectories: true, attributes: nil)
                        baseURL = appURL
                    }
                } catch {
                    print("Warning! Could not create folder /Library/Caches/\(appName)")
                }
            }
        }
        #else
        // iOS, watchOS, etc. are using the caches directory
        if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            baseURL = url
        }
        #endif

        if let baseURL = baseURL {
            logFileURL = baseURL.appendingPathComponent("system.log", isDirectory: false)
        }
        super.init()

        levelColor.verbose = "251m"     // silver
        levelColor.debug = "35m"        // green
        levelColor.info = "38m"         // blue
        levelColor.warning = "178m"     // yellow
        levelColor.error = "197m"       // red
    }

    // append to file. uses full base class functionality
    override public func send(_ level: SwiftyBeaver.Level, msg: String, thread: String,
                              file: String, function: String, line: Int, context: Any? = nil) -> String? {
        let formattedString = super.send(level, msg: msg, thread: thread, file: file, function: function, line: line, context: context)

        if let str = formattedString {
            _ = validateSaveFile(str: str)
        }
        return formattedString
    }

    deinit {
        // close file handle if set
        if let fileHandle = fileHandle {
            fileHandle.closeFile()
        }
    }

    /// appends a string as line to a file.
    /// returns boolean about success
    private func saveToFile(str: String) -> Bool {
        guard let url = logFileURL else { return false }
        do {
            if fileManager.fileExists(atPath: url.path) == false {
                // create file if not existing
                let line = str + "\n"
                try line.write(to: url, atomically: true, encoding: .utf8)

                #if os(iOS) || os(watchOS)
                if #available(iOS 10.0, watchOS 3.0, *) {
                    var attributes = try fileManager.attributesOfItem(atPath: url.path)
                    attributes[FileAttributeKey.protectionKey] = FileProtectionType.none
                    try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
                }
                #endif
            } else {
                // append to end of file
                if fileHandle == nil {
                    // initial setting of file handle
                    fileHandle = try FileHandle(forWritingTo: url as URL)
                }
                if let fileHandle = fileHandle {
                    _ = fileHandle.seekToEndOfFile()
                    let line = str + "\n"
                    if let data = line.data(using: String.Encoding.utf8) {
                        fileHandle.write(data)
                    }
                }
            }
            return true
        } catch {
            print("File Destination could not write to file \(url).")
            return false
        }
    }

    /// deletes log file.
    /// returns true if file was removed or does not exist, false otherwise
    public func deleteLogFile() -> Bool {
        guard let url = logFileURL, fileManager.fileExists(atPath: url.path) else { return true }
        do {
            try fileManager.removeItem(at: url)
            fileHandle = nil
            return true
        } catch {
            print("File Destination could not remove file \(url).")
            return false
        }
    }

    private func validateSaveFile(str: String) -> Bool {

        guard let url = logFileURL else { return false }
        let filePath = url.path
        if FileManager.default.fileExists(atPath: filePath) == true {
            do {
                // Get file size
                let attr = try FileManager.default.attributesOfItem(atPath: filePath)
                let fileSize = attr[FileAttributeKey.size] as! UInt64
                // Do file rotation
                if fileSize > maxLogFilesize {
                    rotateFile(filePath)
                }
            } catch {
                print("validateSaveFile error: \(error)")
            }
        }
        return saveToFile(str: str)
    }

    private func rotateFile(_ filePath: String) {

        let lastIndex = noOfLogFiles - 1
        let firstIndex = 1
        do {
            for index in stride(from: lastIndex, to: firstIndex, by: -1) {
                let oldFile = String(format: "%@.%d", filePath, index)
                if FileManager.default.fileExists(atPath: oldFile) == true {
                    if index == lastIndex {
                        // Delete the last file
                        try FileManager.default.removeItem(atPath: oldFile)
                    } else {
                        // Move the current file to next index
                        let newFile = String(format: "%@.%d", filePath, index + 1)
                        try FileManager.default.moveItem(atPath: oldFile, toPath: newFile)
                    }
                }
            }
            // Finally, move the current file
            let newFile = String(format: "%@.d", filePath, firstIndex)
            try FileManager.default.moveItem(atPath: filePath, toPath: newFile )
        } catch {
            print("rotateFile error: \(error)")
        }
    }

}


