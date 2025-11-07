//
//  CrimeScene.swift
//  Visiom
//
//  Created by jiwon on 11/7/25.
//
import Foundation

struct CrimeScene: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String

    static let mockData: [CrimeScene] = [
        CrimeScene(
            imageName: "crimeSceneDummy1",
            title: "거여동 밀실 살인 사건",
            description: "2003년"
        ),
        CrimeScene(
            imageName: "crimeSceneDummy2",
            title: "서울 노량진 살인 사건",
            description: "3030년"
        ),
        CrimeScene(
            imageName: "crimeSceneDummy3",
            title: "남양주 아파트 밀실 살인 사건",
            description: "2010년"
        ),
        CrimeScene(
            imageName: "crimeSceneDummy4",
            title: "애플 아카데미 사건",
            description: "누가 범인일까"
        ),
    ]
}
