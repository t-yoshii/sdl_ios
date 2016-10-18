//
//  SDLOnButtonPressSpec.m
//  SmartDeviceLink


#import <Foundation/Foundation.h>

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

#import "SDLButtonName.h"
#import "SDLButtonPressMode.h"
#import "SDLOnButtonPress.h"
#import "SDLNames.h"


QuickSpecBegin(SDLOnButtonPressSpec)

describe(@"Getter/Setter Tests", ^ {
    it(@"Should set and get correctly", ^ {
        SDLOnButtonPress* testNotification = [[SDLOnButtonPress alloc] init];
        
        testNotification.buttonName = [SDLButtonName CUSTOM_BUTTON];
        testNotification.buttonPressMode = [SDLButtonPressMode LONG];
        testNotification.customButtonID = @5642;
        
        expect(testNotification.buttonName).to(equal([SDLButtonName CUSTOM_BUTTON]));
        expect(testNotification.buttonPressMode).to(equal([SDLButtonPressMode LONG]));
        expect(testNotification.customButtonID).to(equal(@5642));
    });
    
    it(@"Should get correctly when initialized", ^ {
        NSMutableDictionary<NSString *, id> *dict = [@{SDLNameNotification:
                                                           @{SDLNameParameters:
                                                                 @{SDLNameButtonName:[SDLButtonName CUSTOM_BUTTON],
                                                                   SDLNameButtonPressMode:[SDLButtonPressMode LONG],
                                                                   SDLNameCustomButtonId:@5642},
                                                             SDLNameOperationName:SDLNameOnButtonPress}} mutableCopy];
        SDLOnButtonPress* testNotification = [[SDLOnButtonPress alloc] initWithDictionary:dict];
        
        expect(testNotification.buttonName).to(equal([SDLButtonName CUSTOM_BUTTON]));
        expect(testNotification.buttonPressMode).to(equal([SDLButtonPressMode LONG]));
        expect(testNotification.customButtonID).to(equal(@5642));
    });
    
    it(@"Should return nil if not set", ^ {
        SDLOnButtonPress* testNotification = [[SDLOnButtonPress alloc] init];
        
        expect(testNotification.buttonName).to(beNil());
        expect(testNotification.buttonPressMode).to(beNil());
        expect(testNotification.customButtonID).to(beNil());
    });
});

QuickSpecEnd
