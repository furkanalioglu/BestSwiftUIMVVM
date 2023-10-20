//
//  EditStandup.swift
//  BestMVVMSwiftUI
//
//  Created by Furkan Alioglu on 20.10.2023.
//

import SwiftUI
import SwiftUINavigation

final
class EditStandupModel: ObservableObject {
//    @FocusState var focus : EditStandupView.Field?
    @Published var focus : EditStandupView.Field?
    @Published var standup : Standup
    
    //We can move on appear to the initalizer of model
    init(
        standup: Standup,
        focus: EditStandupView.Field? = .title) {
        self.focus = .title
        self.standup = standup
        if self.standup.attendees.isEmpty {
            self.standup.attendees.append(
                Attendee(id: Attendee.ID(UUID()), name: "")
            )
        }
    }
    
    func deleteAttendees(atOffsets indices : IndexSet) {
        self.standup.attendees.remove(
            atOffsets: indices
        )
        if self.standup.attendees.isEmpty {
            self.standup.attendees.append(
                Attendee(id: Attendee.ID(UUID()), name: "")
            )
        }
        //Unfortunately focus state can not be intended by the ObservableObject
        //But we did it with library
        let index = min(indices.first!, self.standup.attendees.count - 1)
        self.focus = .attendee(self.standup.attendees[index].id)
    }
    
    func addAttendee() {
        let newAttendee = Attendee(id: Attendee.ID(UUID()), name: "")
        self.standup.attendees.append(newAttendee)
        self.focus = .attendee(newAttendee.id)
    }
}

struct EditStandupView: View {
    enum Field: Hashable{
        case attendee(Attendee.ID)
        case title
    }
    
//    @Binding var standup: Standup
    @FocusState private var focus: Field?
    @ObservedObject var model : EditStandupModel
    
    //For some reason (maybe swiftui bug) this focus is not working
    //so wee add it in viewDidAppear
//    init(standup: Binding<Standup>, focus: Field? = .title) {
//        self._standup = standup
//        self.focus = focus
//    }
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: self.$model.standup.title)
                    .focused($focus, equals: .title)
                HStack {
                    Slider(
                        value: self.$model.standup.duration.seconds,
                        in: 5...30, step: 1
                    ) {
                        Text("Length")
                    }
                    Spacer()
                    Text(self.model.standup.duration.formatted(.units()))
                }
                ThemePicker(selection: self.$model.standup.theme)
            } header: {
                Text("Standup Info")
            }
            Section {
                ForEach(self.$model.standup.attendees) { $attendee in
                    TextField("Name", text: $attendee.name)
                        .focused($focus, equals: .attendee(attendee.id))
                }
                .onDelete { indices in
                    self.model.deleteAttendees(atOffsets: indices)
                }
                
                Button("New attendee") {
                    let newAttendee = Attendee(id: Attendee.ID(UUID()), name: "")
                    self.model.standup.attendees.append(newAttendee)
                }
            } header: {
                Text("Attendees")
            }
        }.bind(self.$model.focus, to: self.$focus)
    }
}

struct ThemePicker: View {
    @Binding var selection: Theme
    
    var body: some View {
        Picker("Theme", selection: $selection) {
            ForEach(Theme.allCases) { theme in
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.mainColor)
                    Label(theme.name, systemImage: "paintpalette")
                        .padding(4)
                }
                .foregroundColor(theme.accentColor)
                .fixedSize(horizontal: false, vertical: true)
                .tag(theme)
            }
        }
    }
}

extension Duration {
    fileprivate var seconds: Double {
        get { Double(self.components.seconds / 60) }
        set { self = .seconds(newValue * 60) }
    }
}

struct EditStandup_Previews: PreviewProvider {
    static var previews: some View {
        WithState(initialValue: Standup.mock) { $standup in
            EditStandupView(model: EditStandupModel(standup: .mock))
        }
    }
}
