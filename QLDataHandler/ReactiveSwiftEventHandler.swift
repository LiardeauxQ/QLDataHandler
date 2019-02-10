//
//  ReactiveSwiftEventHandler.swift
//  QLDataHandler
//
//  Created by Quentin Liardeaux on 2/9/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import RxSwift;
import RxCocoa;

public protocol ReactiveSwiftEventHandler {
    func handleSingleEvent<T>(_ event: ((SingleEvent<T>) -> Void),
                              _ value: T?,
                              _ error: Error?);
    func handleCompletableEvent(_ event: ((CompletableEvent) -> Void),
                                _ error: Error?);
    func convertObservableEventToCompletableEvent<T>(observableEvent: Event<T>,
                                                     completableEvent: ((CompletableEvent) -> Void));
    func convertObservableEventToSingleEvent<T>(observableEvent: Event<T>,
                                                singleEvent: ((SingleEvent<T>) -> Void));
}

public extension ReactiveSwiftEventHandler
{
    open func handleCompletableEvent(_ event: ((CompletableEvent) -> Void),
                                       _ error: Error?)
    {
        if let error = error {
            event(.error(error));
            return;
        }
        event(.completed);
    }
    
    open func handleSingleEvent<T>(_ event: ((SingleEvent<T>) -> Void),
                                     _ value: T?,
                                     _ error: Error?)
    {
        if let error = error {
            event(.error(error));
            return;
        }
        if let value = value {
            event(.success(value));
        } else {
            event(.error(NSError(domain: "Nothing to send", code: 0)));
        }
    }
    
    open func convertObservableEventToCompletableEvent<T>(observableEvent: Event<T>,
                                                            completableEvent: ((CompletableEvent) -> Void))
    {
        switch observableEvent {
        case .next( _):
            completableEvent(.completed);
        case .error(let error):
            completableEvent(.error(error));
        case .completed:
            completableEvent(.completed);
        }
    }
    
    open func convertObservableEventToSingleEvent<T>(observableEvent: Event<T>,
                                                       singleEvent: ((SingleEvent<T>) -> Void))
    {
        switch observableEvent {
        case .next(let element):
            singleEvent(.success(element));
        case .error(let error):
            singleEvent(.error(error));
        default:
            break;
        }
    }
}
