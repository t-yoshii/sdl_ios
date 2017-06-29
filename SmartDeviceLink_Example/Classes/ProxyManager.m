//
//  ProxyManager.m
//  SmartDeviceLink-iOS

#import "ProxyManager.h"
#import "Preferences.h"

#import "SmartDeviceLink.h"

NSString *const SDLAppName = @"SDL Example App";
NSString *const SDLShortAppName = @"SDL Example";
NSString *const VRCommandName = @"S D L Example";
NSString *const SDLAppId = @"9999";
NSString *const PointingSoftButtonArtworkName = @"PointingSoftButtonIcon";
NSString *const MainGraphicArtworkName = @"MainArtwork";

NS_ASSUME_NONNULL_BEGIN

@interface ProxyManager () <SDLManagerDelegate>

@end

@implementation ProxyManager

#pragma mark - Initialization

+ (instancetype)sharedManager {
    static ProxyManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ProxyManager alloc] init];
    });

    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _state = ProxyStateStopped;
    _firstTimeState = SDLHMIFirstStateNone;
    _initialShowState = SDLHMIInitialShowStateNone;
    _vehicleDataSubscribed = NO;
    _ShouldRestartOnDisconnect = NO;
    [self sdl_addRPCObservers];

    return self;
}

- (void)startIAP {
    [self sdlex_updateProxyState:ProxyStateSearchingForConnection];
    // Check for previous instance of sdlManager
    if (self.sdlManager) { return; }
    SDLLifecycleConfiguration *lifecycleConfig = [self.class setLifecycleConfigurationPropertiesOnConfiguration:[SDLLifecycleConfiguration defaultConfigurationWithAppName:SDLAppName appId:SDLAppId]];

    // Assume this is production and disable logging
    lifecycleConfig.logFlags = SDLLogOutputFile;
    BOOL type = [Preferences sharedPreferences].appType;
    if (type){
        lifecycleConfig.appType = SDLAppHMIType.MEDIA;
    }else{
        lifecycleConfig.appType = SDLAppHMIType.DEFAULT;
    }

    SDLConfiguration *config = [SDLConfiguration configurationWithLifecycle:lifecycleConfig lockScreen:[SDLLockScreenConfiguration enabledConfiguration]];
    self.sdlManager = [[SDLManager alloc] initWithConfiguration:config delegate:self];

    [self startManager];
}

- (void)startTCP {
    [self sdlex_updateProxyState:ProxyStateSearchingForConnection];
    // Check for previous instance of sdlManager
    if (self.sdlManager) { return; }
    SDLLifecycleConfiguration *lifecycleConfig = [self.class setLifecycleConfigurationPropertiesOnConfiguration:[SDLLifecycleConfiguration debugConfigurationWithAppName:SDLAppName appId:SDLAppId ipAddress:[Preferences sharedPreferences].ipAddress port:[Preferences sharedPreferences].port]];
    SDLConfiguration *config = [SDLConfiguration configurationWithLifecycle:lifecycleConfig lockScreen:[SDLLockScreenConfiguration enabledConfiguration]];

    BOOL type = [Preferences sharedPreferences].appType;
    if (type){
        lifecycleConfig.appType = SDLAppHMIType.MEDIA;
    }else{
        lifecycleConfig.appType = SDLAppHMIType.DEFAULT;
    }
    self.sdlManager = [[SDLManager alloc] initWithConfiguration:config delegate:self];

    [self startManager];
}

- (void)startManager {
    __weak typeof (self) weakSelf = self;
    [self.sdlManager startWithReadyHandler:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"SDL errored starting up: %@", error);
            [weakSelf sdlex_updateProxyState:ProxyStateStopped];
            return;
        }

        [weakSelf sdlex_updateProxyState:ProxyStateConnected];
        [weakSelf setupPermissionsCallbacks];

        if ([weakSelf.sdlManager.hmiLevel isEqualToEnum:[SDLHMILevel FULL]]) {
            [weakSelf showInitialData];
        }
    }];
}

- (void)reset {
    [self sdlex_updateProxyState:ProxyStateStopped];
    [self.sdlManager stop];
    // Remove reference
    self.sdlManager = nil;
}

- (void)showInitialData {
    if ((self.initialShowState != SDLHMIInitialShowStateDataAvailable) || ![self.sdlManager.hmiLevel isEqualToEnum:[SDLHMILevel FULL]]) {
        return;
    }

    self.initialShowState = SDLHMIInitialShowStateShown;

    SDLShow* show = [[SDLShow alloc] initWithMainField1:@"SDL" mainField2:@"Test App" alignment:[SDLTextAlignment LEFT_ALIGNED]];
    SDLSoftButton *pointingSoftButton = [self.class pointingSoftButtonWithManager:self.sdlManager];

    show.softButtons = [@[pointingSoftButton] mutableCopy];
    show.graphic = [self.class mainGraphicImage];

    [self.sdlManager sendRequest:show];
}

- (void)setupPermissionsCallbacks {
    // This will tell you whether or not you can use the Show RPC right at this moment
    BOOL isAvailable = [self.sdlManager.permissionManager isRPCAllowed:@"Show"];
    NSLog(@"Show is allowed? %@", @(isAvailable));

    // This will set up a block that will tell you whether or not you can use none, all, or some of the RPCs specified, and notifies you when those permissions change
    SDLPermissionObserverIdentifier observerId = [self.sdlManager.permissionManager addObserverForRPCs:@[@"Show", @"Alert", @"SubscribeVehicleData"] groupType:SDLPermissionGroupTypeAllAllowed withHandler:^(NSDictionary<SDLPermissionRPCName, NSNumber<SDLBool> *> * _Nonnull change, SDLPermissionGroupStatus status) {
        NSLog(@"Show changed permission to status: %@, dict: %@", @(status), change);
    }];
    // The above block will be called immediately, this will then remove the block from being called any more
    [self.sdlManager.permissionManager removeObserverForIdentifier:observerId];

    // This will give us the current status of the group of RPCs, as if we had set up an observer, except these are one-shot calls
    NSArray *rpcGroup =@[@"AddCommand", @"PerformInteraction"];
    SDLPermissionGroupStatus commandPICSStatus = [self.sdlManager.permissionManager groupStatusOfRPCs:rpcGroup];
    NSDictionary *commandPICSStatusDict = [self.sdlManager.permissionManager statusOfRPCs:rpcGroup];
    NSLog(@"Command / PICS status: %@, dict: %@", @(commandPICSStatus), commandPICSStatusDict);

    // This will set up a long-term observer for the RPC group and will tell us when the status of any specified RPC changes (due to the `SDLPermissionGroupTypeAny`) option.
    [self.sdlManager.permissionManager addObserverForRPCs:rpcGroup groupType:SDLPermissionGroupTypeAny withHandler:^(NSDictionary<SDLPermissionRPCName, NSNumber<SDLBool> *> * _Nonnull change, SDLPermissionGroupStatus status) {
        NSLog(@"Command / PICS changed permission to status: %@, dict: %@", @(status), change);
    }];
}

+ (SDLLifecycleConfiguration *)setLifecycleConfigurationPropertiesOnConfiguration:(SDLLifecycleConfiguration *)config {
    SDLArtwork *appIconArt = [SDLArtwork persistentArtworkWithImage:[UIImage imageNamed:@"AppIcon60x60@2x"] name:@"AppIcon" asImageFormat:SDLArtworkImageFormatPNG];

    config.shortAppName = SDLShortAppName;
    config.appIcon = appIconArt;
    config.voiceRecognitionCommandNames = @[VRCommandName];
    config.ttsName = [SDLTTSChunk textChunksFromString:config.shortAppName];
    return config;
}

- (void)sdlex_updateProxyState:(ProxyState)newState {
    if (self.state != newState) {
        [self willChangeValueForKey:@"state"];
        _state = newState;
        [self didChangeValueForKey:@"state"];
    }
}

#pragma mark - SDLManagerDelegate

- (void)managerDidDisconnect {
    // Reset our state
    self.firstTimeState = SDLHMIFirstStateNone;
    self.initialShowState = SDLHMIInitialShowStateNone;
    [self sdlex_updateProxyState:ProxyStateStopped];
    if (_ShouldRestartOnDisconnect) {
        [self startManager];
    }
}

- (void)hmiLevel:(SDLHMILevel *)oldLevel didChangeToLevel:(SDLHMILevel *)newLevel {
    if (![newLevel isEqualToEnum:[SDLHMILevel NONE]] && (self.firstTimeState == SDLHMIFirstStateNone)) {
        // This is our first time in a non-NONE state
        self.firstTimeState = SDLHMIFirstStateNonNone;

        // Send AddCommands
        [self prepareRemoteSystem];
    }

    if ([newLevel isEqualToEnum:[SDLHMILevel FULL]] && (self.firstTimeState != SDLHMIFirstStateFull)) {
        // This is our first time in a FULL state
        self.firstTimeState = SDLHMIFirstStateFull;
    }

    if ([newLevel isEqualToEnum:[SDLHMILevel FULL]]) {
        // We're always going to try to show the initial state, because if we've already shown it, it won't be shown, and we need to guard against some possible weird states
        [self showInitialData];
    }
}

#pragma mark - Observers
- (void)sdl_addRPCObservers {
    // Adding Notification Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveVehicleData:) name:SDLDidReceiveVehicleDataNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeLanguageNotification:) name:SDLDidChangeLanguageNotification object:nil];
}

#pragma mark - RPC builders

+ (SDLAddCommand *)speakNameCommandWithManager:(SDLManager *)manager {
    NSString *commandName = @"Speak App Name";

    SDLMenuParams *commandMenuParams = [[SDLMenuParams alloc] init];
    commandMenuParams.menuName = commandName;

    SDLAddCommand *speakNameCommand = [[SDLAddCommand alloc] init];
    speakNameCommand.vrCommands = [NSMutableArray arrayWithObject:commandName];
    speakNameCommand.menuParams = commandMenuParams;
    speakNameCommand.cmdID = @0;

    speakNameCommand.handler = ^void(SDLOnCommand *notification) {
        [manager sendRequest:[self.class appNameSpeak]];
    };

    return speakNameCommand;
}

+ (SDLAddCommand *)interactionSetCommandWithManager:(SDLManager *)manager {
    NSString *commandName = @"Perform Interaction";

    SDLMenuParams *commandMenuParams = [[SDLMenuParams alloc] init];
    commandMenuParams.menuName = commandName;

    SDLAddCommand *performInteractionCommand = [[SDLAddCommand alloc] init];
    performInteractionCommand.vrCommands = [NSMutableArray arrayWithObject:commandName];
    performInteractionCommand.menuParams = commandMenuParams;
    performInteractionCommand.cmdID = @1;

    // NOTE: You may want to preload your interaction sets, because they can take a while for the remote system to process. We're going to ignore our own advice here.
    __weak typeof(self) weakSelf = self;
    performInteractionCommand.handler = ^void(SDLOnCommand *notification) {
        [weakSelf sendPerformOnlyChoiceInteractionWithManager:manager];
    };

    return performInteractionCommand;
}

- (void)createMenuItemWithSubmenu {

    SDLAddSubMenu* subMenu = [[SDLAddSubMenu alloc] initWithId:2 menuName:@"Example Submenu"];

    [self.sdlManager sendRequest:subMenu withResponseHandler:^(SDLRPCRequest *request, SDLRPCResponse *response, NSError *error) {
        if ([response.resultCode isEqualToEnum:SDLResult.SUCCESS]) {
            // The submenu was created successfully, start adding the menu items
            [self createSubmenuItem];
        }
    }];
}

- (void)createMenuItemScrollableMessage {

    SDLMenuParams* menuParameters = [[SDLMenuParams alloc] initWithMenuName:@"Show Scrollable Message" parentId:0 position:0];

    // For menu items, be sure to use unique ids.
    SDLAddCommand* menuItem = [[SDLAddCommand alloc] initWithId:3 vrCommands:@[@"Show Scrollable Message"] handler:^(SDLRPCNotification *notification) {
        if (![notification isKindOfClass:SDLOnCommand.class]) {
            return;
        }

        SDLOnCommand* onCommand = (SDLOnCommand*)notification;

        if ([onCommand.triggerSource isEqualToEnum:SDLTriggerSource.MENU]) {
            [self createScrollableMessage];
        }
    }];

    // Set the menu parameters
    menuItem.menuParams = menuParameters;

    [self.sdlManager sendRequest:menuItem withResponseHandler:^(SDLRPCRequest *request, SDLRPCResponse *response, NSError *error) {
        if ([response.resultCode isEqualToEnum:SDLResult.SUCCESS]) {
            // The menuItem was created successfully now add a submenu
        }
    }];
}

- (void)createMenuItemSliders {

    SDLMenuParams* menuParameters = [[SDLMenuParams alloc] initWithMenuName:@"Show Slider" parentId:0 position:0];

    // For menu items, be sure to use unique ids.
    SDLAddCommand* menuItem = [[SDLAddCommand alloc] initWithId:4 vrCommands:@[@"Show Slider"] handler:^(SDLRPCNotification *notification) {
        if (![notification isKindOfClass:SDLOnCommand.class]) {
            return;
        }

        SDLOnCommand* onCommand = (SDLOnCommand*)notification;

        if ([onCommand.triggerSource isEqualToEnum:SDLTriggerSource.MENU]) {
            // Menu Item Was Selected
            [self createSlider];
        }
    }];

    // Set the menu parameters
    menuItem.menuParams = menuParameters;

    [self.sdlManager sendRequest:menuItem withResponseHandler:^(SDLRPCRequest *request, SDLRPCResponse *response, NSError *error) {
        if ([response.resultCode isEqualToEnum:SDLResult.SUCCESS]) {
            // The menuItem was created successfully now add a submenu
        }
    }];
}

- (void) createSubmenuItem {
    SDLMenuParams* menuParameters = [[SDLMenuParams alloc] initWithMenuName:@"Example Item" parentId:2 position:0];

    // For menu items, be sure to use unique ids.
    SDLAddCommand* menuItem = [[SDLAddCommand alloc] initWithId:2 vrCommands:@[@"Example Item"] handler:^(SDLRPCNotification *notification) {
        if (![notification isKindOfClass:SDLOnCommand.class]) {
            return;
        }

        SDLOnCommand* onCommand = (SDLOnCommand*)notification;

        if ([onCommand.triggerSource isEqualToEnum:SDLTriggerSource.MENU]) {
            // Menu Item Was Selected
        }
    }];

    // Set the menu parameters
    menuItem.menuParams = menuParameters;

    [self.sdlManager sendRequest:menuItem withResponseHandler:^(SDLRPCRequest *request, SDLRPCResponse *response, NSError *error) {
        if ([response.resultCode isEqualToEnum:SDLResult.SUCCESS]) {
            // The menuItem was created successfully now add a submenu
        }
    }];
}

- (void) createScrollableMessage {
    // Menu Item Was Selected
    SDLScrollableMessage* message = [[SDLScrollableMessage alloc] init];
    // message from cat ipsum
    message.scrollableMessageBody = @"Sit in window and stare oooh, a bird, yum russian blue make muffins hiss and stare at nothing then run suddenly away love to play with owner's hair tie. Meow cat is love, cat is life attack dog, run away and pretend to be victim. Chew foot. Peer out window, chatter at birds, lure them to mouth always hungry.";
    message.timeout = @10000;
    [self.sdlManager sendRequest:message];
}

- (void) createSlider {
    SDLSlider* slider = [[SDLSlider alloc] init];
    slider.timeout = @10000;
    slider.position = @1;
    slider.numTicks = @8;
    slider.sliderHeader = @"Slider Header";
    [self.sdlManager sendRequest:slider];
}

+ (SDLSpeak *)appNameSpeak {
    SDLSpeak *speak = [[SDLSpeak alloc] init];
    speak.ttsChunks = [SDLTTSChunk textChunksFromString:@"S D L Example App"];

    return speak;
}

+ (SDLSpeak *)goodJobSpeak {
    SDLSpeak *speak = [[SDLSpeak alloc] init];
    speak.ttsChunks = [SDLTTSChunk textChunksFromString:@"Good Job"];

    return speak;
}

+ (SDLSpeak *)youMissedItSpeak {
    SDLSpeak *speak = [[SDLSpeak alloc] init];
    speak.ttsChunks = [SDLTTSChunk textChunksFromString:@"You missed it"];

    return speak;
}

+ (SDLCreateInteractionChoiceSet *)createOnlyChoiceInteractionSet {
    SDLCreateInteractionChoiceSet *createInteractionSet = [[SDLCreateInteractionChoiceSet alloc] init];
    createInteractionSet.interactionChoiceSetID = @0;

    NSString *theOnlyChoiceName = @"The Only Choice";
    SDLChoice *theOnlyChoice = [[SDLChoice alloc] init];
    theOnlyChoice.choiceID = @0;
    theOnlyChoice.menuName = theOnlyChoiceName;
    theOnlyChoice.vrCommands = [NSMutableArray arrayWithObject:theOnlyChoiceName];

    createInteractionSet.choiceSet = [NSMutableArray arrayWithArray:@[theOnlyChoice]];

    return createInteractionSet;
}

+ (void)sendPerformOnlyChoiceInteractionWithManager:(SDLManager *)manager {
    SDLPerformInteraction *performOnlyChoiceInteraction = [[SDLPerformInteraction alloc] init];
    performOnlyChoiceInteraction.initialText = @"Choose the only one! You have 5 seconds...";
    performOnlyChoiceInteraction.initialPrompt = [SDLTTSChunk textChunksFromString:@"Choose it"];
    performOnlyChoiceInteraction.interactionMode = [SDLInteractionMode BOTH];
    performOnlyChoiceInteraction.interactionChoiceSetIDList = [NSMutableArray arrayWithObject:@0];
    performOnlyChoiceInteraction.helpPrompt = [SDLTTSChunk textChunksFromString:@"Do it"];
    performOnlyChoiceInteraction.timeoutPrompt = [SDLTTSChunk textChunksFromString:@"Too late"];
    performOnlyChoiceInteraction.timeout = @5000;
    performOnlyChoiceInteraction.interactionLayout = [SDLLayoutMode LIST_ONLY];

    [manager sendRequest:performOnlyChoiceInteraction withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLPerformInteractionResponse * _Nullable response, NSError * _Nullable error) {
        if ((response == nil) || (error != nil)) {
            NSLog(@"Something went wrong, no perform interaction response: %@", error);
        }

        if ([response.choiceID isEqualToNumber:@0]) {
            [manager sendRequest:[self goodJobSpeak]];
        } else {
            [manager sendRequest:[self youMissedItSpeak]];
        }
    }];
}

+ (SDLSoftButton *)pointingSoftButtonWithManager:(SDLManager *)manager {
    SDLSoftButton* softButton = [[SDLSoftButton alloc] initWithHandler:^(__kindof SDLRPCNotification *notification) {
        if ([notification isKindOfClass:[SDLOnButtonPress class]]) {
            SDLAlert* alert = [[SDLAlert alloc] init];
            alert.alertText1 = @"You pushed the button!";
            [manager sendRequest:alert];
        }
    }];
    softButton.text = @"Press";
    softButton.softButtonID = @100;
    softButton.type = SDLSoftButtonType.BOTH;

    SDLImage* image = [[SDLImage alloc] init];
    image.imageType = SDLImageType.DYNAMIC;
    image.value = PointingSoftButtonArtworkName;
    softButton.image = image;

    return softButton;
}

+ (SDLImage *)mainGraphicImage {
    SDLImage* image = [[SDLImage alloc] init];
    image.imageType = SDLImageType.DYNAMIC;
    image.value = MainGraphicArtworkName;

    return image;
}

#pragma mark Vehicle Data
/**
 Subscribe to (periodic) vehicle data updates from SDL.
 */
- (void)sdl_subscribeVehicleData {
    NSLog(@"sdl_subscribeVehicleData");
    if (self.isVehicleDataSubscribed) {
        return;
    }

    SDLSubscribeVehicleData *subscribe = [[SDLSubscribeVehicleData alloc] init];

    subscribe.speed = @YES;

    [self.sdlManager sendRequest:subscribe withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        if ([response.resultCode isEqualToEnum:[SDLResult SUCCESS]]) {
            NSLog(@"Vehicle Data Subscribed!");
            _vehicleDataSubscribed = YES;
        }
    }];
}

- (void)didReceiveVehicleData:(SDLRPCNotificationNotification *)notification {
    SDLOnVehicleData *onVehicleData = notification.notification;
    if (!onVehicleData || ![onVehicleData isKindOfClass:SDLOnVehicleData.class]) {
        return;
    }
    NSLog(@"Speed: %@", onVehicleData.speed);
}

#pragma mark - Files / Artwork

+ (SDLArtwork *)pointingSoftButtonArtwork {
    return [SDLArtwork artworkWithImage:[UIImage imageNamed:@"sdl_softbutton_icon"] name:PointingSoftButtonArtworkName asImageFormat:SDLArtworkImageFormatPNG];
}

+ (SDLArtwork *)mainGraphicArtwork {
    return [SDLArtwork artworkWithImage:[UIImage imageNamed:@"sdl_logo_green"] name:MainGraphicArtworkName asImageFormat:SDLArtworkImageFormatPNG];
}

- (void)prepareRemoteSystem {
    [self.sdlManager sendRequest:[self.class speakNameCommandWithManager:self.sdlManager]];
    [self.sdlManager sendRequest:[self.class interactionSetCommandWithManager:self.sdlManager]];
    [self createMenuItemWithSubmenu];
    [self createMenuItemScrollableMessage];
    [self createMenuItemSliders];
    [self sdl_subscribeVehicleData];

    dispatch_group_t dataDispatchGroup = dispatch_group_create();
    dispatch_group_enter(dataDispatchGroup);

    dispatch_group_enter(dataDispatchGroup);
    [self.sdlManager.fileManager uploadFile:[self.class mainGraphicArtwork] completionHandler:^(BOOL success, NSUInteger bytesAvailable, NSError * _Nullable error) {
        dispatch_group_leave(dataDispatchGroup);

        if (success == NO) {
            NSLog(@"Something went wrong, image could not upload: %@", error);
            return;
        }
    }];

    dispatch_group_enter(dataDispatchGroup);
    [self.sdlManager.fileManager uploadFile:[self.class pointingSoftButtonArtwork] completionHandler:^(BOOL success, NSUInteger bytesAvailable, NSError * _Nullable error) {
        dispatch_group_leave(dataDispatchGroup);

        if (success == NO) {
            NSLog(@"Something went wrong, image could not upload: %@", error);
            return;
        }
    }];

    dispatch_group_enter(dataDispatchGroup);
    [self.sdlManager sendRequest:[self.class createOnlyChoiceInteractionSet] withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        // Interaction choice set ready
        dispatch_group_leave(dataDispatchGroup);
    }];

    dispatch_group_leave(dataDispatchGroup);
    dispatch_group_notify(dataDispatchGroup, dispatch_get_main_queue(), ^{
        self.initialShowState = SDLHMIInitialShowStateDataAvailable;
        [self showInitialData];
    });
}

@end

NS_ASSUME_NONNULL_END
