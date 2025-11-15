//
//  TemplateItem.swift
//  Trume
//
//  Created by CM on 2025/11/8.
//

import Foundation

enum TemplateCategory: String, Codable, CaseIterable, Identifiable {
    case preset
    case custom
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .preset:
            return "Preset Styles"
        case .custom:
            return "Custom"
        }
    }
}

struct TemplateItem: Identifiable, Codable, Equatable {
    enum ImageSource: Codable, Equatable {
        case remote(url: URL)
        case base64(String)
        
        private enum CodingKeys: String, CodingKey {
            case type
            case value
        }
        
        private enum SourceType: String, Codable {
            case remote
            case base64
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(SourceType.self, forKey: .type)
            
            switch type {
            case .remote:
                let urlString = try container.decode(String.self, forKey: .value)
                guard let url = URL(string: urlString) else {
                    throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid URL string.")
                }
                self = .remote(url: url)
            case .base64:
                let base64 = try container.decode(String.self, forKey: .value)
                self = .base64(base64)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .remote(let url):
                try container.encode(SourceType.remote, forKey: .type)
                try container.encode(url.absoluteString, forKey: .value)
            case .base64(let base64):
                try container.encode(SourceType.base64, forKey: .type)
                try container.encode(base64, forKey: .value)
            }
        }
    }
    
    let id: String
    var name: String
    var detail: String
    var category: TemplateCategory
    var styleCode: String
    var imageSource: ImageSource
    var createdAt: Date
    var isSystemTemplate: Bool
    var isDefault: Bool = false
    
    init(
        id: String = UUID().uuidString,
        name: String,
        detail: String,
        category: TemplateCategory,
        styleCode: String,
        imageSource: ImageSource,
        createdAt: Date = Date(),
        isSystemTemplate: Bool = false,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.category = category
        self.styleCode = styleCode
        self.imageSource = imageSource
        self.createdAt = createdAt
        self.isSystemTemplate = isSystemTemplate
        self.isDefault = isDefault
    }
    
    var base64Image: String? {
        switch imageSource {
        case .remote:
            return nil
        case .base64(let base64):
            return base64
        }
    }
}


