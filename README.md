# MethodAspects

[![CI Status](https://img.shields.io/travis/youlianchun/MethodAspects.svg?style=flat)](https://travis-ci.org/youlianchun/MethodAspects)
[![Version](https://img.shields.io/cocoapods/v/MethodAspects.svg?style=flat)](https://cocoapods.org/pods/MethodAspects)
[![License](https://img.shields.io/cocoapods/l/MethodAspects.svg?style=flat)](https://cocoapods.org/pods/MethodAspects)
[![Platform](https://img.shields.io/cocoapods/p/MethodAspects.svg?style=flat)](https://cocoapods.org/pods/MethodAspects)

![](https://raw.githubusercontent.com/youlianchun/MethodAspects/master/MethodAspects.png)

## 简介

MethodAspects 是一个基于 [Aspects](https://github.com/steipete/Aspects) 的 iOS 方法拦截库，相比原版增加了以下功能：

- **类方法和实例方法可同时进行拦截**
- **方法拦截可根据需要调用原 super 方法**
- **无转型直接赋值**：MethodAspects 采用无转型直接赋值，而 Aspects 统一处理成 NSValue 赋值

## 特性

- 🚀 **抢先执行**：在原始方法执行前拦截
- 🔄 **替换执行**：完全替换原始方法，可选择调用 super
- ➕ **追加执行**：在原始方法执行后追加逻辑
- 🎯 **支持类方法和实例方法**：同时拦截类方法和实例方法
- 🔒 **线程安全**：使用互斥锁保证线程安全
- 📱 **iOS 兼容**：支持 iOS 8.0+

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

1. 下载源代码
2. 将 `MethodAspects/Classes` 文件夹添加到项目中
3. 链接 `objc/runtime` 和 `objc/message` 框架

## 使用方法

### 基本用法

```objc
#import <MethodAspects/MethodAspects.h>

// 拦截实例方法
[object methodAspectWithSelector:@selector(methodName) 
                          option:MAIntercept 
                           block:^(id self, id arg1, id arg2, MACallSuper callSuper) {
    // 在方法执行前执行
    NSLog(@"方法执行前");
    
    // 调用原始方法（可选）
    if (callSuper) {
        callSuper(&returnValue, arg1, arg2);
    }
    
    // 在方法执行后执行
    NSLog(@"方法执行后");
}];
```

### 拦截选项

```objc
typedef enum : int {
    MAForestall = 0,    // 抢先执行，仅调用，return无效
    MAIntercept = 1,    // 替换执行，super根据实际需求获取，return有效
    MAReplenish = 2,    // 追加执行，仅调用，return无效
} MAOptions;
```

### 类方法拦截

```objc
// 拦截类方法
[MyClass methodAspectWithSelector:@selector(classMethod) 
                           option:MAIntercept 
                            block:^(id self, id arg1, MACallSuper callSuper) {
    NSLog(@"类方法被拦截");
    
    // 调用原始类方法
    if (callSuper) {
        callSuper(&returnValue, arg1);
    }
}];
```

### 移除拦截

```objc
// 移除特定方法的拦截
[object methodUnAspectWithSelector:@selector(methodName)];

// 移除所有拦截
[object methodUnAspectWithSelector:nil];
```

### C 函数接口

```objc
// 设置拦截
methodAspect(target, MAIntercept, @selector(methodName), block);

// 移除拦截
methodUnAspect(target, @selector(methodName));
```

## 示例项目

要运行示例项目：

1. 克隆仓库
2. 在 Example 目录下运行 `pod install`
3. 打开 `MethodAspects.xcworkspace`
4. 运行项目

## 实现原理

MethodAspects 通过以下方式实现方法拦截：

1. **动态创建子类**：为每个被拦截的对象创建动态子类
2. **方法替换**：将目标方法替换为消息转发
3. **参数传递**：通过 NSInvocation 处理参数和返回值
4. **Super 调用**：提供 MACallSuper 回调支持调用父类方法

详细实现逻辑可参考以下原理图：

![MethodAspects实现原理图](https://raw.githubusercontent.com/YLCHUN/MethodAspects/refs/heads/master/MethodAspects.png)

## 要求

- iOS 8.0+
- Xcode 8.0+
- Objective-C

## 注意事项

- **MACallSuper 禁止跨线程调用**
- 参数顺序和类型必须与 selector 一致
- 需要调用 super 时，MABlock 在原有参数基础上添加一个 MACallSuper（跟在最后面）

## 许可证

MethodAspects 基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 作者

**youlianchun** - [youlianchunios@163.com](mailto:youlianchunios@163.com)

## 致谢

- 基于 [Aspects](https://github.com/steipete/Aspects) 项目
- 感谢所有贡献者的支持

