//
//  CTAPIManagerValidator.h
//  CTNetworking
//
//  Created by CharlieLiao on 2017/12/13.
//  Copyright © 2017年 Charlie. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CTAPIBaseManager;

/*************************************************************************************************/
/*                                     CTAPIManagerValidator                                     */
/*************************************************************************************************/
/**
 验证器，用于验证API的返回或者调用API的参数是否正确
 使用场景：
 当我们确认一个api是否真正调用成功时，要看的不光是status，还有具体的数据内容是否为空。由于每个api中的内容对应的key都不一定一样，甚至于其数据结构也不一定一样，因此对每一个api的返回数据做判断是必要的，但又是难以组织的。
 为了解决这个问题，manager有一个自己的validator来做这些事情，一般情况下，manager的validator可以就是manager自身。
 
 1.有的时候可能多个api返回的数据内容的格式是一样的，那么他们就可以共用一个validator。
 2.有的时候api有修改，并导致了返回数据的改变。在以前要针对这个改变的数据来做验证，是需要在每一个接收api回调的地方都修改一下的。但是现在就可以只要在一个地方修改判断逻辑就可以了。
 3.有一种情况是manager调用api时使用的参数不一定是明文传递的，有可能是从某个变量或者跨越了好多层的对象中来获得参数，那么在调用api的最后一关会有一个参数验证，当参数不对时不访问api，同时自身的errorType将会变为CTAPIManagerErrorTypeParamsError。这个机制可以优化我们的app。
 */
@protocol CTAPIManagerValidator

@required
/**
 所有的callback数据都应该在这个函数里面进行检查，事实上，到了回调delegate的函数里面是不需要再额外验证返回数据是否为空的。
 因为判断逻辑都在这里做掉了。
 而且本来判断返回数据是否正确的逻辑就应该交给manager去做，不要放到回调到controller的delegate方法里面去做。
 */
- (BOOL)manager:(CTAPIBaseManager * _Nonnull)manager isCorrectWithCallBackData:(id _Nullable)data;

/**
 用户会被要求填很多参数，这些参数都有一定的规则，比如邮箱地址或是手机号码等等，我们可以在validator里判断邮箱或者电话是否符合规则，比如描述是否超过十个字。
 从而manager在调用API之前可以验证这些参数，通过manager的回调函数告知上层controller。
 避免无效的API请求。加快响应速度，也可以多个manager共用。
 所以不要以为这个params验证不重要。当调用API的参数是来自用户输入的时候，验证是很必要的。
 当调用API的参数不是来自用户输入的时候，这个方法可以写成直接返回true。
 反正哪天要真是参数错误，QA那一关肯定过不掉。不过我还是建议认真写完这个参数验证，这样能够省去将来代码维护者很多的时间。
 */
- (BOOL)manager:(CTAPIBaseManager * _Nonnull)manager isCorrectWithParamsData:(NSDictionary <NSString*,id>* _Nullable)data;

@end
