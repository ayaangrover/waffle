import Foundation

class YouTubeAPIManager {
    static let shared = YouTubeAPIManager()
    private init() {}
    
    private let apiKey = "AIzaSyDY1LPW4il2szvuPNFBV8N_dKGRRDD-N44"
    private let baseURL = "https://www.googleapis.com/youtube/v3/videos"
    
    func fetchVideoInfo(id: String) async throws -> YouTubeVideoInfo {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(YouTubeAPIResponse.self, from: data)
        
        guard let videoItem = response.items.first else {
            throw NSError(domain: "YouTubeAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No video found"])
        }
        
        return YouTubeVideoInfo(
            id: videoItem.id,
            title: videoItem.snippet.title,
            thumbnailURL: URL(string: videoItem.snippet.thumbnails.medium.url)!
        )
    }
}

struct YouTubeAPIResponse: Codable {
    let items: [YouTubeVideoItem]
}

struct YouTubeVideoItem: Codable {
    let id: String
    let snippet: YouTubeVideoSnippet
}

struct YouTubeVideoSnippet: Codable {
    let title: String
    let thumbnails: YouTubeVideoThumbnails
}

struct YouTubeVideoThumbnails: Codable {
    let medium: YouTubeVideoThumbnail
}

struct YouTubeVideoThumbnail: Codable {
    let url: String
}
