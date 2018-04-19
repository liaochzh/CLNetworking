//
//  APIBaseManager.swift
//  CTNetworking
//
//  Created by 廖朝瑞 on 2018/4/19.
//  Copyright © 2018年 Charlie. All rights reserved.
//

import Foundation
import AFNetworking

public typealias ParamsType = [String:AnyObject]

enum APIManagerErrorType {
    case success
    case paramsError
    case timeout
    case noNetWork
    case noContent
}

public protocol APIManagerCallBack : class {
    func callAPIDidSuccess(_ manager: APIBaseManager, data: Data)
    func callAPIDidFailed(_ manager: APIBaseManager, errorMsg: String)
}

public protocol APIManagerParamSource : class {
    func paramsForApi(_ manager: APIBaseManager) -> APIParameter?
}

public protocol APIManagerValidator : class {
    
    /**
     用户会被要求填很多参数，这些参数都有一定的规则，比如邮箱地址或是手机号码等等，我们可以在validator里判断邮箱或者电话是否符合规则，比如描述是否超过十个字。
     从而manager在调用API之前可以验证这些参数，通过manager的回调函数告知上层controller。
     避免无效的API请求。加快响应速度，也可以多个manager共用。
     所以不要以为这个params验证不重要。当调用API的参数是来自用户输入的时候，验证是很必要的。
     当调用API的参数不是来自用户输入的时候，这个方法可以写成直接返回true。
     反正哪天要真是参数错误，QA那一关肯定过不掉。不过我还是建议认真写完这个参数验证，这样能够省去将来代码维护者很多的时间。
     */
    func isCorrectWithParams(_ params: ParamsType?, manager: APIBaseManager) -> Bool
    
    /**
     所有的callback数据都应该在这个函数里面进行检查，事实上，到了回调delegate的函数里面是不需要再额外验证返回数据是否为空的。
     因为判断逻辑都在这里做掉了。
     而且本来判断返回数据是否正确的逻辑就应该交给manager去做，不要放到回调到controller的delegate方法里面去做。
     */
    func isCorrectWithCallBack(_ data: Any?, manager: APIBaseManager) -> Bool
}

@objc public protocol RequestGenerator: class {
    
    func generateRequest(service: CTService, params: ParamsType?, methodName: String, type: APIRequestType) -> URLRequest
    
}

@objc public enum APIRequestType: UInt {
    case get
    case post
    case put
    case delete
}

@objc public protocol APIManagerConfiguration : class {
    
    var methodName: String { get }
    var requestType: APIRequestType { get }
    var service: CTService { get }
    var requestGenerator: RequestGenerator { get }
    
    //    /**
    //     调用API之前额外添加一些参数,但不应该在这个函数里面修改已有的参数。
    //     所以这里返回的参数字典还是会被后面的验证函数去验证的。
    //
    //     假设同一个翻页Manager，ManagerA的paramSource提供page_size=15参数，ManagerB的paramSource提供page_size=2参数
    //     如果在这个函数里面将page_size改成10，那么最终调用API的时候，page_size就变成10了。然而外面却觉察不到这一点，因此这个函数要慎用。
    //
    //     这个函数的适用场景：
    //     当两类数据走的是同一个API时，为了避免不必要的判断，我们将这一个API当作两个API来处理。
    //     那么在传递参数要求不同的返回时，可以在这里给返回参数指定类型。
    //     */
    //    @objc optional func reformParams(_ params: AnyObject?) -> AnyObject?
    
    /**
     是否需要加载本地数据
     */
    @objc optional var shouldLoadFromNative: Bool { get }
    /**
     是否加载缓存数据（加载缓存将不再请求服务器）
     */
    @objc optional var shouldCache: Bool { get }
    
    /**
     缓存超时间隔(默认300秒)
     */
    @objc optional var cacheOutdatedInterval: TimeInterval { get }
    
    /**
     解密Response内容
     */
    @objc optional var decryptResponse: ((_ content: Data) -> Data) { get }
    
    /**
     解密本地缓存
     */
    @objc optional func decryptCache(_ data: Data) -> Data
    
    /**
     加密本地缓存(确保数据存储的安全性)
     */
    @objc optional func encryptCache(_ data: Data) -> Data
}

public protocol APIManagerInterceptor: class {
    
    func shouldCallAPI(params: ParamsType?, manager: APIBaseManager) -> Bool
    
    func beforePerformSuccess(_ response: CTURLResponse, manager: APIBaseManager) -> Bool
    func afterPerformSuccess(_ response: CTURLResponse, manager: APIBaseManager)
    
    func beforePerformFail(_ response: CTURLResponse?, manager: APIBaseManager) -> Bool
    func afterPerformFail(_ response: CTURLResponse?, manager: APIBaseManager)
}

public class APIParameter: Encodable {
    
}

open class APIBaseManager {
    
    open weak var paramSource: APIManagerParamSource?
    open weak var validator: APIManagerValidator?
    open weak var callBack: APIManagerCallBack?
    open weak var configuration: APIManagerConfiguration?
    open weak var interceptor: APIManagerInterceptor?
    
    public var isReachable: Bool {
        let manager = AFNetworkReachabilityManager.shared()
        return manager.isReachable || manager.networkReachabilityStatus == .unknown
    }
    
    public var isLoading: Bool {
        return requestIdList.count > 0
    }
    
    private lazy var cache = CTCache()
    private lazy var requestIdList = [Int]()
    
    public init() { }
    
    deinit {
        cancelAllRequests()
    }
    
    /// 尽量使用loadData这个方法,这个方法会通过param source来获得参数，这使得参数的生成逻辑位于controller中的固定位置
    @discardableResult
    public func loadData() -> Int {
        return loadData(paramSource?.paramsForApi(self))
    }
    
    @discardableResult
    public func loadData(_ params: APIParameter?) -> Int {
        
        // api 配置清单
        guard let config = configuration else {
            return kNilRequestID
        }
        
        // 用了比较笨的方法对象转成了字典
        let paramDict: ParamsType?
        if params != nil {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(params!) {
                paramDict = (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)) as? ParamsType
            } else {
                paramDict = nil
            }
        } else {
            paramDict = nil
        }
        
        // 拦截器
        guard interceptor?.shouldCallAPI(params: paramDict, manager: self) ?? true else {
            return kNilRequestID
        }
        
        // 验证器 验证参数是否正确
        guard validator?.isCorrectWithParams(paramDict, manager: self) ?? true  else {
            failedOnCallingAPI(nil, errorType: .paramsError)
            return kNilRequestID
        }
        
        // 读取缓存数据
        if config.shouldCache ?? false {
            if loadCache(paramDict) {
                return kNilRequestID
            }
        }
        
        // 本地缓存
        if config.shouldLoadFromNative ?? false {
            loadDataFromNative(paramDict)
        }
        
        // 实际的网络请求
        guard isReachable else {
            failedOnCallingAPI(nil, errorType: .noNetWork)
            return kNilRequestID
        }
        
        // 构建请求
        let request = config.requestGenerator.generateRequest(service: config.service, params: paramDict, methodName: config.methodName, type: config.requestType)
        
        //
        CTLogger.logDebugInfo(with: request, apiName: config.methodName, service: config.service, requestParams: paramDict, httpMethod: request.httpMethod)
        
        //
        let requestId = ApiProxy.shared.callApi(request: request, params: paramDict, decrypt: config.decryptResponse, success: { [weak self] (response) in
            self?.successedOnCallingAPI(response)
            
            }, fail: { [weak self] (response) in
                let type: APIManagerErrorType = response.status == .errorTimeout ? .timeout : .noNetWork
                self?.failedOnCallingAPI(response, errorType: type)
        })
        requestIdList.append(requestId)
        
        return requestId
    }
    
    public func cancelAllRequests() {
        ApiProxy.shared.cancelRequest(requestIdList)
        requestIdList.removeAll()
    }
    
    public func cancelRequest(id: Int) {
        ApiProxy.shared.cancelRequest(id)
        if let index = requestIdList.index(of: id) {
            requestIdList.remove(at: index)
        }
    }
    
    // MARK: -
    private func successedOnCallingAPI(_ response: CTURLResponse) {
        
        let responseData = response.responseData ?? Data()
        // 验证器 验证回调是否正确
        let object = try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments)
        guard validator?.isCorrectWithCallBack(object, manager: self) ?? true  else {
            failedOnCallingAPI(response, errorType: .noContent)
            return
        }
        
        if !response.isCache { // 不是缓存数据
            // 移除请求id
            if let index = requestIdList.index(of: response.requestId) {
                requestIdList.remove(at: index)
            }
            
            if let config = configuration {
                let shouldCache = config.shouldCache ?? false
                let shouldNative = config.shouldLoadFromNative ?? false
                
                if shouldCache || shouldNative { // 需要缓存
                    let cacheData = config.encryptCache?(responseData) ?? responseData
                    
                    cache.save(with: cacheData, serviceIdentifier: config.service.serviceIdentifier, methodName: config.methodName, requestParams: response.requestParams, inMemoryOnly: !shouldNative)
                }
            }
        }
        
        if interceptor?.beforePerformSuccess(response, manager: self) ?? true {
            callBack?.callAPIDidSuccess(self, data: responseData)
        }
        interceptor?.afterPerformSuccess(response, manager: self)
    }
    
    private func failedOnCallingAPI(_ response: CTURLResponse?, errorType: APIManagerErrorType) {
        // 先移除请求id
        if let requestId = response?.requestId, requestId != kNilRequestID {
            if let index = requestIdList.index(of: requestId) {
                requestIdList.remove(at: index)
            }
        }
        
        // 错误的信息
        // 响应数据是缓存 报了没数据错误，但还有请求未完成，就不处理了
        if errorType != .noContent || !isLoading || !(response?.isCache ?? false) {
            
            if interceptor?.beforePerformFail(response, manager: self) ?? true {
                callBack?.callAPIDidFailed(self, errorMsg: "")
            }
            interceptor?.afterPerformFail(response, manager: self)
        }
    }
    
    // MARK: - private methods
    
    private func loadCache(_ params: ParamsType?) -> Bool {
        guard let config = configuration else {
            return false
        }
        
        let service = config.service
        let serviceId = service.serviceIdentifier
        let methodName = config.methodName
        
        // 默认300秒，查找缓存
        let timeOutInterval = config.cacheOutdatedInterval ?? 300
        guard let result = cache.fetchCachedData(withServiceIdentifier: serviceId, methodName: methodName, requestParams: params, outdatedInterval: timeOutInterval) else {
            return false
        }
        // 解密缓存数据
        let cacheData = config.decryptCache?(result) ?? result
        
        DispatchQueue.main.async { [weak self] in
            let response = CTURLResponse(data: cacheData)!
            response.requestParams = params as! [String : NSCoding]
            
            CTLogger.logDebugInfo(withCachedResponse: response, methodName: methodName, serviceIdentifier: service)
            self?.successedOnCallingAPI(response)
        }
        return false
    }
    
    private func loadDataFromNative(_ params: ParamsType?) {
        guard let config = configuration else {
            return
        }
        
        let serviceId = config.service.serviceIdentifier
        let methodName = config.methodName
        
        // 本地数据，最多就是一个月，查找缓存
        guard let result = cache.fetchCachedData(withServiceIdentifier: serviceId, methodName: methodName, requestParams: params, outdatedInterval: 2592000) else {
            return
        }
        // 解密缓存数据
        let cacheData = config.decryptCache?(result) ?? result
        
        DispatchQueue.main.async { [weak self] in
            let response = CTURLResponse(data: cacheData)!
            response.requestParams = params as! [String : NSCoding]
            
            self?.successedOnCallingAPI(response)
        }
    }
}


