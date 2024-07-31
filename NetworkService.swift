//
//  NetworkService.swift
//  travel
//
//  Created by Artem Vishniakov on 25.09.2023.
//

import Foundation
import ComposableArchitecture

enum RequestMethod: String {
    
    case delete = "DELETE"
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
}

enum RequestError: Error {
    
    case decode
    case invalidURL
    case noResponse
    case unauthorized
    case unexpectedStatusCode
    case unknown
    case server
    case userError
    
    var customMessage: String {
        
        switch self {
        case .decode:
            return "Decode error"
        case .unauthorized:
            return "Session expired"
        case .server:
            return "Что-то пошло не так"
        default:
            return "Unknown error"
        }
    }
}

protocol HTTPClient {
    
    func sendRequest<T: Decodable>(endpoint: BaseEndpoint, responseModel: T.Type, isDecode: Bool) async -> Result<T?, RequestError>
}

extension HTTPClient {
    
    func sendRequest<T: Decodable> (
        endpoint: BaseEndpoint,
        responseModel: T.Type,
        isDecode: Bool
    ) async -> Result<T?, RequestError> {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = endpoint.scheme
        urlComponents.host = endpoint.host
        
#if DEBUG
        
        urlComponents.port = endpoint.port
       
#else
       
#endif
        urlComponents.path = endpoint.path
        urlComponents.queryItems = endpoint.queryItems
      
        guard let url = urlComponents.url else {
            
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header

        if let body = endpoint.body {
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
       
        do {
            let urlSessionConfig = URLSessionConfiguration.default
            
            urlSessionConfig.timeoutIntervalForRequest = 60
            urlSessionConfig.timeoutIntervalForResource = 60
            
            let urlSession = URLSession(configuration: urlSessionConfig)
            
            let (data, response) = try await urlSession.data(for: request)
   
            guard let response = response as? HTTPURLResponse else {
                
                return .failure(.noResponse)
            }
            
            switch response.statusCode {
                
            case 200...299:
                if isDecode {
                    
                    guard let decodedResponse = try? JSONDecoder().decode(responseModel, from: data) else {
                        return .failure(.decode)
                    }
                                        
                    return .success(decodedResponse)
                }
                
                let statusCode: Decodable = StatusCode(statusCode: response.statusCode)
                
                return .success(statusCode as? T)
            
            case 401:
                return .failure(.unauthorized)
                
            case 404:
                return .failure(.userError)
                
            case 500...599:
                return .failure(.server)
                
            default:
                return .failure(.unexpectedStatusCode)
            }
        } catch {
            return .failure(.unknown)
        }
    }
}

protocol NetworkServiceProtocol {
    
    func sendConfirmationCode(email: String) async -> Result<StatusCode?, RequestError>
    func checkOnCorrectCode(email: String, code: String) async -> Result<IsCodeCorrect?, RequestError>
    func checkOnActiveExists(email: String) async -> Result<IsUserExist?, RequestError>
    func createUser(email: String, name: String, code: String) async -> Result<CreateUser?, RequestError>
    func auth(userName: String, code: String) async -> Result<Auth?, RequestError>
    func deleteUser() async -> Result<StatusCode?, RequestError>
    func getUser() async -> Result<UserObject?, RequestError>
    func callback(userName: String, email: String, text: String) async -> Result<StatusCode?, RequestError>
    func authToken(token: String, cameFrom: String) async -> Result<Auth?, RequestError>
    func getAppRoutes() async -> Result<[FullWayObject]?, RequestError>
    func updateToken(refreshToken: String) async -> Result<AccessTokenObject?, RequestError>
    func getFullWayObject(id: Int) async -> Result<FullWayObject?, RequestError>
    func getMapObjects() async -> Result<[MapObjectFullModel]?, RequestError>
    func getFullMapObject(id: Int) async -> Result<MapObjectFullModel?, RequestError>
    func sendFinishedWay(id: Int) async -> Result<StatusCode?, RequestError>
    func downloadWay(id: Int) async -> Result<FullWayObject?, RequestError>
}

struct NetworkService: HTTPClient, NetworkServiceProtocol {
    
    func sendFinishedWay(id: Int) async -> Result<StatusCode?, RequestError> {
        return await sendRequest(endpoint: Endpoint.sendFinishedWay(id: id), responseModel: StatusCode.self, isDecode: false)
    }
    
    func authToken(token: String, cameFrom: String) async -> Result<Auth?, RequestError> {
        return await sendRequest(endpoint: Endpoint.authToken(token: token, cameFrom: cameFrom), responseModel: Auth.self, isDecode: true)
    }

    func sendConfirmationCode(email: String) async -> Result<StatusCode?, RequestError> {
        return await sendRequest(endpoint: Endpoint.sendConfirmationCode(email: email), responseModel: StatusCode.self, isDecode: false)
    }
    
    func checkOnCorrectCode(email: String, code: String) async -> Result<IsCodeCorrect?, RequestError> {
        return await sendRequest(endpoint: Endpoint.isCorrect(email: email, code: code), responseModel: IsCodeCorrect.self, isDecode: true)
    }
    
    func checkOnActiveExists(email: String) async -> Result<IsUserExist?, RequestError> {
        return await sendRequest(endpoint: Endpoint.activeExist(email: email), responseModel: IsUserExist.self, isDecode: true)
    }
    
    func createUser(email: String, name: String, code: String) async -> Result<CreateUser?, RequestError> {
        return await sendRequest(endpoint: Endpoint.createUser(email: email, name: name, code: code), responseModel: CreateUser.self, isDecode: true)
    }
    
    func deleteUser() async -> Result<StatusCode?, RequestError> {
        await sendRequest(endpoint: Endpoint.deleteUser, responseModel: StatusCode.self, isDecode: false)
    }
    
    func auth(userName: String, code: String) async -> Result<Auth?, RequestError> {
        return await sendRequest(endpoint: Endpoint.auth(userName: userName, code: code), responseModel: Auth.self, isDecode: true)
    }
    
    func getUser() async -> Result<UserObject?, RequestError> {
        return await sendRequest(endpoint: Endpoint.getUser, responseModel: UserObject.self, isDecode: true)
    }
    
    func callback(userName: String, email: String, text: String) async -> Result<StatusCode?, RequestError> {
        return await sendRequest(endpoint: Endpoint.callback(userName: userName, email: email, text: text), responseModel: StatusCode.self, isDecode: false)
    }
    
    func getAppRoutes() async -> Result<[FullWayObject]?, RequestError> {
        return await sendRequest(endpoint: Endpoint.getRoutes, responseModel: [FullWayObject].self, isDecode: true)
    }
    
    func updateToken(refreshToken: String) async -> Result<AccessTokenObject?, RequestError> {
        return await sendRequest(endpoint: Endpoint.updateToken(refreshToken: refreshToken), responseModel: AccessTokenObject.self, isDecode: true)
    }
    
    func getUserRoutes() async -> Result<[FullWayObject]?, RequestError> {
        return await sendRequest(endpoint: Endpoint.getUserRoutes, responseModel: [FullWayObject].self, isDecode: true)
    }
    
    func getFullWayObject(id: Int) async -> Result<FullWayObject?, RequestError> {
        return await sendRequest(endpoint: Endpoint.getFullWayObject(id), responseModel: FullWayObject.self, isDecode: true)
    }
    
    func getFullMapObject(id: Int) async -> Result<MapObjectFullModel?, RequestError> {
        return await sendRequest(endpoint: Endpoint.getFullMapObject(id), responseModel: MapObjectFullModel.self, isDecode: true)
    }
    
    func getMapObjects() async -> Result<[MapObjectFullModel]?, RequestError> {
        return await sendRequest(endpoint: Endpoint.getMapObjects, responseModel: [MapObjectFullModel].self, isDecode: true)
    }
    
    func downloadWay(id: Int) async -> Result<FullWayObject?, RequestError> {
        return await sendRequest(endpoint: Endpoint.downloadFullWay(id: id), responseModel: FullWayObject.self, isDecode: true)
    }
}

extension NetworkService: TestDependencyKey {
    static var testValue: NetworkService {
        NetworkService()
    }
}
