//
//  DXProxy.h
//
//  Created by 徐 东 on 15/1/21.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, UnregisteredSelectorPolicy) {
    UnregisteredSelectorPolicyForward,
    UnregisteredSelectorPolicySilent,
    UnregisteredSelectorPolicyRaisingExeption,
};

#define ProxySelector(sel) NSStringFromSelector(@selector(sel))

typedef id(^DXProxyBeforeHandler)(NSInvocation *invocation);
typedef id(^DXProxyInsteadHandler)(NSInvocation *invocation,id deforeHandleResult);
typedef void(^DXProxyAfterHandler)(NSInvocation *invocation,id afterHandleResult,id insteadHandleResult);
typedef UnregisteredSelectorPolicy(^DXProxyPolicyBlock)(SEL selector);

@interface DXProxy : NSProxy

@property (copy,nonatomic) DXProxyBeforeHandler beforeHandler;
@property (copy,nonatomic) DXProxyInsteadHandler insteadHandler;
@property (copy,nonatomic) DXProxyAfterHandler afterHandler;
@property (copy,nonatomic) DXProxyPolicyBlock policyBlock;//default is UnregisteredSelectorPolicyForward

- (instancetype)initWithObject:(id)object selectors:(NSArray *)selectors;

- (void)setBeforeHandler:(DXProxyBeforeHandler)beforeHandler;
- (void)setInsteadHandler:(DXProxyInsteadHandler)insteadHandler;
- (void)setAfterHandler:(DXProxyAfterHandler)afterHandler;

@end

@interface NSObject (DXProxy)

- (instancetype)dx_proxyForSelectors:(NSArray *)selectors beforeHandler:(DXProxyBeforeHandler)beforeHandler insteadHandler:(DXProxyInsteadHandler)insteadHandler afterHandler:(DXProxyAfterHandler)afterHandler policyBlock:(DXProxyPolicyBlock)policyBlock;

@end
