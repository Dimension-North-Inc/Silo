//
//  ContentView.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 2022-11-06.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Silo
import IdentifiedCollections

import SwiftUI

struct SampleList: View {
    struct SampleGroup: Identifiable {
        var id: String {
            name
        }
        
        var name: String
        var samples: IdentifiedArrayOf<Sample>
    }
    struct Sample: Identifiable {
        var id: String {
            name
        }
        
        var name: String
        var view: AnyView
    }
    
    private var sections: [SampleGroup] = [
        SampleGroup(
            name: "Observation",
            samples: [
                Sample(
                    name: "Store Observation",
                    view: AnyView(
                        StoreObservationSample()
                    )
                ),
                Sample(
                    name: "WithSubstate Observation",
                    view: AnyView(
                        WithSubstateObservationSample()
                    )
                ),
            ]
        ),
        SampleGroup(
            name: "Side Effects",
            samples: [
                Sample(
                    name: "Repeating Effects",
                    view: AnyView(
                        RepeatingEffectsSample()
                    )
                ),
            ]
        ),
        SampleGroup(
            name: "SwiftUI Support",
            samples: [
                Sample(
                    name: "Bindings",
                    view: AnyView(
                        BindingsSample()
                    )
                ),
            ]
        ),
        SampleGroup(
            name: "Dependency Injection",
            samples: [
                Sample(
                    name: "Injectables",
                    view: AnyView(
                        InjectionSample()
                    )
                ),
            ]
        ),
    ]

    private var allSamples: IdentifiedArrayOf<Sample> {
        IdentifiedArray(uniqueElements: sections.flatMap(\.samples))
    }

    @State
    private var selectedID: Sample.ID?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedID) {
                ForEach(sections) {
                    section in
                    Section(section.name) {
                        ForEach(section.samples) {
                            sample in
                            NavigationLink(value: sample.id) {
                                Label(sample.name, systemImage: "cube.fill")
                            }
                        }
                    }
                }
            }
            #if os(iOS)
            .listStyle(InsetGroupedListStyle())
            #endif
            .navigationTitle("Silo Samples")
            
        } detail: {
            if  let id = selectedID,
                let selection = allSamples[id: id] {
                selection
                    .view
                    .navigationTitle(selection.name)
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                    .padding()
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
