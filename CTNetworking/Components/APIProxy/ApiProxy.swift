//
//  ApiProxy.swift
//  CTNetworking
//
//  Created by 廖朝瑞 on 2018/4/19.
//  Copyright © 2018年 Charlie. All rights reserved.
//

import Foundation
import AFNetworking

typealias AXCallback = (_ response: CTURLResponse) -> Void
typealias DecryptContent = (_ content: Data) -> Data


class ApiProxy {
    
    static let shared = ApiProxy()
    
    private lazy var dispatchTable = [Int:URLSessionDataTask]()
    private lazy var session: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()
        session.requestSerializer = AFHTTPRequestSerializer()
        session.responseSerializer = AFHTTPResponseSerializer()
        return session
    }()
    
    private init() { }
    
    func callApi(request: URLRequest, params: ParamsType?, decrypt: DecryptContent?, success: AXCallback?, fail: AXCallback?) -> Int {
        
        var requestID: Int = -1
        let task = session.dataTask(with: request, uploadProgress: nil, downloadProgress: nil) { (response, responseObject, error) in
            // 队列移除
            self.dispatchTable.removeValue(forKey: requestID)
            
            let responseData: Data?
            if let data = responseObject as? Data {
                // 没错误 和 实现解密block 就进行解密
                responseData = (error == nil && decrypt != nil) ?
                    decrypt!(data):data
            } else {
                responseData = nil
            }
            
            // 输出Log
            CTLogger.logDebugInfo(with: response as! HTTPURLResponse, data: responseData, request: request, error: error)
            
            // 检查http response是否成立。
            // 构建Response
            let ctResponse = CTURLResponse(requestId: requestID, request: request, responseData: responseData, error: error)!
            ctResponse.requestParams = params
            if error != nil {
                fail?(ctResponse)
            } else {
                success?(ctResponse)
            }
        }
        requestID = task.taskIdentifier
        dispatchTable[requestID] = task
        task.resume()
        return requestID
    }
    
    func cancelRequest(_ id: Int) {
        if let task = dispatchTable[id] {
            task.cancel()
            dispatchTable.removeValue(forKey: id)
        }
    }
    
    func cancelRequest(_ ids: [Int]) {
        for reqid in ids {
            self.cancelRequest(reqid)
        }
    }
}

