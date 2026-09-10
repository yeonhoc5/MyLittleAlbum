//
//  InfoHiddenAsset.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 5/1/25.
//

import SwiftUI

struct InfoHiddenAsset: View {
    var body: some View {
        VStack {
            Text("가려진 사진이 있음에도 없다고 나오나요?")
                .font(.callout)
                .font(Font.system(size: 10, design: .rounded))
                .foregroundStyle(Color.fancyBackground)
            Text("가려진 사진 안내")
                .font(.title)
                .bold()
                .padding(.top, 20)
                .padding(.bottom, 40)
            VStack(alignment: .leading, spacing: 10) {
                Group {
                    Text("Apple의 정책상, 가려진 사진에서")
                    Text("\"Face ID(또는 암호) 사용\"을 설정하면")
                    VStack(alignment: .trailing) {
                        Image("faceID")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                        Text("기기의 [설정 / 앱 / 사진App]")
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                    .padding(10)
                    Text("애플 자체 앱을 제외한 앱에서는")
                    Text("가려진 사진을 볼 수 없습니다.")
                }
            }
            .lineLimit(1)
            .font(.body)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.ultraThickMaterial)
        }
        .padding(40)
    }
}

#Preview {
    InfoHiddenAsset()
}
