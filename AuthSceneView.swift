//
//  AuthSceneView.swift
//  travel
//
//  Created by Artem Vishniakov on 04.10.2023.
//

import SwiftUI
import ComposableArchitecture

struct AuthSceneView: View {
    
    @Environment(\.scenePhase) var scenePhase
    
    let store: StoreOf<AuthReducer>
    
    @State var isActive: Bool = false
    
    var body: some View {
        
        WithViewStore(store, observe: {$0}) { viewStore in
            
            ZStack(alignment: .bottom) {
                
                AuthBackground()
                
                Color.black.opacity(viewStore.showAuthModal ? 0.2 : 0).ignoresSafeArea()
                
                BaseBottomSheetView(show: viewStore.binding(get: \.showAuthModal,
                                                            send: .openCloseAuthModal)) {
                    
                    VStack (spacing: 0) {
                        
                        switch viewStore.authPageNumber {
                            
                        case 1: AuthRegistrationPage(store: store)
                            
                        case 2: CodeEnterPage(store: store)
                            
                        case 3: CongratulationsPage(store: store)
                            
                        default: Text("")
                        }
                        
                        PrimaryButton(disabled: viewStore.isButtonDisabled, title: viewStore.authPageNumber != 3 ? Localized.next.value : Localized.lets_go.value) {
                            
                            viewStore.send(.nextButtonTapped, animation: .easeInOut)
                        }
                        .padding(.top, 24)
                        .padding(.horizontal)
                        .padding(.bottom, (!viewStore.isRegistration || viewStore.authPageNumber == 2) ? (accessHeight < 750 ? 12 : 0) : 4)
                        .disabled(viewStore.isButtonDisabled)
                        
                        if (viewStore.authPageNumber != 3 && viewStore.authPageNumber != 1 || viewStore.isRegistration && viewStore.authPageNumber != 3) {
                            
                            SecondaryButton(title: Localized.back.value) {
                                
                                viewStore.send(.backButtonTapped, animation: .easeInOut)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, accessHeight < 750 ? 12 : 0)
                        }
                    }
                }
                
                if viewStore.isLoading {
                    
                    VStack {
                        
                        Spacer()
                        
                        LoaderAnimationView()
                        
                        Spacer()
                    }
                } 
                
                Color.black.ignoresSafeArea().opacity(viewStore.isShowNoInternetModal ? 0.3 : 0)
                
                BaseModalView(modalType: .no_internet,
                              isButtonDisabled: false,
                              additionalDescription: "",
                              showBaseModal: viewStore.binding(get: \.isShowNoInternetModal,
                                                               send: .showNoInternetModal),
                              primaryAction: {viewStore.send(.noInternetModalAction)},
                              secondaryAction: {viewStore.send(.showNoInternetModal)})
            }
            .onAppear {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        
                    viewStore.send(.onAppear)}
                }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
