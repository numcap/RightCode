//
//  CodeResultView.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-09-08.
//

import SwiftUI

struct CodeResultView: View {
    @ObservedObject var viewModel: HomeViewModel
    var body: some View {
        VStack {
            CodeResultItemView(title: "Status", desc: viewModel.selectedNote.codeResult?.success.description ?? "")
            CodeResultItemView(title: "Output", desc: viewModel.selectedNote.codeResult?.output ?? "")
            CodeResultItemView(title: "Errors", desc: viewModel.selectedNote.codeResult?.errors ?? "")
            CodeResultItemView(title: "Exit Code", desc: viewModel.selectedNote.codeResult?.exit_code?.description ?? "")
            CodeResultItemView(title: "Execution Time", desc: viewModel.selectedNote.codeResult?.execution_time?.description ?? "")
            CodeResultItemView(title: "Stage", desc: viewModel.selectedNote.codeResult?.stage ?? "")
        }
    }
}

#Preview {
    CodeResultView(viewModel: HomeViewModel())
}
