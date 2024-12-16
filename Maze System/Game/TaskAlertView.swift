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
    var onSubmit: (Bool) -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Task")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            Text(question)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            TextField("Your Answer", text: $answer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    onSubmit(false)  // Treat Cancel as failure
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                .padding()

                Button(action: {
                    let success = !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    presentationMode.wrappedValue.dismiss()
                    onSubmit(success)
                }) {
                    Text("Submit")
                        .font(.headline)
                }
                .padding()
                Spacer()
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(UIColor.systemBackground))
        #endif
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}
