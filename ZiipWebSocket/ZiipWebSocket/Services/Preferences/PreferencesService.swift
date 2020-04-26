//
//  PreferencesService.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

public protocol PreferencesService {
    
    var userName: String? { get set }
    
}

public class UserPreferencesService: PreferencesService {

    public init() {}

    // MARK: - Private keys
    
    private enum UserDefaultsKeys: String {
        case userName
    }
    
    // MARK: - PreferencesService

    public var userName: String? {
        get {
            return UserDefaults.standard.value(forKey:UserDefaultsKeys.userName.rawValue) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.userName.rawValue)
        }
    }
}
