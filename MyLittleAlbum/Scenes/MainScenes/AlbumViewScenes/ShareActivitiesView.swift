//
//  ShareActivitiesView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/24/26.
//

import SwiftUI

struct ShareActivity: Identifiable {
  let id: UUID
  let date: Date
  let user: String
  let album: String
  let activity: String
  
}
let activity1 = ShareActivity(id: UUID(),
                              date: Date(),
                              user: "최연호",
                              album: "오키나와",
                              activity: "32장의 사진 공유")
let activity2 = ShareActivity(id: UUID(),
                              date: Date(),
                              user: "윤치하",
                              album: "25년3월 한우목장",
                              activity: "100장의 사진 공유")


struct ShareActivitiesView: View {
  let activities: [ShareActivity] = [activity1, activity2]
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("최근 공유 활동")
          .font(.headline).fontWeight(.heavy)
          .foregroundStyle(.white)
        Spacer()
        Text("전체 보기 >")
          .font(.caption)
          .foregroundStyle(.gray)
      }
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 10)
          .foregroundStyle(Color.folder)
        VStack(alignment: .leading) {
          ForEach(activities) { act in
            activityLineView(act)
          }
        }
        .padding(10)
      }
    }
    .padding(10)
  }
  func activityLineView(_ activity: ShareActivity) -> some View {
    HStack(spacing: 10) {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .foregroundStyle(.gray)
        Text(activity.user)
          .font(.caption).bold()
          .foregroundStyle(.white)
      }
      .frame(width: 50, height: 30)
      VStack(alignment: .leading) {
        Text("\(actDate(date: activity.date))")
        HStack {
          Text("[\(activity.album)]").bold()
          Text(activity.activity)
        }
      }
      .font(.caption)
    }
  }
  func actDate(date: Date) -> String {
    let fommatter = DateFormatter()
    fommatter.locale = Locale(identifier: "ko_KR")
    fommatter.dateFormat = "yyyy/MM/dd-HH:mm"
    let date = fommatter.string(from: date)
    return date
  }
}

#Preview {
  ShareActivitiesView()
}
