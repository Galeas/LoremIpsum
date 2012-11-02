//
//  LISettingsProxy.h
//  LoremIpsum
//
//  Created by Akki on 11/2/12.
//
//

#import <Foundation/Foundation.h>

@interface LISettingsProxy : NSObject
+ (LISettingsProxy*)proxy;
- (id)valueForSetting:(NSString*)settingName;
- (void)setValue:(id)value forSettingName:(NSString*)settingName;

@property (copy) NSMutableDictionary *settings;
@end
