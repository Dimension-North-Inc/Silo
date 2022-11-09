//
//  ContentView.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 2022-11-06.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Silo
import SwiftUI

struct SampleList: View {
    struct Sample: Identifiable {
        var id = UUID()
        
        var name: String
        var view: AnyView
    }
    
    @State
    private var samples: IdentifiedArray = [
        Sample(
            name: "Observable Store",
            view: AnyView(
                ObservableStore()
            )
        ),
        Sample(
            name: "Repeating Effects",
            view: AnyView(
                RepeatingEffects()
            )
        ),
        Sample(
            name: "Binding Actions",
            view: AnyView(
                Bindings()
            )
        ),
    ]

    @State
    private var selectedID: Sample.ID?

    var body: some View {
        NavigationSplitView {
            List(samples, selection: $selectedID) {
                sample in
                NavigationLink(value: sample.id) {
                    Label(sample.name, systemImage: "cube.fill")
                }
            }
            .navigationTitle("Silo Samples")
        } detail: {
            if  let id = selectedID,
                let selection = samples[id] {
                selection
                    .view
                    .navigationTitle(selection.name)
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
            } else {
                VStack {
                    Image(systemName: "cube.fill")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                    Text("Pick A Sample!")
                }
                .padding()
            }
        }
    }
}

struct SampleList_Previews: PreviewProvider {
    static var previews: some View {
        SampleList()
    }
}
