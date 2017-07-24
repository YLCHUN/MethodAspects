//
//  MethodAspects.h
//  MethodAspects
//
//  Created by YLCHUN on 2017/7/19.
//  Copyright © 2017年 ylchun. All rights reserved.
//
//  实现逻辑思路可查阅Aspects.png原理图

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, MAOptions) {
    MAForestall = 0,            //抢先执行，仅调用，return无效
    MAIntercept = 1,            //替换执行
    MAReplenish = 2,            //追加执行，仅调用，return无效
};

//第一个参数为返回参数，第二个参数开始为入参，入参参数顺序和类型必须和selector一致,MACallSuper禁止跨线程调用
typedef void(^MACallSuper)(void*res,...);

//参数顺序和类型必须和selector一致；nil时候为移除操作，此时MAOptions无作用
//需要调用super时候，MABlock在原有的参数基础上添加一个MACallSuper（跟在最后面）
typedef id MABlock;

void methodAspect(id self, MAOptions option, SEL selector, MABlock block);

void methodUnAspect(id self, SEL selector);//移除

