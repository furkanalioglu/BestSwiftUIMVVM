//
//  BestMVVMSwiftUIApp.swift
//  BestMVVMSwiftUI
//
//  Created by Furkan Alioglu on 20.10.2023.
//

import SwiftUI

@main
struct BestMVVMSwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            var standup = Standup.mock
            let _ = standup.duration = .seconds(6)
            StandupsList(
                model: StandupsListModel(
//                    destination: .detail(
//                        StandupDetailModel(
//                            destination: .record(
//                                RecordMeetingModel(
//                                    standup: standup)
//                            ),
//                            standup: standup
//                        )
//                    )
//                    standups: [standup]
                )
            )
        }
    }
}
