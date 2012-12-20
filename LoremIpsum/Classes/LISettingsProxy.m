//
//  LISettingsProxy.m
//  LoremIpsum
//
//  Created by Akki on 11/2/12.
//
//

#import "LISettingsProxy.h"

static NSUserDefaultsController *defaultsController;

@implementation LISettingsProxy

+ (void)initialize
{
    [self proxy];
}

+ (LISettingsProxy *)proxy
{
    static LISettingsProxy *controller = nil;
    static dispatch_once_t predicate;
    dispatch_once( &predicate, ^{
        controller = [[LISettingsProxy alloc] init];
        defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    } );
    return controller;
}

- (void)setSettings:(NSMutableDictionary *)settings
{
    if ([defaultsController initialValues])
        [defaultsController setInitialValues:nil];
    [defaultsController setInitialValues:settings];
}


- (NSMutableDictionary *)settings
{
    return [[defaultsController initialValues] mutableCopy];
}

- (id)valueForSetting:(NSString *)settingName
{
    NSString *pref = @"values";
    NSString *path = [pref stringByAppendingPathExtension:settingName];
    
    return [defaultsController valueForKeyPath:path];
}

- (void)setValue:(id)value forSettingName:(NSString *)settingName
{
    NSString *pref = @"values";
    NSString *path = [pref stringByAppendingPathExtension:settingName];
    
    if (![[defaultsController valueForKeyPath:path] isEqualTo:value])
        [defaultsController setValue:nil forKeyPath:path];
    
    [defaultsController setValue:value forKeyPath:path];
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    NSString *pref = @"values";
    NSString *path = [pref stringByAppendingPathExtension:keyPath];
    [defaultsController addObserver:observer forKeyPath:path options:options context:context];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    NSString *pref = @"values";
    NSString *path = [pref stringByAppendingPathExtension:keyPath];
    [defaultsController removeObserver:observer forKeyPath:path];
}
@end
