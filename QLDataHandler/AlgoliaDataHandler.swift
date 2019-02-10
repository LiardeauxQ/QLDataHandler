//
//  AlgoliaDataHandler.swift
//  QLDataHandler
//
//  Created by Quentin Liardeaux on 2/9/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import Foundation;
import RxSwift;
import RxCocoa;
import InstantSearchClient;

public protocol AlgoliaSerializable {
    associatedtype T;
    
    func createAlgoliaObject<T>(previousValue: T?, additionalInfo: [String: Any]?) -> [String: Any]?;
}

open class AlgoliaDataHandler: ReactiveSwiftEventHandler
{
    private var _client: Client;
    public var client: Client {
        get {
            return (self._client);
        }
    }
    private var index: Index;
    
    public init(appID: String, appKey: String, indexName: String)
    {
        self._client = Client(appID: appID, apiKey: appKey);
        self.index = self._client.index(withName: indexName);
    }
    
    open func push(object: [String: Any]) -> Completable
    {
        return Completable.create(subscribe: { (event) -> Disposable in
            self.index.addObject(object) { [weak self] (data, error) in
                self?.handleCompletableEvent(event, error);
            };
            return (Disposables.create());
        });
    }
    
    open func update(object: [String: Any]) -> Completable?
    {
        guard let id = object["objectID"] as? String else {
            return nil;
        }
        
        return Completable.create(subscribe: { (event) -> Disposable in
            self.index.partialUpdateObject(object, withID: id,
                                           createIfNotExists: true)
            { [weak self] (data, error) in
                self?.handleCompletableEvent(event, error);
            };
            return (Disposables.create());
        });
    }
    
    open func update(objects: [[String: Any]]) -> Completable?
    {
        return Completable.create(subscribe: { (event) -> Disposable in
            self.index.partialUpdateObjects(
                objects, createIfNotExists: true,
                completionHandler:
                { [weak self] (data, error) in
                    self?.handleCompletableEvent(event, error);
            });
            return (Disposables.create());
        });
    }
    
    open func delete(ids: [String]) -> Completable
    {
        return Completable.create(subscribe: { (event) -> Disposable in
            self.index.deleteObjects(withIDs: ids) { [weak self] (data, error) in
                self?.handleCompletableEvent(event, error);
            };
            return (Disposables.create());
        });
    }
    
    open func delete(id: String) -> Completable
    {
        return self.delete(ids: [id]);
    }
}
