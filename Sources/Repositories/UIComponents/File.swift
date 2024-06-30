//
//  File.swift
//  
//
//  Created by Moritz Ellerbrock on 22.06.24.
//

import Foundation
import SwiftTUI

public struct MyTerminalView: View {
    let text: String
    let doneHandler: ((Bool) -> Void)

    public init(text: String,
                doneHandler: @escaping ((Bool) -> Void)) {
        self.text = text
        self.doneHandler = doneHandler
    }
  public var body: some View {
      VStack {
          Text(text)
          Text(text)
          Text(text)
          Text(text)
          Text(text)
          Button("EXIT") {
              doneHandler(true)
          }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }
}
