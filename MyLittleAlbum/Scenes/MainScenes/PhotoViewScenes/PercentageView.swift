//
//  PercentageView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 5/6/26.
//

import SwiftUI

struct PercentageView: View {
  let readyCount: Int
  let allCount: Int
  let nameSpace: Namespace.ID
  let cancel: () -> Void
  
  var body: some View {
    let percent = CGFloat(readyCount) / CGFloat(allCount)
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .matchedGeometryEffect(id: "용량순", in: nameSpace)
        .foregroundStyle(Color.fancyBackground)
      RoundedRectangle(cornerRadius: 20)
        .stroke(.ultraThinMaterial, lineWidth: 1)
    }
    .frame(width: 180, height: 180)
        .overlay {
          VStack {
            Spacer()
            Text("용량순 보기")
              .matchedGeometryEffect(id: "용량순보기sort", in: nameSpace)
            ProgressView(value: percent)
            .frame(width: 100)
            Text(" \(readyCount) / \(allCount)")
            Spacer()
            Button {
              cancel()
            } label: {
              ZStack {
                Capsule().foregroundStyle(.white)
                Text("취소").foregroundStyle(Color.fancyBackground)
              }
            }
            .frame(width: 100, height: 30)
          }
          .padding(30)
        }
  }
}

#Preview {
  PercentageView(readyCount: 10,
                 allCount: 100,
                 nameSpace: Namespace().wrappedValue) {
    
  }
}
