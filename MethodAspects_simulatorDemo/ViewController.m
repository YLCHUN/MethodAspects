//
//  ViewController.m
//  MethodAspects_simulatorDemo
//
//  Created by YLCHUN on 2017/7/19.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "ViewController.h"
#import <MethodAspects/MethodAspects.h>
#import "Aspects.h"

@interface ObjectS : NSObject
-(CGRect)function1:(CGPoint)size;
-(int)function2:(NSString*)str p:(int)i;
+(NSString*)classFunction:(NSString*)str;
@end
@implementation ObjectS
-(CGRect)function1:(CGPoint)size{
    return CGRectMake(0, 0, 100, 100);
}
-(int)function2:(NSString*)str p:(int)i {
    NSLog(@"super %s %@", __func__, str);
    return 1;
}
+(NSString*)classFunction:(NSString*)str {
    return @"class_classFunction";
}
@end
@interface Object : ObjectS
-(void)function:(NSString*)str;
-(CGRect)function1:(CGPoint)size;
-(int)function2:(NSString*)str p:(int)i;
+(NSString*)classFunction:(NSString*)str;
@end
@implementation Object
-(void)function:(NSString*)str {
    NSLog(@"self %s %@", __func__, str);
}
-(CGRect)function1:(CGPoint)size {
    return CGRectMake(0, 0, 0, 100);
}
-(int)function2:(NSString*)str p:(int)i {
    NSLog(@"self %s %@", __func__, str);
    return [super function2:str p:i];
}
+(NSString*)classFunction:(NSString*)str {
    NSLog(@"self %s %@", __func__, str);
    return [super classFunction:str];
}
@end


@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    [self methodAspectTest];
//    [self aspectTest];
}

-(void)methodAspectTest {
    Object *obj = [[Object alloc] init];
    methodAspect(obj, MAReplenish, @selector(function:), ^(NSString* str){
        NSLog(@"function:");
    });
    [obj function:@"f1"];
    
    methodAspect(obj, MAIntercept, @selector(function2:p:), ^int(NSString*str, int i, MACallSuper callSuper){
        int si;
        callSuper(&si, str, i);
        si++;
        return si;//2
    });
    int i = [obj function2:@"11"p:3];
    
    methodAspect([Object class], MAIntercept, @selector(classFunction:), ^NSString*(NSString*str, MACallSuper callSuper){
        NSString* str_super;
        callSuper(&str_super, str);
        return [str_super stringByAppendingString:@"_ma"];
    });
    NSString *str = [Object classFunction:@"cc"];
    
    methodAspect(obj, MAIntercept, @selector(function1:), ^CGRect(CGPoint point, MACallSuper callSuper){
        CGRect sRect;
        callSuper(&sRect,point);
        sRect.origin = point;
        return sRect;
    });
    
    CGRect rect = [obj function1:CGPointMake(100, 10)];
    
    
    NSLog(@"%d %@  {%f,%f, %f,%f}", i, str,rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

-(void)aspectTest {
    Object *obj = [[Object alloc] init];
    [obj aspect_hookSelector:@selector(function:) withOptions:AspectPositionAfter usingBlock:^(NSString*str){
        NSLog(@"function:");
    } error:NULL];
    [obj function:@"1"];
    
    [obj aspect_hookSelector:@selector(function2:p:) withOptions:AspectPositionInstead usingBlock:^int(NSString*str, int i){
        return 1;//super ？？？
    } error:NULL];
    int i = [obj function2:@"11"p:3];
    

    [[Object class] aspect_hookSelector:@selector(classFunction:) withOptions:AspectPositionInstead usingBlock:^NSString*(NSString*str){//super ？？？
        NSLog(@"Object");
        return @"classFunction:";
    } error:NULL];
    NSString *str = [Object classFunction:@"cc"];
    NSLog(@"%d %@", i, str);

}
@end
