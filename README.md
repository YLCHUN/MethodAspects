# MethodAspects

[![CI Status](https://img.shields.io/travis/youlianchun/MethodAspects.svg?style=flat)](https://travis-ci.org/youlianchun/MethodAspects)
[![Version](https://img.shields.io/cocoapods/v/MethodAspects.svg?style=flat)](https://cocoapods.org/pods/MethodAspects)
[![License](https://img.shields.io/cocoapods/l/MethodAspects.svg?style=flat)](https://cocoapods.org/pods/MethodAspects)
[![Platform](https://img.shields.io/cocoapods/p/MethodAspects.svg?style=flat)](https://cocoapods.org/pods/MethodAspects)

![](https://raw.githubusercontent.com/youlianchun/MethodAspects/master/MethodAspects.png)

## 简介

MethodAspects 是一个强大的 iOS 方法拦截库，基于 [Aspects](https://github.com/steipete/Aspects) 进行扩展。它允许你在运行时拦截和修改 Objective-C 方法的执行，支持类方法和实例方法的拦截，并且可以根据需要调用原始的 super 方法。

## 主要特性

- 🚀 **双重拦截支持**: 同时支持类方法和实例方法的拦截
- 🔄 **灵活的执行控制**: 支持抢先执行、替换执行、追加执行三种模式
- 📞 **Super 方法调用**: 可以根据需要调用原始的 super 方法
- ⚡ **高性能**: 采用无转型直接赋值，性能优于 Aspects
- 🛡️ **线程安全**: 使用互斥锁保证线程安全
- 📱 **iOS 兼容**: 支持 iOS 8.0+

## 与 Aspects 的区别

| 特性 | MethodAspects | Aspects |
|------|---------------|---------|
| 类方法拦截 | ✅ 支持 | ❌ 不支持 |
| 实例方法拦截 | ✅ 支持 | ✅ 支持 |
| Super 方法调用 | ✅ 支持 | ❌ 不支持 |
| 参数处理 | 无转型直接赋值 | NSValue 统一处理 |
| 执行模式 | 3种模式 | 2种模式 |

## 安装

### CocoaPods

在 Podfile 中添加：

```ruby
pod 'MethodAspects'
```

然后运行：

```bash
pod install
```

### 手动安装

1. 下载 `MethodAspects.h` 和 `MethodAspects.m` 文件
2. 将文件添加到你的 Xcode 项目中
3. 确保链接了 `objc` 运行时库

## 使用方法

### 基本用法

```objc
#import "MethodAspects.h"

// 拦截实例方法
[object methodAspectWithSelector:@selector(someMethod) 
                          option:MAIntercept 
                           block:^(id result, id param1, id param2, MACallSuper callSuper) {
    // 在方法执行前做一些事情
    NSLog(@"方法执行前");
    
    // 调用原始方法
    if (callSuper) {
        callSuper(&result, param1, param2);
    }
    
    // 在方法执行后做一些事情
    NSLog(@"方法执行后");
    
    return result;
}];

// 拦截类方法
[SomeClass methodAspectWithSelector:@selector(classMethod) 
                              option:MAForestall 
                               block:^(id result, id param) {
    NSLog(@"类方法被拦截");
    return result;
}];
```

### 三种执行模式

#### 1. MAForestall (抢先执行)
在原始方法执行前执行，返回值无效

```objc
[object methodAspectWithSelector:@selector(method) 
                          option:MAForestall 
                           block:^(id result, id param) {
    NSLog(@"抢先执行");
    return result; // 返回值无效
}];
```

#### 2. MAIntercept (替换执行)
完全替换原始方法，可以调用 super 方法，返回值有效

```objc
[object methodAspectWithSelector:@selector(method) 
                          option:MAIntercept 
                           block:^(id result, id param, MACallSuper callSuper) {
    NSLog(@"替换执行");
    
    // 调用 super 方法
    if (callSuper) {
        callSuper(&result, param);
    }
    
    return result; // 返回值有效
}];
```

#### 3. MAReplenish (追加执行)
在原始方法执行后执行，返回值无效

```objc
[object methodAspectWithSelector:@selector(method) 
                          option:MAReplenish 
                           block:^(id result, id param) {
    NSLog(@"追加执行");
    return result; // 返回值无效
}];
```

### 移除拦截

```objc
// 移除特定方法的拦截
[object methodUnAspectWithSelector:@selector(someMethod)];

// 移除所有方法的拦截
[object methodUnAspectWithSelector:nil];
```

### 使用 C 函数接口

```objc
// 设置拦截
methodAspect(object, MAIntercept, @selector(method), block);

// 移除拦截
methodUnAspect(object, @selector(method));
```

## API 文档

### 枚举类型

```objc
typedef enum : int {
    MAForestall = 0,    // 抢先执行
    MAIntercept = 1,    // 替换执行
    MAReplenish = 2,    // 追加执行
} MAOptions;
```

### 回调块类型

```objc
// Super 方法调用回调
typedef void(^MACallSuper)(void*res,...);

// 方法拦截回调
typedef id MABlock;
```

### 主要函数

```objc
// 设置方法拦截
void methodAspect(id target, MAOptions option, SEL selector, MABlock block);

// 移除方法拦截
void methodUnAspect(id target, SEL selector);
```

### NSObject 分类方法

```objc
@interface NSObject (MethodAspect)

// 实例方法拦截
- (void)methodAspectWithSelector:(SEL)anSelector 
                          option:(MAOptions)option 
                           block:(MABlock)block;

// 类方法拦截
+ (void)methodAspectWithSelector:(SEL)anSelector 
                          option:(MAOptions)option 
                           block:(MABlock)block;

// 移除实例方法拦截
- (void)methodUnAspectWithSelector:(SEL)anSelector;

// 移除类方法拦截
+ (void)methodUnAspectWithSelector:(SEL)anSelector;

@end
```

## 注意事项

1. **线程安全**: `MACallSuper` 禁止跨线程调用
2. **参数顺序**: 回调块中的参数顺序和类型必须与 selector 一致
3. **Super 调用**: 只有在 `MAIntercept` 模式下才能调用 super 方法
4. **内存管理**: 拦截器会自动管理内存，无需手动释放

## 许可证

MethodAspects 基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 作者

youlianchun - youlianchunios@163.com

## 致谢

- 基于 [Aspects](https://github.com/steipete/Aspects) 项目进行扩展
- 感谢开源社区的支持和贡献


