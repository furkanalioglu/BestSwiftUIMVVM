//
//  EditStandupsTest.swift
//  BestMVVMSwiftUITests
//
//  Created by Furkan Alioglu on 20.10.2023.
//

import Foundation
import XCTest
@testable import BestMVVMSwiftUI

class EditStandupsTest : XCTestCase {
    func testDeletion() {
        let model = EditStandupModel(
            standup:
                Standup(
                    id: Standup.ID(UUID()),
                    attendees: [
                        Attendee(id: Attendee.ID(UUID()), name: "Blob"),
                        Attendee(id: Attendee.ID(UUID()), name: "Blob Jr")
                    ]
                )
        )
        model.deleteAttendees(atOffsets: [1])
        XCTAssertEqual(model.standup.attendees.count, 1)
        XCTAssertEqual(model.standup.attendees[0].name, "Blob")
        XCTAssertEqual(model.focus, .attendee(model.standup.attendees[0].id))
    }
    
    func testAdd() {
        let model = EditStandupModel(
            standup: Standup(id:Standup.ID(UUID())))
        
        XCTAssertEqual(model.standup.attendees.count,1)
        XCTAssertEqual(model.focus, .title)
        model.addAttendee()
        XCTAssertEqual(model.standup.attendees.count, 2)
        XCTAssertEqual(model.focus, .attendee(model.standup.attendees[1].id))
    }
}