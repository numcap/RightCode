//
//  CodeResultItemView.swift
//  RightCode
//
//  Created by Jonathan Ishak on 2025-09-08.
//

import SwiftUI

struct CodeResultItemView: View {
    let title: String
    let desc: String

    var body: some View {
        Text(title)
            .padding(.bottom, -1)
            .font(.largeTitle)
            .bold()
        Text(desc == "" ? "None" : desc)
            .font(desc != "" ? .title3 : .title)
            .padding(.vertical, 40)
            .padding(.horizontal, 50)
            .background(Color(.secondarySystemBackground))
            .clipShape(.buttonBorder)
            .padding(.horizontal, 25)

    }
}

#Preview {
    CodeResultItemView(
        title: "Status",
        desc:
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed scelerisque mi ut nisi accumsan posuere. Aliquam justo nunc, maximus et tempor sit amet, pretium a arcu. Integer orci velit, luctus sed elementum pulvinar, blandit non felis. Curabitur volutpat urna et tortor imperdiet, non blandit turpis luctus. Nulla facilisis tempus libero, a venenatis eros tincidunt vulputate. In ut velit et mi venenatis pellentesque. Maecenas facilisis lorem quis magna vulputate, ac venenatis lectus vulputate. Suspendisse at pellentesque velit. Integer luctus sed dui sed convallis. Sed metus lacus, finibus in magna eu, gravida scelerisque dui. Morbi eget erat vitae leo molestie pellentesque. Fusce mauris enim, rutrum a vulputate in, convallis vitae sem. Maecenas sit amet facilisis velit, ut consequat justo. Vivamus leo odio, tempor id mi non, blandit pharetra nibh. Pellentesque sed sodales massa. Donec sollicitudin augue vel aliquet gravida."
    )
}
