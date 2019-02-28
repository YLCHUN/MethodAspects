//
//  MethodAspects.m
//  MethodAspects
//
//  Created by YLCHUN on 2017/7/19.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "MethodAspects.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <pthread.h>

typedef struct _MAHandlerBlock {
    __unused Class isa;
    int flags;
    __unused int reserved;
    void (__unused *invoke)(struct _MAHandlerBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        const char *signature;
        const char *layout;
    } *descriptor;
} *MAHandlerBlockRef;

static NSInvocation* ma_getInvocationForBlock(id block) {
    MAHandlerBlockRef layout = (__bridge void *)block;
    if (!(layout->flags & (1 << 30))) {
        return nil;
    }
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    if (layout->flags & (1 << 25)) {
        desc += 2 * sizeof(void *);
    }
    if (!desc) {
        return nil;
    }
    const char *types = (*(const char **)desc);
    NSMethodSignature *signature= [NSMethodSignature signatureWithObjCTypes:types];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = block;
    return invocation;
}

static void ma_argumentCopy(NSInvocation *invocationFrom, NSInvocation *invocationTo){
    if (invocationFrom && invocationTo) {
        NSInteger count_from = invocationFrom.methodSignature.numberOfArguments - 2;
        NSInteger count_to = invocationTo.methodSignature.numberOfArguments - 1;
        for (NSInteger i = 0; i < count_from && i < count_to; i++) {
            NSInteger indexFrom = i+2;
            static void *argument = NULL;
            [invocationFrom getArgument:&argument atIndex:indexFrom];
            NSInteger indexTo = i+1;
            [invocationTo setArgument:&argument atIndex:indexTo];
            argument = NULL;
        }
    }
}

static void ma_returnCopy(NSInvocation *invocationFrom, NSInvocation *invocationTo){
    if (invocationFrom.methodSignature.methodReturnLength>0 && invocationTo.methodSignature.methodReturnLength>0) {
        static void *returnValue = NULL;
        [invocationFrom getReturnValue:&returnValue];
        [invocationTo setReturnValue:&returnValue];
        returnValue = NULL;
    }
}

#pragma mark -
static BOOL isClass(id obj) {
    if (object_isClass(obj)) {
        return YES;
    }
    return [obj respondsToSelector:@selector(alloc)];
}

static SEL ma_MABlockDictSelector(id self) {
    SEL sel = sel_registerName(isClass(self)?"ma_selectorMABlockDict_class":"ma_selectorMABlockDict_instance");
    return sel;
}

static NSMutableDictionary* ma_getMABlockDict(id self) {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, ma_MABlockDictSelector(self));
    return dict;
};

static void ma_setMABlockDict(id self, NSMutableDictionary*dict) {
    objc_setAssociatedObject(self, ma_MABlockDictSelector(self), dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
};

#define MABlock(SEL) ma_getSelectorMABlockDict(self, SEL)[@"MIBlockKey"]
#define MAOption(SEL) ma_getSelectorMABlockDict(self, SEL)[@"kMAOptions"]
static NSMutableDictionary<NSString*, id>* ma_getSelectorMABlockDict(id self, __nonnull SEL sel) {
    NSMutableDictionary *dict = ma_getMABlockDict(self);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        ma_setMABlockDict(self, dict);
    }
    NSString *selKey = NSStringFromSelector(sel);
    NSMutableDictionary *selBlockDict = dict[selKey];
    if (!selBlockDict) {
        selBlockDict = [NSMutableDictionary dictionary];
        dict[selKey] = selBlockDict;
    }
    return selBlockDict;
}

static void ma_cleSelectorMABlockDict(id self, __nonnull SEL sel) {
    NSString *selKey = NSStringFromSelector(sel);
    NSMutableDictionary *dict = ma_getMABlockDict(self);
    dict[selKey] = nil;
}

#define sel_maSub(SEL) sel_maSel(SEL, "maSub_")//superClass selfClass subClass 说明：subClass里指向selfClass的方法
#define sel_maSup(SEL) sel_maSel(SEL, "maSup_")//superClass selfClass subClass 说明：subClass里指向superClass的方法
static SEL sel_maSel(SEL selector, char *prefix) {
    char selName[100] = "";
    const char *selectorName = sel_getName(selector);
    strcpy(selName, prefix);
    strcat(selName, selectorName);
    SEL sel = sel_registerName(selName);
    return sel;
}

static Class ma_subClass(id self, BOOL initIfNil, void(^block)(Class selfClass, Class subClass)) {
    const char *selfclass = object_getClassName(self);
    char *postfix = isClass(self)?"_maSub_A":"_maSub_a";
    Class subClass;
    Class selfClass;
    if(strstr(selfclass, postfix)) {
        subClass = objc_getClass(selfclass);
        selfClass = class_getSuperclass(subClass);
    }else {
        char subclass[100] = "";
        strcpy(subclass, selfclass);
        strcat(subclass, postfix);
        subClass = objc_getClass(subclass);
        selfClass = object_getClass(self);
        if (subClass == nil && initIfNil) {
            subClass = objc_allocateClassPair(selfClass, subclass, 0);
            objc_registerClassPair(subClass);
        }
    }
    if (block) {
        block(selfClass, subClass);
    }
    return subClass;
}

static void ma_unForwardInvocation(id self) {
    ma_setMABlockDict(self, nil);
    ma_subClass(self, NO, ^(__unsafe_unretained Class selfClass, __unsafe_unretained Class subClass) {
        Method method_ma_forwardInvocation = class_getInstanceMethod(subClass, sel_registerName("ma_forwardInvocation:"));
        if (method_ma_forwardInvocation) {
            Method method_forwardInvocation = class_getInstanceMethod(selfClass, @selector(forwardInvocation:));
            IMP im_forwardInvocation = method_getImplementation(method_ma_forwardInvocation);
            class_replaceMethod(subClass, @selector(forwardInvocation:), im_forwardInvocation, method_getTypeEncoding(method_forwardInvocation));
        }
        object_setClass(self, selfClass);
    });
}


static Class _forwarding(id self) {
    Class subClass = ma_subClass(self, YES, ^(__unsafe_unretained Class selfClass, __unsafe_unretained Class subClass) {
        BOOL isAClass = isClass(self);
        SEL sel_forwardInvocation = sel_registerName("ma_forwardInvocation:");
        Method method_forwardInvocation = class_getInstanceMethod(subClass, @selector(forwardInvocation:));
        const char *encode_forwardInvocation = method_getTypeEncoding(method_forwardInvocation);
        IMP imp_forwardInvocation = imp_implementationWithBlock(^(id self, NSInvocation *anInvocation) {
            SEL selector = anInvocation.selector;
            
            id maBlock = MABlock(selector);
            MAOptions option = (MAOptions)[MAOption(selector) integerValue];
            NSInvocation *maInvocation = ma_getInvocationForBlock(maBlock);
            
            if (option == MAForestall) {//抢先执行
                ma_argumentCopy(anInvocation, maInvocation);
                [maInvocation invoke];
            }
            
            if (option == MAIntercept) {//替换执行 执行到super(创建一个sel_super指向父类的sel,然后修改invoke的sel执行invole)
                Class superClass = class_getSuperclass(selfClass);
                MACallSuper superBlock;//__unsafe_unretained
                if ([superClass instancesRespondToSelector:selector]) {
                    SEL sel_sup = sel_maSup(selector);//获取super的方法
                    Method method = isAClass?class_getClassMethod(superClass, sel_sup):class_getInstanceMethod(superClass, sel_sup);
                    if (method == NULL) {//superSelector不存在时候进行注册
                        method = class_getInstanceMethod(superClass, selector);
                        const char *encode = method_getTypeEncoding(method);
                        IMP imp = method_getImplementation(method);
                        class_addMethod(subClass, sel_sup, imp, encode);
                    }
                    NSMethodSignature *signature_sup = [self methodSignatureForSelector:selector];
                    NSInvocation *invocation_sup = [NSInvocation invocationWithMethodSignature:signature_sup];
                    invocation_sup.selector = sel_sup;
                    invocation_sup.target = self;
                    NSUInteger count = invocation_sup.methodSignature.numberOfArguments-2;
                    superBlock = ^(void*res,...){
                        va_list args;
                        void *arg;
                        va_start(args, res);
                        for (int i = 0; i<count; i++) {
                            arg = va_arg(args, void *);
                            NSUInteger index = i+2;
                            [invocation_sup setArgument:arg atIndex:index];
                        }
                        va_end(args);
                        [invocation_sup invoke];
                        [invocation_sup getReturnValue:res];
                    };
                }
                
                ma_argumentCopy(anInvocation, maInvocation);
                BOOL needCallSuper = maInvocation.methodSignature.numberOfArguments-1>anInvocation.methodSignature.numberOfArguments-2;
                if (superBlock && needCallSuper) {//存在super且需要调用super
                    [maInvocation setArgument:&superBlock atIndex:maInvocation.methodSignature.numberOfArguments-1];
                }
                [maInvocation invoke];
                ma_returnCopy(maInvocation, anInvocation);//拦截返回值赋给原来的返回值
            }else{//抢先 或者 追加时候正常执行原本方法
                SEL sel_sub = sel_maSub(selector);
                anInvocation.selector = sel_sub;
                if ([subClass instancesRespondToSelector:sel_sub]) {
                    [anInvocation invoke];
                }else{
                    ((void(*)(id, SEL, NSInvocation *))objc_msgSend)(self, sel_forwardInvocation, anInvocation);
                }
            }
            
            if (option == MAReplenish) {//追加执行
                ma_argumentCopy(anInvocation, maInvocation);
                [maInvocation invoke];
            }
        });
        BOOL b = class_addMethod(subClass, @selector(forwardInvocation:), imp_forwardInvocation, encode_forwardInvocation);
        if (b) {
            class_replaceMethod(subClass, sel_forwardInvocation, method_getImplementation(method_forwardInvocation), encode_forwardInvocation);
        }else{
            //添加失败
        }
        
        if (!isAClass) {//类的class返回值不变，不需要修改，修改后会导致实例的-[NSObject isKindOf:]方法返回错误结果
            //修改subClass 的class IMP，返回superClass
            Method method_class = class_getInstanceMethod(subClass, @selector(class));
            IMP imp_class = imp_implementationWithBlock(^Class(id self) {
                return selfClass;
            });
            const char *encode_class = method_getTypeEncoding(method_class);
            class_replaceMethod(subClass, @selector(class), imp_class, encode_class);
        }
    });
    object_setClass(self, subClass);
    return subClass;
}

static BOOL ma_isMsgForwardIMP(IMP imp) {
    return imp == _objc_msgForward
#if !defined(__arm64__)
    || imp == (IMP)_objc_msgForward_stret
#endif
    ;
}

static IMP ma_getMsgForwardIMP(const char *types) {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    @try {
        BOOL methodReturnsStructValue = types[0] == _C_STRUCT_B;
        if (methodReturnsStructValue) {
            NSUInteger valueSize = 0;
            NSGetSizeAndAlignment(types, &valueSize, NULL);
            if (valueSize == 1 || valueSize == 2 || valueSize == 4 || valueSize == 8) {
                methodReturnsStructValue = NO;
            }
        }
        if (methodReturnsStructValue) {
            msgForwardIMP = (IMP)_objc_msgForward_stret;
        }
    } @catch (__unused NSException *e) {}
#endif
    return msgForwardIMP;
}

static void ma_unMsgForwardSelector(Class subClass, id self, SEL selector) {
    SEL sel = sel_maSub(selector);
    Method method = class_getInstanceMethod(subClass, sel);
    IMP imp = method_getImplementation(method);
    if (imp && !ma_isMsgForwardIMP(imp)) {
        const char *encode = method_getTypeEncoding(method);
        class_replaceMethod(subClass, selector, imp, encode);
    }
}

//让subClass 的 selector 直接通过消息转发方式执行（调用 -[NSObject forwardInvocation:]）
//返回原IMP对应的新selector
static SEL ma_msgForwardSelector(Class subClass, id self, SEL selector) {
    Method method = class_getInstanceMethod(object_getClass(self), selector);
    IMP imp = method_getImplementation(method);
    SEL sel = sel_maSub(selector);
    if (!ma_isMsgForwardIMP(imp)) {
        const char *encode = method_getTypeEncoding(method);
        if (![subClass instancesRespondToSelector:sel]) {
            class_addMethod(subClass, sel, method_getImplementation(method), encode);
        }
        class_replaceMethod(subClass, selector, ma_getMsgForwardIMP(encode), encode);
    }
    return sel;
}

////删除selector对应的IMP（修改为转发IMP）
//static BOOL class_delMethodIMP(Class cls, SEL name, const char *types){
//    IMP imp = ma_getMsgForwardIMP(types);
//    BOOL b = class_replaceMethod(cls, name, imp, types);
//    return b;
//}

static void ma_locked(dispatch_block_t block) {
    static pthread_mutex_t ma_lock = PTHREAD_MUTEX_INITIALIZER;
    pthread_mutex_lock(&ma_lock);
    block();
    pthread_mutex_unlock(&ma_lock);
}

void methodAspect(id self, MAOptions option, SEL selector, MABlock block) {
    NSCParameterAssert(self);
    NSCParameterAssert(selector);
    if (![block isKindOfClass:objc_getClass("NSBlock")]) {
        return;
    }
    ma_locked(^{
        Class superClass = class_getSuperclass(object_getClass(self));
        if ([superClass instancesRespondToSelector:selector]) {
            MABlock(selector) = block;
            MAOption(selector) = @(option);
            Class subClass = _forwarding(self);
            ma_msgForwardSelector(subClass, self, selector);
        }
    });
}

static void _methodUnAspect(id self, SEL selector) {
    ma_subClass(self, NO, ^(__unsafe_unretained Class selfClass, __unsafe_unretained Class subClass) {
        ma_unMsgForwardSelector(subClass, self, selector);
        if (MABlock(selector) == nil) {
            ma_cleSelectorMABlockDict(self, selector);
        }
        NSDictionary *dict = ma_getMABlockDict(self);
        if (dict.allKeys.count == 0) {
            ma_unForwardInvocation(self);
        }
    });
}

void methodUnAspect(id self, SEL selector) {
    NSCParameterAssert(self);
    ma_locked(^{
        if (selector) {
            _methodUnAspect(self, selector);
        }else {
            NSMutableDictionary *dict = ma_getMABlockDict(self);
            for (NSString* selName in [dict allKeys]) {
                SEL sel = NSSelectorFromString(selName);
                if (sel) {
                    _methodUnAspect(self, sel);
                }
            }
        }
    });
}


#pragma mark -
#pragma mark - NSObject+MethodAspect
void ___importMethodAspect() {}

@implementation NSObject (MethodAspect)

-(void)methodAspectWithSelector:(SEL)anSelector option:(MAOptions)option block:(MABlock)block {
    methodAspect(self, option, anSelector, block);
}

+(void)methodAspectWithSelector:(SEL)anSelector option:(MAOptions)option block:(MABlock)block {
    methodAspect(self, option, anSelector, block);
}

-(void)methodUnAspectWithSelector:(SEL)anSelector {
    methodUnAspect(self, anSelector);
}

+(void)methodUnAspectWithSelector:(SEL)anSelector {
    methodUnAspect(self, anSelector);
}

@end

