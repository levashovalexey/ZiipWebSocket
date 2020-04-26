//
//  Routes+CloudAPI.swift
//  ZiipWebSocket
//
//  Created by Underside on 26.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

extension Routes {
    
    public enum CloudAPI {

        static let tokenHeaderKey = "Authorization"
        static let hubSecurityCodeQueryKey = "security_code"

        // MARK: - AnyUser (General Accounts Management) API

        public enum AnyUser {

            static let login = "auth/login"
            static let verifyEmail = "verify_email"
            static let forgotPassword = "forget_password"
            static let resetPassword = "reset_password"
            static let createUser = "users"

        }

        // MARK: - User (User Management) API

        public enum ZiipRoomUser {

            static let currentUser = "user"
            static let changePasswordForCurrentUser = "user/password"
            static let sendVerifyEmailForCurrentUser = "user/send_verify_email"
            static let globalSystemConfig = "system/config"
            static func endpointForUser(withId id: String) -> String { return "users/\(id)/" }
            static func endpointForPasswordChange(for userId: String) -> String { return "users/\(userId)/password" }
            static func endpointForEmailVerification(for userId: String) -> String { return "users/\(userId)/send_verify_email" }
            static func endpointForOrganizations(for userId: String) -> String { return "users/\(userId)/organizations" }
            static func endpointForOrganizationConfig(for organizationId: String) -> String { return "organizations/\(organizationId)/config" }

        }

        // MARK: - HubInfo (Hub Information) API

        public enum HubInfo {

            static let info = "/hubs/code/"
            static func endpointForConfiguration(for hubId: String) -> String { return "hubs/\(hubId)/configuration" }
            static func endpointForName(for hubId: String) -> String { return "hubs/\(hubId)/" }

        }
    }
}

