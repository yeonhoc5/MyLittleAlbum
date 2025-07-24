//
//  CustomDispatchQueue.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 5/27/25.
//

import Foundation

let userDataQueue = DispatchQueue(label: "userDataQueue",
                                  qos: .userInteractive,
                                  autoreleaseFrequency: .workItem,
                                  target: .global(qos: .userInteractive))
let phDataQueue = DispatchQueue(label: "phDataQueue",
                                    qos: .background,
                                    autoreleaseFrequency: .workItem,
                                    target: .global(qos: .background))
let phPhotosQueue = DispatchQueue(label: "phPhotosQueue",
                                    qos: .userInteractive,
                                    autoreleaseFrequency: .workItem,
                                    target: .global(qos: .userInteractive))
let phImageQueue = DispatchQueue(label: "phImageQueue",
                                    qos: .background,
                                    autoreleaseFrequency: .workItem,
                                    target: .global(qos: .background))

let dispatchGroup = DispatchGroup()


