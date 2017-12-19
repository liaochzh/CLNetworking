//
//  CTAPIManagerDataReformer.h
//  CTNetworking
//
//  Created by CharlieLiao on 2017/12/13.
//  Copyright © 2017年 Charlie. All rights reserved.
//

#import <Foundation/Foundation.h>

/*************************************************************************************************/
/*                               CTAPIManagerCallbackDataReformer                                */
/*************************************************************************************************/
//负责重新组装API数据的对象
/*
 重组数据的场景：
 1.当不同的controller需要从同一个manager里面获得数据来进行不同的操作的时候，他们需要的数据格式可能不一样，比如列表页controller可能需要array型的数据，而单页只需要dictionary型的数据，那么此时就由 需要使用数据的controller 提供 reformer，让manager根据reformer中的方法进行重组来获得数据。
 
 2.我们现有的代码里面，有些时候是将manager返回的数据map成一个对象，有的时候并没有这么做，甚至将来可能有其它的数据使用者对数据结构有新的要求。那么，在上层将数据传递到下层接收者的时候，上层会很困惑应该传递什么类型的数据。
 以前为了解决这个问题，是让下层接收者接收id类型的数据，然后自己判断如何使用。在数据类型比较少的时候还能够做判断，当数据类型多的时候，判断就会变得很困难。
 现在如果要解决这个问题，则需要由下层接收者提供一个reformer交给上层，上层拿了下层提供的reformer来重组数据，并把重组的数据交给下层，就能保证提供的数据正是是下层需要的。
 
 3.reformer在运行层面上的本质是业务逻辑的插入，这个业务逻辑是由需求方提供的，由controller负责把业务逻辑提交给manager执行。
 
 举个例子：
 app需要在房源单页里面获得电话号码，这个电话号码的生成是有一个业务逻辑的：
 1.先要判断提供这个房源的人是不是经纪人，如果是经济人，则输出经纪人的电话号码
 2.如果是个人，则要判断个人是否公开电话号码，
 （1）如果公开，则显示个人的电话号码
 （2）如果不公开，则显示400电话号码。
 
 由此可见，这个业务逻辑的使用场景相对频繁，且相对复杂，而且比较通用（在所有租房要显示电话号码的地方都要用到）。那么如何使用reformer来实现这样的功能呢？
 
 接下来先说一个规范：controller负责调用manager获得数据，然后交给view去渲染。
 
 如果以前要实现这样的功能，有三种方法可以实现：
 1.controller调用manager获得数据，然后解析出电话号码，交给view。
 2.controller把manager的数据全部拿过来，交给view去解析出电话号码并显示。这是我们目前比较常用的做法。
 3.manager中直接做好获得电话号码的逻辑，由controller从manager中获取电话号码然后交给view。我们的项目中也有些地方是这么做的。
 
 第1种做法不评价，相信大家都明白缺点在哪儿。评价一下第2种做法：
 第一点，api的数据是有可能变的。当一个项目里面很多地方都需要显示电话号码的时候（收藏、列表、单页），各个view里面内联了同一套逻辑，当API出现修改时，需要到每个view的地方都要修改一次，会变的比较麻烦。
 第二点，由于逻辑被硬编码进入view，在其它的view需要电话号码的时候，只能从已经做好逻辑的view里面复制代码，这样就产生了代码冗余，降低了项目的可维护性。
 
 评价一下第3种做法：
 第3种做法是相对规范的，也解决了上述第2种方法中的两个问题。mananger中包含了业务逻辑，然后由controller去调用获得数据交给view。其中也有一些地方美中不足：
 1.manager会变得非常庞大，因为它集成了很多业务逻辑，修改和维护的时候定位代码会变得困难。
 2.如果不同的manager中有相同的业务逻辑，虽然各个manager提供的基础数据不同，但都是做一个相同的业务逻辑，这部分也会产生一定的冗余。对于产品来说，新房租房二手房的业务逻辑都是一样的，修改的时候可能都会有修改，那么我们就要分别到二手房，新房，租房的manager中修改同一套业务逻辑，这就是一种冗余。
 3.有的时候manager处理业务逻辑的时候也需要外部提供一些辅助数据，为了满足这样的需求，manager中会设置个别属性来提供冗余数据，但由于manager提供不止一种业务逻辑的处理，随之而来的就是manager提供业务逻辑所需要的辅助属性就会非常多，会降低代码的可维护性。
 
 于是我引入了reformer。reformer只能由需求方提供。具体可以参看后面的代码样例。
 reformer在这个角度上讲是业务逻辑的一种封装，它能够根据不同的manager以及不同的数据来处理业务逻辑，由于reformer是个相对独立的对象，它可以被每一个业务需求方引入，然后交给controller，controller拿着这个reformer去调用manager，并且把返回的数据交给view。这么做的好处就是把view和manager做了解耦，同时同样的业务逻辑只会在同一个reformer里面，这样就不会产生代码冗余，代码定位和代码维护都会非常方便。它是这么解决上述第3种方法的三个弊端的：
 1.由于业务逻辑被独立抽出来形成了一个对象，因此manager不会变得非常庞大，mananger只需要做好向API请求数据就可以了。在维护一个业务逻辑时，直接去维护这个业务逻辑对应得reformer就可以了，定位代码和维护代码都变得非常容易且独立。
 2.因为reformer能够区分不同的manager，在做相同的业务逻辑的时候可以在reformer内部调用不同的方法。注意，reformer其实也是一个对象。由于业务逻辑被独立出来，不同业务逻辑之间的耦合度被降低，同时相同业务逻辑之间的代码重用性也得到了提高，降低了代码冗余度。
 3.因为reformer自己本身也是一个对象，且一个reformer对应一个业务逻辑，那么就能够保证一个业务逻辑中所需要的辅助数据都能够在reformer中找到并设置。增强了代码的可维护性。
 
 下面描述一下使用reformer的流程。
 1.controller获得view的reformer
 2.controller给获得的reformer提供一些辅助数据，如果没有辅助数据，这一步可以省略。
 3.controller调用manager的 fetchDataWithReformer: 获得数据
 4.将数据交给view
 
 如何使用reformer：
 ContentRefomer *reformer = self.topView.contentReformer;    //reformer是属于需求方的，此时的需求方是topView
 reformer.contentParams = self.filter.params;                //如果不需要controller提供辅助数据的话，这一步可以不要。
 id data = [self.manager fetchDataWithReformer:reformer];
 [self.topView configWithData:data];
 
 */
@class CTAPIBaseManager;
@protocol CTAPIManagerDataReformer <NSObject>
@required
/*
 比如同样的一个获取电话号码的逻辑，二手房，新房，租房调用的API不同，所以它们的manager和data都会不同。
 即便如此，同一类业务逻辑（都是获取电话号码）还是应该写到一个reformer里面去的。这样后人定位业务逻辑相关代码的时候就非常方便了。
 
 代码样例：
 - (id)manager:(CTAPIBaseManager *)manager reformData:(NSDictionary *)data
 {
 if ([manager isKindOfClass:[xinfangManager class]]) {
 return [self xinfangPhoneNumberWithData:data];      //这是调用了派生后reformer子类自己实现的函数，别忘了reformer自己也是一个对象呀。
 //reformer也可以有自己的属性，当进行业务逻辑需要一些外部的辅助数据的时候，
 //外部使用者可以在使用reformer之前给reformer设置好属性，使得进行业务逻辑时，
 //reformer能够用得上必需的辅助数据。
 }
 
 if ([manager isKindOfClass:[zufangManager class]]) {
 return [self zufangPhoneNumberWithData:data];
 }
 
 if ([manager isKindOfClass:[ershoufangManager class]]) {
 return [self ershoufangPhoneNumberWithData:data];
 }
 }
 */
- (id _Nullable)manager:(CTAPIBaseManager * _Nonnull)manager reformData:(id _Nullable)data;
@end
