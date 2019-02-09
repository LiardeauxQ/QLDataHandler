//
//  DataBaseHandler.swift
//  QLDataHandler
//
//  Created by Quentin Liardeaux on 2/9/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import Foundation;
import FirebaseFirestore;
import Geofirestore;
import CoreLocation;
import RxSwift;
import RxCocoa;

public protocol DocumentSerializable {
    var dictionary: [String: Any]? { get };
    
    init?(id: String?, dictionary: [String: Any]?);
}

public protocol DataBaseHandler: ReactiveSwiftEventHandler
{
    func fetchDocument<T: DocumentSerializable>(document: DocumentReference,
                                                completionHandler: @escaping ((T?, Error?) -> Void));
    func fetchCollection<T: DocumentSerializable>(collection: CollectionReference,
                                                  completionHandler: @escaping (([T]?, Error?) -> Void));
    func fetchCollection<T: DocumentSerializable>(query: Query,
                                                  completionHandler: @escaping (([T]?, Error?) -> Void));
    func setListener<T: DocumentSerializable>(with query: Query,
                                              completionHandler: @escaping (([T]?, Error?) -> Void)) -> ListenerRegistration;
    func stockObjects<T: DocumentSerializable>(with querySnapshot: QuerySnapshot) -> [T]
    func stock<T: DocumentSerializable>(document: DocumentSnapshot) -> T?;
    func update<T: DocumentSerializable>(object: T, document: DocumentReference) -> Completable?;
    func update(data: [String: Any], document: DocumentReference) -> Completable;
    func update(location: CLLocation, geoFirestore: GeoFirestore, documentID: String) -> Completable;
    func set<T: DocumentSerializable>(object: T, document: DocumentReference) -> Completable?;
    func set(data: [String: Any], document: DocumentReference) -> Completable;
    func remove(document: DocumentReference) -> Completable;
}

public extension DataBaseHandler
{
    public func fetchDocument<T: DocumentSerializable>(document: DocumentReference,
                                                completionHandler: @escaping ((T?, Error?) -> Void))
    {
        var object: T?;
        
        document.getDocument { (documentSnap, error) in
            if let document = documentSnap {
                object = self.stock(document: document);
            }
            completionHandler(object, error);
        }
    }
    
    public func fetchCollection<T: DocumentSerializable>(collection: CollectionReference,
                                                  completionHandler: @escaping (([T]?, Error?) -> Void))
    {
        var objects: [T]?;
        
        collection.getDocuments { (querySnap, error) in
            if let querySnap = querySnap, error == nil {
                objects = self.stockObjects(with: querySnap);
            }
            completionHandler(objects, error);
        }
    }
    
    public func fetchCollection<T: DocumentSerializable>(query: Query,
                                                  completionHandler: @escaping (([T]?, Error?) -> Void))
    {
        var objects: [T]?;
        
        query.getDocuments { (querySnap, error) in
            if let querySnap = querySnap, error == nil {
                objects = self.stockObjects(with: querySnap);
            }
            completionHandler(objects, error);
        }
    }
    
    public func setListener<T: DocumentSerializable>(with query: Query,
                                              completionHandler: @escaping (([T]?, Error?) -> Void)) -> ListenerRegistration
    {
        var objects: [T]?;
        
        return (query.addSnapshotListener { (querySnap, error) in
            if let querySnap = querySnap, error == nil {
                objects = self.stockObjects(with: querySnap);
            }
            completionHandler(objects, error);
        });
    }
    
    public func stockObjects<T: DocumentSerializable>(with querySnapshot: QuerySnapshot) -> [T]
    {
        var objects = [T]();
        
        for document in querySnapshot.documents {
            guard let object: T = self.stock(document: document) else {
                continue;
            }
            objects.append(object);
        }
        return (objects);
    }
    
    public func stock<T: DocumentSerializable>(document: DocumentSnapshot) -> T?
    {
        return (T(id: document.documentID, dictionary: document.data()));
    }
    
    public func update<T: DocumentSerializable>(object: T, document: DocumentReference) -> Completable?
    {
        guard let data = object.dictionary else {
            return nil;
        }
        
        return update(data: data, document: document);
    }
    
    public func update(data: [String: Any], document: DocumentReference) -> Completable
    {
        return Completable.create(subscribe: { (event) -> Disposable in
            document.updateData(data) { (error) in
                self.handleCompletableEvent(event, error);
            }
            return (Disposables.create());
        });
    }
    
    public func update(location: CLLocation, geoFirestore: GeoFirestore, documentID: String) -> Completable
    {
        return Completable.create(subscribe: { (event) -> Disposable in
            geoFirestore.setLocation(location: location,
                                     forDocumentWithID: documentID) { (error) in
                                        self.handleCompletableEvent(event, error);
            }
            return Disposables.create();
        });
    }
    
    public func set<T: DocumentSerializable>(object: T, document: DocumentReference) -> Completable?
    {
        guard let data = object.dictionary else {
            return nil;
        }
        
        return set(data: data, document: document);
    }
    
    public func set(data: [String: Any], document: DocumentReference) -> Completable
    {
        return Completable.create(subscribe: { (event) -> Disposable in
            document.setData(data) { (error) in
                self.handleCompletableEvent(event, error);
            }
            return (Disposables.create());
        });
    }
    
    public func remove(document: DocumentReference) -> Completable
    {
        return Completable.create(subscribe: { (event) -> Disposable in
            document.delete { (error) in
                self.handleCompletableEvent(event, error);
            }
            return Disposables.create();
        });
    }
}
