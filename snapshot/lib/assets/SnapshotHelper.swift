//
//  SnapshotHelper.swift
//  Example
//
//  Created by Felix Krause on 10/8/15.
//  Copyright © 2015 Felix Krause. All rights reserved.
//

import Foundation
import XCTest

var deviceLanguage = ""
var locale = ""

@available(*, deprecated, message="use setupSnapshot: instead")
func setLanguage(app: XCUIApplication) {
    setupSnapshot(app)
}

func setupSnapshot(app: XCUIApplication) {
    Snapshot.setupSnapshot(app)
}

func snapshot(name: String, waitForLoadingIndicator: Bool = true, additionalInfos:Dictionary<String,AnyObject>? = nil) {
    Snapshot.snapshot(name, waitForLoadingIndicator: waitForLoadingIndicator, additionalInfos:additionalInfos)
}

public class Snapshot: NSObject {

    public class func setupSnapshot(app: XCUIApplication) {
        setLanguage(app)
        setLocale(app)
        setLaunchArguments(app)
    }

    class func setLanguage(app: XCUIApplication) {
        guard let prefix = pathPrefix() else {
            return
        }

        let path = prefix.stringByAppendingPathComponent("language.txt")

        do {
            let trimCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
            deviceLanguage = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding).stringByTrimmingCharactersInSet(trimCharacterSet) as String
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))"]
        } catch {
            print("Couldn't detect/set language...")
        }
    }

    class func setLocale(app: XCUIApplication) {
        guard let prefix = pathPrefix() else {
            return
        }

        let path = prefix.stringByAppendingPathComponent("locale.txt")

        do {
            let trimCharacterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
            locale = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding).stringByTrimmingCharactersInSet(trimCharacterSet) as String
        } catch {
            print("Couldn't detect/set locale...")
        }
        if locale.isEmpty {
            locale = NSLocale(localeIdentifier: deviceLanguage).localeIdentifier
        }
        app.launchArguments += ["-AppleLocale", "\"\(locale)\""]
    }

    class func setLaunchArguments(app: XCUIApplication) {
        guard let prefix = pathPrefix() else {
            return
        }

        let path = prefix.stringByAppendingPathComponent("snapshot-launch_arguments.txt")
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]

        do {
            let launchArguments = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
            let regex = try NSRegularExpression(pattern: "(\\\".+?\\\"|\\S+)", options: [])
            let matches = regex.matchesInString(launchArguments, options: [], range: NSRange(location:0, length:launchArguments.characters.count))
            let results = matches.map { result -> String in
                (launchArguments as NSString).substringWithRange(result.range)
            }
            app.launchArguments += results
        } catch {
            print("Couldn't detect/set launch_arguments...")
        }
    }

    public class func snapshot(name: String, waitForLoadingIndicator: Bool = true, additionalInfos:Dictionary<String,AnyObject>? = nil) {
        if waitForLoadingIndicator {
            waitForLoadingIndicatorToDisappear()
        }
        var metaInfos = ""
        if let additionalInfos = additionalInfos {
            do {
                let jsonData:NSData? = try NSJSONSerialization.dataWithJSONObject(additionalInfos,options:NSJSONWritingOptions.init(rawValue: 0))
                if let jsonData = jsonData {
                    metaInfos = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as! String
                }
            } catch {
                print("Unable to serialize Additional Info ...")
            }
        }

        // more information about this, check out https://github.com/fastlane/fastlane/tree/master/snapshot
        print("snapshot: \(name) meta: \(metaInfos)")

        sleep(1) // Waiting for the animation to be finished (kind of)
        XCUIDevice.sharedDevice().orientation = .Unknown
    }

    class func waitForLoadingIndicatorToDisappear() {
        let query = XCUIApplication().statusBars.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other)

        while (0..<query.count).map({ query.elementBoundByIndex($0) }).contains({ $0.isLoadingIndicator }) {
            sleep(1)
            print("Waiting for loading indicator to disappear...")
        }
    }

    class func pathPrefix() -> NSString? {
        if let path = NSProcessInfo().environment["SIMULATOR_HOST_HOME"] as NSString? {
            return path.stringByAppendingPathComponent("Library/Caches/tools.fastlane")
        }
        print("Couldn't find Snapshot configuration files at ~/Library/Caches/tools.fastlane")
        return nil
    }
}

extension XCUIElement {
    var isLoadingIndicator: Bool {
        return self.frame.size == CGSize(width: 10, height: 20)
    }
}

// Please don't remove the lines below
// They are used to detect outdated configuration files
// SnapshotHelperVersion [1.2]
