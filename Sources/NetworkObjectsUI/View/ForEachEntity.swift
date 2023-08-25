//
//  EntityListView.swift
//
//
//  Created by Alsey Coleman Miller on 8/24/23.
//

#if canImport(SwiftUI)
import Foundation
import Combine
import SwiftUI
import CoreModel
import NetworkObjects

/// NetworkObjects Entity `ForEach` View
public struct ForEachEntity <Entity: NetworkEntity, Store: ObjectStore, RowContent: View, RowPlaceholder: View, ErrorView: View> : View {
    
    let data: [Entity.ID]
    
    let store: Store
    
    let cache: (Entity.ID) -> (Entity?)
    
    let row: (Entity) -> (RowContent)
    
    let placeholder: (Entity.ID) -> (RowPlaceholder)
    
    let error: (Error) -> (ErrorView)
    
    public init(
        data: [Entity.ID],
        store: Store,
        cache: @escaping (Entity.ID) -> (Entity?),
        row: @escaping (Entity) -> (RowContent),
        placeholder: @escaping (Entity.ID) -> (RowPlaceholder),
        error: @escaping (Error) -> (ErrorView)
    ) {
        self.data = data
        self.store = store
        self.cache = cache
        self.row = row
        self.placeholder = placeholder
        self.error = error
    }
    
    public var body: some View {
        ForEach(data, id: \.self) { id in
            RowView(
                id: id,
                store: store,
                cache: cache,
                row: row,
                placeholder: placeholder,
                error: error
            )
        }
    }
}

internal extension ForEachEntity {
    
    struct RowView: View {
        
        let id: Entity.ID
        
        let store: Store
        
        @State
        var state: ViewState = .loading
        
        @State
        var task: Task<Void, Never>? = nil
        
        let cache: (Entity.ID) -> (Entity?)
        
        let row: (Entity) -> (RowContent)
        
        let placeholder: (Entity.ID) -> (RowPlaceholder)
        
        let error: (Error) -> (ErrorView)
                
        var body: some View {
            ZStack {
                switch state {
                case .loading:
                    self.placeholder(id)
                case .failure(let error):
                    self.error(error)
                case .success(let value):
                    self.row(value)
                }
            }
            .onAppear {
                loadData()
            }
            .onDisappear {
                cancelTask()
            }
        }
    }
}

private extension ForEachEntity.RowView {
    
    func cancelTask() {
        task?.cancel()
        task = nil
    }
    
    func loadData() {
        let state: ViewState
        if let value = cache(id) {
            state = .success(value)
        } else if task == nil {
            // load in background
            task = Task(priority: .userInitiated) {
                await fetchData()
            }
            state = .loading
        } else {
            state = .loading
        }
        self.state = state
    }
    
    func fetchData() async {
        defer { cancelTask() }
        let state: ViewState
        do {
            let value = try await store.fetch(Entity.self, for: id)
            state = .success(value)
        }
        catch {
            state = .failure(error)
        }
        self.state = state
    }
}

internal extension ForEachEntity.RowView {
    
    enum ViewState {
        case loading
        case failure(Error)
        case success(Entity)
    }
}
#endif
