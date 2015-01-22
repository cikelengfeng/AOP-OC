//
//  DXProxy.m
//
//  Created by 徐 东 on 15/1/21.
//
//

#import "DXProxy.h"

@interface DXProxy ()

@property (strong,nonatomic) id concreteObject;
@property (strong,nonatomic) NSMutableArray *selectors;

@end

@implementation DXProxy

- (id)initWithObject:(id)object selectors:(NSArray *)selectors
{
    if (!object) {
        return nil;
    }
    if (self) {
        _concreteObject = object;
        _selectors = [NSMutableArray arrayWithArray:selectors];
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL selector = invocation.selector;
    BOOL registered = [self.selectors containsObject:NSStringFromSelector(selector)];
    UnregisteredSelectorPolicy policy = self.policyBlock ? self.policyBlock(selector) : UnregisteredSelectorPolicyForward;
    if (!registered) {
        switch (policy) {
            case UnregisteredSelectorPolicySilent:
                NSLog(@"invocation %@ has been cancelled silently",NSStringFromSelector(selector));
                return;
            case UnregisteredSelectorPolicyRaisingExeption:
                [super forwardInvocation:invocation];
                return;
            case UnregisteredSelectorPolicyForward:
                break;
            default:
                return;
        }
    }
    
    // set target first
    [invocation setTarget:self.concreteObject];
    if (!registered) {
        //policy must be UnregisteredSelectorPolicyForward now,we should invoke this simply
        [invocation invoke];
    }else {
    
        //build a mirror invocation object,only responds to several selectors for security reason
        NSInvocation *mirror = nil;
        if ((self.beforeHandler || self.afterHandler)) {
            mirror = [invocation dx_proxyForSelectors:@[ProxySelector(methodSignature),ProxySelector(selector),ProxySelector(target)] beforeHandler:nil insteadHandler:nil afterHandler:nil policyBlock:^UnregisteredSelectorPolicy(SEL selector) {
                return UnregisteredSelectorPolicySilent;
            }];
        }
        
        id beforeHandlerResult = nil;
        if (self.beforeHandler) {
            beforeHandlerResult = self.beforeHandler(mirror);
        }
        
        id insteadHandleResult = nil;
        if (self.insteadHandler) {
            insteadHandleResult = self.insteadHandler(invocation,beforeHandlerResult);
        }else {
            [invocation invoke];
        }
        
        
        if (self.afterHandler) {
            [((DXProxy *)mirror).selectors addObject:ProxySelector(getReturnValue:)];
            self.afterHandler(mirror,beforeHandlerResult,insteadHandleResult);
        }
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [self.concreteObject methodSignatureForSelector:sel];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.concreteObject respondsToSelector:aSelector];
}


@end

@implementation NSObject (DXProxy)

- (instancetype)dx_proxyForSelectors:(NSArray *)selectors beforeHandler:(DXProxyBeforeHandler)beforeHandler insteadHandler:(DXProxyInsteadHandler)insteadHandler afterHandler:(DXProxyAfterHandler)afterHandler policyBlock:(DXProxyPolicyBlock)policyBlock
{
    DXProxy *proxy = [[DXProxy alloc]initWithObject:self selectors:selectors];
    if (!proxy) {
        return nil;
    }
    proxy.beforeHandler = beforeHandler;
    proxy.insteadHandler = insteadHandler;
    proxy.afterHandler = afterHandler;
    proxy.policyBlock = policyBlock;
    return (NSObject *)proxy;
}

@end

