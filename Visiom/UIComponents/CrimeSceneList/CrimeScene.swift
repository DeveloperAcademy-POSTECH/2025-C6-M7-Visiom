//
//  CrimeScene.swift
//  Visiom
//
//  Created by jiwon on 11/7/25.
//
import Foundation

enum CrimeSceneStatus: String {
    case coldcase = "미제"
    case investigating = "수사 중"
    case solved = "완료"
}

struct CrimeScene: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let occuredDate: String
    let location: String
    let status: CrimeSceneStatus
    let fileName: String

    static let mockData: [CrimeScene] = [
        CrimeScene(
            imageName: "crimeSceneDummy4",
            title: "애플 아카데미 사건",
            occuredDate: "2025.10.8",
            location: "경상북도 포항시 청암로77",
            status: .investigating,
            fileName: "Immersive"
        ),
        CrimeScene(
            imageName: "crimeSceneDummy1",
            title: "거여동 밀실 살인 사건",
            occuredDate: "2025.10.8",
            location: "경상북도 포항시 청암로77",
            status: .investigating,
            fileName: "Inside"
        ),
        CrimeScene(
            imageName: "crimeSceneDummy2",
            title: "서울 노량진 살인 사건",
            occuredDate: "2025.10.8",
            location: "경상북도 포항시 청암로77",
            status: .coldcase,
            fileName: "Immersive"
        ),
        CrimeScene(
            imageName: "crimeSceneDummy3",
            title: "아파트 밀실 살인 사건",
            occuredDate: "2025.10.8",
            location: "경상북도 포항시 청암로77",
            status: .solved,
            fileName: "Inside"
        ),
    ]
}
