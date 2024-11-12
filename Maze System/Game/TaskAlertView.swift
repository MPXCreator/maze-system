//
//  TaskAlertView.swift
//  Maze System
//
//  Created by Reyes on 11/6/24.
//

import SwiftUI

struct TaskAlertView: View {
    let question: String
    @Binding var answer: String
    var onSubmit: () -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("Task", comment: ""))
                .font(.headline)
                .padding(.top)

            Text(question)
                .padding()

            TextField(NSLocalizedString("Your Answer", comment: ""), text: $answer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(NSLocalizedString("Cancel", comment: ""))
                }
                .padding()

                Spacer()

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    onSubmit()
                }) {
                    Text(NSLocalizedString("Submit", comment: ""))
                }
                .padding()
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: 400)
    }
}
