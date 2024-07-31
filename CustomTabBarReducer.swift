//
//  CustomTabBarReducer.swift
//  travel
//
//  Created by Artem Vishniakov on 26.09.2023.
//

import SwiftUI
import ComposableArchitecture
import SwiftKeychainWrapper

enum ErrorType: Equatable {
    
    case noInternet
    case requestError
}

struct CustomTabBarCoordinatorReducer: Reducer {

    @AppStorage("showAuth") var showAuth: Bool?
    
    let networkService: NetworkService
    let networkMonitorManager: NetworkMonitorManager

    enum TabBarItem: Hashable {
        
        case main, map, profile, additionaly
        
        var image: String {
            
            switch self {
                
            case .main:
                return "main"
            
            case .map:
                return "map"
            
            case .profile:
                return "profile"
            
            case .additionaly:
                return "additionally"
            }
        }
        
        var isActive: Bool {
            
            switch self {
                
            case .additionaly:
                return false
            
            default: return true
            }
        }
    }
    
    struct State: Equatable {
        
        static let initialState = State(home: .initialState,
                                        progress: .initialState,
                                        profile: .initialState,
                                        selectedTab: .main)
        
        var home: MainCoordinatorReducer.State
        var progress: MapCoordinatorReducer.State
        var profile: ProfileCoordinatorReducer.State
        
        var tabBarIsHidden: Bool = false
        var isLoading: Bool = false
        
        var selectedTab: TabBarItem
        var isShowAdditionalModal: Bool = false
        var isShowDeleteProfileModal: Bool = false
        var isShowCacheDeleteModal: Bool = false
        var isShowSuccefullyDeleteCacheModal: Bool = false
        
        var documentType: DocumentType = .confidentialPolitic
        
        var isSuccefullyDeletedCache: Bool = false
        
        var isShowErrorModal: Bool = false
        
        var sizeAllFiles: String = ""
    }
    
    enum Action {
        
        case home(MainCoordinatorReducer.Action)
        case map(MapCoordinatorReducer.Action)
        case profile(ProfileCoordinatorReducer.Action)
        case tabSelected(TabBarItem)
        
        case showTabBar
        case hideTabBar
        case additionalyTapped
        
        case showDeleteModal
        case showCacheDeleteModal
        case showSuccefullyDeleteCacheModal
        case showDocumentView
        
        case deleteProfileTapped
        
        case cancelDeletProfileTapped
        case cancelCacheDeleteTapped
        case cancelSuccefullyDeleteTapped
        
        case closeAllModals
        case deleteUser
        case deleteUserResponse((Bool?, RequestError?))
        case deleteCache
        
        case updateDocumentType(DocumentType)
        
        case showErrorModal
        case errorHandling
    }
        
    var body: some ReducerOf<Self> {
        
        Scope(state: \.home, action: /Action.home) {
            MainCoordinatorReducer(networkService: networkService,
                                   networkMonitorManager: networkMonitorManager)
        }
        
        Scope(state: \.progress, action: /Action.map) {
            MapCoordinatorReducer(networkMonitorManager: networkMonitorManager)
        }
        
        Scope(state: \.profile, action: /Action.profile) {
            ProfileCoordinatorReducer(networkService: networkService,
                                      networkMonitorManager: networkMonitorManager)
        }
        
        Reduce { state, action in
            
            switch action {
                
            case .tabSelected(let tab):
                state.selectedTab = tab
               
                if tab == .map {
                    
                    return .run { send in
                        
                        await send(.map(.routeAction(0, action: .map(.onAppear))))
                    }
                }
                
            case .showTabBar:
                state.tabBarIsHidden = false
                
                return .none
                
            case .hideTabBar:
                state.tabBarIsHidden = true
                
                return .none
                
            case .home(.hideTabBar):
                return .run { send in
                    await send(.hideTabBar, animation: .easeIn)
                }
                
            case .home(.showTabBar):
                return .run { send in
                    await send(.showTabBar, animation: .easeIn)
                }
            
            case .profile(.hideTabbar):
                return .run { send in
                    await send(.hideTabBar, animation: .easeIn)
                }
                
            case .profile(.showTabbar):
                return .run { send in
                    await send(.showTabBar, animation: .easeIn)
                }
                
            case .map(.hideTabbar):
                return .run { send in
                    await send(.hideTabBar, animation: .easeIn)
                }
                
            case .map(.showTabbar):
                return .run { send in
                    await send(.showTabBar, animation: .easeIn)
                }
                
            case .home(.routeAction(0, action: .main(.orderExursionTapped))):
                return .run { send in
                    await send(.showErrorModal)
                }
                
            case .additionalyTapped:
                state.isShowAdditionalModal.toggle()
                state.sizeAllFiles = STFileManager.shared.getSizeAllFiles()
                return .none
                
            case .showDeleteModal:
                state.isShowDeleteProfileModal.toggle()
                state.isShowAdditionalModal = false
                return .none
                
            case .showCacheDeleteModal:
                state.isShowCacheDeleteModal.toggle()
                state.isShowAdditionalModal = false
                return .none
            
            case .showSuccefullyDeleteCacheModal:
                state.isShowSuccefullyDeleteCacheModal.toggle()
                state.isShowAdditionalModal = false
                return .none
                
            case .deleteProfileTapped:
                state.isShowAdditionalModal = false
                return .none
                
            case .cancelDeletProfileTapped:
                state.isShowAdditionalModal = true
                state.isShowDeleteProfileModal = false
                return .none
                
            case .cancelCacheDeleteTapped:
                state.isShowAdditionalModal = true
                state.isShowCacheDeleteModal = false
                return .none
                
            case .cancelSuccefullyDeleteTapped:
                state.isShowSuccefullyDeleteCacheModal = false
                return .none
                
            case .closeAllModals:
                state.isShowAdditionalModal = false
                state.isShowDeleteProfileModal = false
                state.isShowErrorModal = false
                state.isShowCacheDeleteModal = false
                return .none
                
            case .deleteUser:
                state.isLoading = true
                
                return .run { send in
                    await send(.deleteUserResponse(deleteAccount()))
                }
                
            case .deleteUserResponse(let result):
                state.isLoading = false
                
                if result.0 == true {
                    
                    KeychainWrapper.standard.set("", forKey: "accessToken")
                    KeychainWrapper.standard.set("", forKey: "refreshToken")
                    showAuth = true
                    let _ = STFileManager.shared.cleanFileManager()
                    CoreDataManager.shared.deleteCoreData()
                    return .none
                    
                } else {
                    
                    return .run { [deleteModalIsShown = state.isShowDeleteProfileModal] send in
                        
                        if deleteModalIsShown {
                            
                            await send(.showDeleteModal)
                        }
                        
                        await send(.showErrorModal)
                    }
                }
                
            case .deleteCache:
                state.isLoading = true
                state.isSuccefullyDeletedCache = STFileManager.shared.cleanFileManager()
                CoreDataManager.shared.deleteCoreData(isOnlyWays: true)
                state.isLoading = false
                state.isShowCacheDeleteModal = false
                state.isShowSuccefullyDeleteCacheModal = true
                
                return .none
                
            case .home(.routeAction(_, action: .main(.showWarningModal))),
                 .home(.routeAction(_, action: .route(.showWarningModal))):
                
                return .run { send in
                    await send(.showErrorModal)
                }
                
            case .showErrorModal:
                state.isShowErrorModal.toggle()
                return .none
                
            case .errorHandling:
                return .run { send in
                    
                    await send(.home(.errorHandling))
                    await send(.showErrorModal)
                }
                
            case .updateDocumentType(let documentType):
                state.documentType = documentType
                
                return .run { send in
                    await send(.showDocumentView)
                }
                
            default:
                break
            }
            return .none
        }
        .dependency(\.networkService, networkService)
    }
    
    //MARK: - Network Methods
    
    func deleteAccount() async -> (Bool?, RequestError?) {
        
        let result = await networkService.deleteUser()
        
        switch result {
            
        case .success(let response):
            
            guard let statusCode = response?.statusCode else { return (false, nil) }
            
            if statusCode >= 200 && statusCode <= 299 {
                
                return (true, nil)
                
            } else {
                
                return (false, nil)
            }
            
        case .failure(let error):
            
            return (nil, error)
        }
    }
}

