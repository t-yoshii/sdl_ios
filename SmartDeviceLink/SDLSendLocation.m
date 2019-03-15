//
//  SDLSendLocation.m
//  SmartDeviceLink

#import "SDLSendLocation.h"

#import "NSMutableDictionary+Store.h"
#import "SDLRPCParameterNames.h"
#import "SDLRPCFunctionNames.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SDLSendLocation

- (instancetype)init {
    self = [super initWithName:SDLRPCFunctionNameSendLocation];
    if (!self) {
        return nil;
    }

    return self;
}

- (instancetype)initWithAddress:(SDLOasisAddress *)address addressLines:(nullable NSArray<NSString *> *)addressLines locationName:(nullable NSString *)locationName locationDescription:(nullable NSString *)locationDescription phoneNumber:(nullable NSString *)phoneNumber image:(nullable SDLImage *)image deliveryMode:(nullable SDLDeliveryMode)deliveryMode timeStamp:(nullable SDLDateTime *)timeStamp {
    self = [self init];
    if (!self) { return nil; }

    self.address = address;
    self.addressLines = addressLines;
    self.locationName = locationName;
    self.locationDescription = locationDescription;
    self.phoneNumber = phoneNumber;
    self.image = image;
    self.deliveryMode = deliveryMode;
    self.timeStamp = timeStamp;

    return self;
}

- (instancetype)initWithLongitude:(double)longitude latitude:(double)latitude locationName:(nullable NSString *)locationName locationDescription:(nullable NSString *)locationDescription address:(nullable NSArray<NSString *> *)address phoneNumber:(nullable NSString *)phoneNumber image:(nullable SDLImage *)image {
    return [self initWithLongitude:longitude latitude:latitude locationName:locationName locationDescription:locationDescription displayAddressLines:address phoneNumber:phoneNumber image:image deliveryMode:nil timeStamp:nil address:nil];
}

- (instancetype)initWithLongitude:(double)longitude latitude:(double)latitude locationName:(nullable NSString *)locationName locationDescription:(nullable NSString *)locationDescription displayAddressLines:(nullable NSArray<NSString *> *)displayAddressLines phoneNumber:(nullable NSString *)phoneNumber image:(nullable SDLImage *)image deliveryMode:(nullable SDLDeliveryMode)deliveryMode timeStamp:(nullable SDLDateTime *)timeStamp address:(nullable SDLOasisAddress *)address {
    self = [self init];
    if (!self) {
        return nil;
    }

    self.longitudeDegrees = @(longitude);
    self.latitudeDegrees = @(latitude);
    self.locationName = locationName;
    self.locationDescription = locationDescription;
    self.addressLines = displayAddressLines;
    self.phoneNumber = phoneNumber;
    self.locationImage = image;
    self.deliveryMode = deliveryMode;
    self.timeStamp = timeStamp;
    self.address = address;

    return self;
}

- (void)setLongitudeDegrees:(nullable NSNumber<SDLFloat> *)longitudeDegrees {
    [parameters sdl_setObject:longitudeDegrees forName:SDLRPCParameterNameLongitudeDegrees];
}

- (nullable NSNumber<SDLFloat> *)longitudeDegrees {
    return [parameters sdl_objectForName:SDLRPCParameterNameLongitudeDegrees];
}

- (void)setLatitudeDegrees:(nullable NSNumber<SDLFloat> *)latitudeDegrees {
    [parameters sdl_setObject:latitudeDegrees forName:SDLRPCParameterNameLatitudeDegrees];
}

- (nullable NSNumber<SDLFloat> *)latitudeDegrees {
    return [parameters sdl_objectForName:SDLRPCParameterNameLatitudeDegrees];
}

- (void)setLocationName:(nullable NSString *)locationName {
    [parameters sdl_setObject:locationName forName:SDLRPCParameterNameLocationName];
}

- (nullable NSString *)locationName {
    return [parameters sdl_objectForName:SDLRPCParameterNameLocationName];
}

- (void)setAddressLines:(nullable NSArray<NSString *> *)addressLines {
    [parameters sdl_setObject:addressLines forName:SDLRPCParameterNameAddressLines];
}

- (nullable NSString *)locationDescription {
    return [parameters sdl_objectForName:SDLRPCParameterNameLocationDescription];
}

- (void)setLocationDescription:(nullable NSString *)locationDescription {
    [parameters sdl_setObject:locationDescription forName:SDLRPCParameterNameLocationDescription];
}

- (nullable NSArray<NSString *> *)addressLines {
    return [parameters sdl_objectForName:SDLRPCParameterNameAddressLines];
}

- (void)setPhoneNumber:(nullable NSString *)phoneNumber {
    [parameters sdl_setObject:phoneNumber forName:SDLRPCParameterNamePhoneNumber];
}

- (nullable NSString *)phoneNumber {
    return [parameters sdl_objectForName:SDLRPCParameterNamePhoneNumber];
}

- (void)setLocationImage:(nullable SDLImage *)locationImage {
    [parameters sdl_setObject:locationImage forName:SDLRPCParameterNameLocationImage];
}

- (nullable SDLImage *)locationImage {
    return [parameters sdl_objectForName:SDLRPCParameterNameLocationImage ofClass:SDLImage.class];
}

- (void)setDeliveryMode:(nullable SDLDeliveryMode)deliveryMode {
    [parameters sdl_setObject:deliveryMode forName:SDLRPCParameterNameDeliveryMode];
}

- (nullable SDLDeliveryMode)deliveryMode {
    return [parameters sdl_objectForName:SDLRPCParameterNameDeliveryMode];
}

- (void)setTimeStamp:(nullable SDLDateTime *)timeStamp {
    [parameters sdl_setObject:timeStamp forName:SDLRPCParameterNameTimeStamp];
}

- (nullable SDLDateTime *)timeStamp {
    return [parameters sdl_objectForName:SDLRPCParameterNameTimeStamp ofClass:SDLDateTime.class];
}

- (void)setAddress:(nullable SDLOasisAddress *)address {
    [parameters sdl_setObject:address forName:SDLRPCParameterNameAddress];
}

- (nullable SDLOasisAddress *)address {
    return [parameters sdl_objectForName:SDLRPCParameterNameAddress ofClass:SDLOasisAddress.class];
}

@end

NS_ASSUME_NONNULL_END
