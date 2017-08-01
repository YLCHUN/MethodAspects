//
//  MethodAspects.h
//  MethodAspects
//
//  Created by YLCHUN on 2017/7/19.
//  Copyright © 2017年 ylchun. All rights reserved.
//
//  MethodAspects: https://github.com/youlianchun/MethodAspects_Demo
//  Aspects: https://github.com/steipete/Aspects
//
//  相比Aspects增加两点功能：类方法和实例方法可同时进行拦截，方法拦截可根据需要调用原super方法
//  主要不同的一点是MethodAspects和Aspects在参数赋值的处理上，MethodAspects采用无转型直接赋值，Aspects统一处理成NSValue赋值
//  MethodAspects实现逻辑思路可查阅MethodAspects.png原理图

#import <Foundation/Foundation.h>

#pragma mark - MethodAspect

typedef enum : int {
    MAForestall = 0,            //抢先执行，仅调用，return无效
    MAIntercept = 1,            //替换执行，super根据实际需求获取，return有效
    MAReplenish = 2,            //追加执行，仅调用，return无效
} MAOptions;

/**
 第一个参数为返回参数，第二个参数开始为入参，入参参数顺序和类型必须和selector一致，MACallSuper禁止跨线程调用
 */
typedef void(^MACallSuper)(void*res,...);

/**
 参数存在则顺序和类型必须和selector一致
 需要调用super时候，MABlock在原有的参数基础上添加一个MACallSuper（跟在最后面）
 */
typedef id MABlock;

/**
 设置拦截

 @param target 目标（类或实例对象）
 @param option 操作方式
 @param selector 目标方法
 @param block 回调
 */
extern void methodAspect(id target, MAOptions option, SEL selector, MABlock block);

/**
 移除拦截

 @param target 目标（类或实例对象）
 @param selector 目标方法，nil为全部
 */
extern void methodUnAspect(id target, SEL selector);



#pragma mark - 
#pragma mark - NSObject+MethodAspect

#define FOUNDATION_IMPORT_METHODASPECT void ___importMethodAspect();\
__attribute__((used)) static void importMethodAspect () {\
___importMethodAspect();\
}

FOUNDATION_IMPORT_METHODASPECT

@interface NSObject (MethodAspect)

/**
 设置拦截

 @param anSelector 目标方法
 @param option 操作方式
 @param block 回调
 */
-(void)methodAspectWithSelector:(SEL)anSelector option:(MAOptions)option block:(MABlock)block;
+(void)methodAspectWithSelector:(SEL)anSelector option:(MAOptions)option block:(MABlock)block;

/**
 移除拦截

 @param anSelector 目标方法
 */
-(void)methodUnAspectWithSelector:(SEL)anSelector;
+(void)methodUnAspectWithSelector:(SEL)anSelector;

@end



