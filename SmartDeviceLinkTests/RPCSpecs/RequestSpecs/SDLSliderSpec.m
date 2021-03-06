//
//  SDLSliderSpec.m
//  SmartDeviceLink


#import <Foundation/Foundation.h>

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

#import "SDLSlider.h"
#import "SDLNames.h"

QuickSpecBegin(SDLSliderSpec)

describe(@"Getter/Setter Tests", ^ {
    it(@"Should set and get correctly", ^ {
        SDLSlider* testRequest = [[SDLSlider alloc] init];
        
        testRequest.numTicks = @2;
        testRequest.position = @1;
        testRequest.sliderHeader = @"Head";
        testRequest.sliderFooter = [@[@"LeftFoot", @"RightFoot"] mutableCopy];
        testRequest.timeout = @2000;
        
        expect(testRequest.numTicks).to(equal(@2));
        expect(testRequest.position).to(equal(@1));
        expect(testRequest.sliderHeader).to(equal(@"Head"));
        expect(testRequest.sliderFooter).to(equal([@[@"LeftFoot", @"RightFoot"] mutableCopy]));
        expect(testRequest.timeout).to(equal(@2000));
    });
    
    it(@"Should get correctly when initialized", ^ {
        NSMutableDictionary<NSString *, id> *dict = [@{SDLNameRequest:
                                                           @{SDLNameParameters:
                                                                 @{SDLNameNumberTicks:@2,
                                                                   SDLNamePosition:@1,
                                                                   SDLNameSliderHeader:@"Head",
                                                                   SDLNameSliderFooter:[@[@"LeftFoot", @"RightFoot"] mutableCopy],
                                                                   SDLNameTimeout:@2000},
                                                             SDLNameOperationName:SDLNameSlider}} mutableCopy];
        SDLSlider* testRequest = [[SDLSlider alloc] initWithDictionary:dict];
        
        expect(testRequest.numTicks).to(equal(@2));
        expect(testRequest.position).to(equal(@1));
        expect(testRequest.sliderHeader).to(equal(@"Head"));
        expect(testRequest.sliderFooter).to(equal([@[@"LeftFoot", @"RightFoot"] mutableCopy]));
        expect(testRequest.timeout).to(equal(@2000));
    });
    
    it(@"Should return nil if not set", ^ {
        SDLSlider* testRequest = [[SDLSlider alloc] init];
        
        expect(testRequest.numTicks).to(beNil());
        expect(testRequest.position).to(beNil());
        expect(testRequest.sliderHeader).to(beNil());
        expect(testRequest.sliderFooter).to(beNil());
        expect(testRequest.timeout).to(beNil());
    });
});

QuickSpecEnd
