//
//  SortingHeader.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-06-17.
//

import SwiftUI

struct SortingHeader: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        HStack(spacing: 20) {
            Label("Sort", systemImage: "arrow.up.arrow.down")
                .labelStyle(.iconOnly)
                .font(.headline)
                .onTapGesture {
                    viewModel.sortingPreferences.sortingOrderASC.toggle()
                    viewModel.sort(true)
                }
            Picker(
                "Sort By",
                selection: $viewModel.sortingPreferences.sortingMethod
            ) {
                Text("Date").tag(Sort.date)
                Text("Name").tag(Sort.name)
                Text("Language").tag(Sort.language)
            }
            .onChange(
                of: viewModel.sortingPreferences.sortingMethod,
                { viewModel.sort(true) }
            )
            .pickerStyle(.palette)
            .frame(width: 300)
        }
    }
}

#Preview {
    SortingHeader(viewModel: HomeViewModel())
}
