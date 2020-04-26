//
//  Routes.swift
//  ZiipWebSocket
//
//  Created by Underside on 25.04.2020.
//  Copyright © 2020 Underside. All rights reserved.
//

import Foundation

extension Routes {

    enum HubAPI {

        enum HubConfiguration {
            static let configuration = "/configuration"
        }

        enum Participant {
            static let participants = "/participants"
            static func deleteParticipant(with participantId: String) -> String {
                return "participants/\(participantId)"
            }
        }

        enum Meeting {
            static let meetings = "/meetings"
            static func joinToMeetingNotification(with meetingId: String) -> String {
                return "/meetings/\(meetingId)/join"
            }
            static func leaveMeetingNotification(with meetingId: String) -> String {
                return "/meetings/\(meetingId)/leave"
            }
            static func dropMeeting(with meetingId: String) -> String {
                return "/meetings/\(meetingId)/drop"
            }
        }

        enum Call {
            static let calls = "/calls"
            static let answer = "/calls/answer"
            static let reject = "/calls/reject"
            static func deleteCall(with callId: String) -> String { return "/calls/\(callId)" }
        }
        
        enum Audio {
            static let muteSpeaker = "/audio/volume"
            static let muteMicrophone = "/audio/microphone"
            static let volumeLevel = "/audio/volume/level"
        }

        enum Video {
            static let muteVideo = "/video/camera"
            static let upCamera = "/camera/tilt/up"
            static let downCamera = "/camera/tilt/down"
            static let leftCamera = "/camera/pan/left"
            static let rightCamera = "/camera/pan/right"
            static let zoomInCamera = "/camera/zoom/in"
            static let zoomOutCamera = "/camera/zoom/out"
            static let homeCamera = "/camera/ptz/home"
        }

        enum Ultrasonic {
            static func playUltasonic(with hubId: String) -> String {
                return "/hubs/\(hubId)/ultrasonic/play/"
            }
        }

        public enum ScreenSharing {
            static let stopSharing = "/presenting/stop"
            //static func endpointForSharing(for hubId: String) -> String { return "hubs/\(hubId)\(stopSharing)" }
        }
    }
}
