//
//  SearchDataEngine.swift
//  QLDataHandler
//
//  Created by Quentin Liardeaux on 2/9/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved
//

import Foundation;
import RxSwift;
import RxCocoa;
import InstantSearchClient;

public protocol SearchDataEngineDelegate: class {
    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?);
}

public protocol DataRecordConformity {
    init(json: [String: Any]);
}

open class SearchDataEngine<Record: DataRecordConformity>
{
    public var records = [Record]();
    public var loadedPages: UInt = 0;
    public var nbPages: UInt = 0;
    public var totalCount: Int = 0;
    private var currentQuery: Query;
    private var currentIndex: Index;
    private var isFetchingData: Bool = false;
    private var disposeBag = DisposeBag();
    open weak var delegate: SearchDataEngineDelegate? {
        didSet {
            startSearching();
        }
    };
    
    public init(index: Index, query: InstantSearchClient.Query)
    {
        self.currentQuery = query;
        self.currentIndex = index;
    }
    
    open func startSearching()
    {
        self.currentIndex.search(self.currentQuery) { [weak self] (data, error) in
            guard let self = self,
                error == nil,
                let hits = data!["hits"] as? [[String: AnyObject]],
                let nbPages = data!["nbPages"] as? UInt else {
                    return
            }
            var tmp = [Record]();
            
            self.nbPages = nbPages;
            self.totalCount = data!["nbHits"] as? Int ?? 0;
            if (self.totalCount == 0) {
                self.confirmDataFetching(at: nil);
                return;
            }
            for hit in hits {
                tmp.append(Record(json: hit));
            }
            self.records = tmp;
            self.confirmDataFetching(at: nil);
        }
    }
    
    open func loadMore()
    {
        if (self.loadedPages + 1 >= self.nbPages)
            || (self.isFetchingData == true) {
            return;
        }
        let query = Query(copy: self.currentQuery);
        
        query.page = self.loadedPages + 1;
        searchMoreData(with: self.currentIndex, and: query);
    }
    
    private func searchMoreData(with index: Index, and query: InstantSearchClient.Query)
    {
        self.isFetchingData = true;
        index.search(query) { [weak self] (data, error) in
            guard let self = self,
                error == nil,
                let hits = data!["hits"] as? [[String: AnyObject]] else {
                    return
            }
            var tmp = [Record]();
            
            self.loadedPages = query.page ?? 0;
            for hit in hits {
                tmp.append(Record(json: hit));
            }
            self.records.append(contentsOf: tmp);
            self.confirmDataFetching(at: self.calculateIndexPathsToReload(from: tmp));
        }
    }
    
    private func confirmDataFetching(at indexPaths: [IndexPath]?)
    {
        self.isFetchingData = false;
        self.delegate?.onFetchCompleted(with: indexPaths);
    }
    
    private func calculateIndexPathsToReload(from newRecords: [Record]) -> [IndexPath]
    {
        let startIndex: Int = self.records.count - newRecords.count;
        let endIndex: Int = startIndex + newRecords.count;
        
        return ((startIndex ..< endIndex).map({ IndexPath(item: $0, section: 0) }));
    }
}
