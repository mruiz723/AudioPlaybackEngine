//
//  FavoritesProvider.swift
//  AudioPlaybackEngine
//
//  Created by Marlon Ruiz Arroyave on 26/11/25.
//

import Foundation

public protocol FavoritesProvider: AnyObject {
    func fetchFavorites(completion: @escaping (Set<String>) -> Void)
    func addFavorite(id: String, completion: (() -> Void)?)
    func removeFavorite(id: String, completion: (() -> Void)?)
}
