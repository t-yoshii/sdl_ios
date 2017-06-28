//
//  ConnectionIAPTableViewController.m
//  SmartDeviceLink-iOS

#import "ConnectionIAPTableViewController.h"
#import "Preferences.h"

#import "ProxyManager.h"



@interface ConnectionIAPTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *connectTableViewCell;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UISwitch *mediaSwitch;

@end



@implementation ConnectionIAPTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Observe Proxy Manager state
    [[ProxyManager sharedManager] addObserver:self forKeyPath:NSStringFromSelector(@selector(state)) options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew) context:nil];
    
    // Tableview setup
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    // Connect Button setup
    self.connectButton.tintColor = [UIColor whiteColor];

    // Set switch
    [self.mediaSwitch setOn:[Preferences sharedPreferences].appType animated:YES];
}

- (void)dealloc {
    @try {
        [[ProxyManager sharedManager] removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];
    } @catch (NSException __unused *exception) {}
}


#pragma mark - IBActions

- (IBAction)connectButtonWasPressed:(UIButton *)sender {

    if ([self.mediaSwitch isOn]) {
        [Preferences sharedPreferences].appType = 1;
    } else {
        [Preferences sharedPreferences].appType = 0;
    }

    ProxyState state = [ProxyManager sharedManager].state;
    switch (state) {
        case ProxyStateStopped: {
            [[ProxyManager sharedManager] startIAP];
        } break;
        case ProxyStateSearchingForConnection: {
            [[ProxyManager sharedManager] reset];
        } break;
        case ProxyStateConnected: {
            [[ProxyManager sharedManager] reset];
        } break;
        default: break;
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
        ProxyState newState = [change[NSKeyValueChangeNewKey] unsignedIntegerValue];
        [self proxyManagerDidChangeState:newState];
    }
}


#pragma mark - Private Methods

- (void)proxyManagerDidChangeState:(ProxyState)newState {
    UIColor* newColor = nil;
    NSString* newTitle = nil;

    switch (newState) {
        case ProxyStateStopped: {
            newColor = [UIColor redColor];
            newTitle = @"Connect";
        } break;
        case ProxyStateSearchingForConnection: {
            newColor = [UIColor blueColor];
            newTitle = @"Stop Searching";
        } break;
        case ProxyStateConnected: {
            newColor = [UIColor greenColor];
            newTitle = @"Disconnect";
        } break;
        default: break;
    }

    if (newColor || newTitle) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.connectTableViewCell setBackgroundColor:newColor];
            [self.connectButton setTitle:newTitle forState:UIControlStateNormal];
        });
    }
}


@end
