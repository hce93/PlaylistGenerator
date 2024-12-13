//
//  ListAlertView.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 19/11/2024.
//

import SwiftUI

struct ListAlertView: View {
    let items: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            // Add your text comment or title
            Text("We encountered errors updating the below songs. No changes to these have been made")
                .font(.headline)
                .padding()

            List(items, id: \.self) { item in
                Text(item)
            }

            // Add a "Done" button at the bottom
            Button("Done") {
                dismiss()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center) // Center the button
        }
        .frame(width: 400, height: 400) // Optional: Adjust size of the sheet
    }
}
