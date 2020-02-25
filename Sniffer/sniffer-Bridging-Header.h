//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
@import Cocoa;


@interface XLNavigationItemView : NSView {}
@property(retain,nonatomic) NSImage *image;
@property(retain,nonatomic) NSImage *alternateImage;
@property(retain,nonatomic) NSColor *selectedColor;
@property(retain,nonatomic) NSColor *deSelectedColor;

@property(copy) NSString *itemName;
@end

@protocol XLPluginSetupProtocol <NSObject>

@required
// 注册插件的对外接口数据原。
- (void)registeHostController:(id)hostController bundle:(NSBundle *)bundle;

// 数字低级别高。
- (uint8_t)priority;

// 插件的身份识别。
- (NSString *)identifier;

@optional
// 返回注册的hostController。
- (id)hostController;

@end

@protocol XLPluginNotificationProtocol <NSObject>

@optional
// 通知插件完成加载。
- (void)pluginDidFinishLoadingNotification:(NSNotification *)notification;

// 通知插件用户登陆状态改变。
- (void)userLoginStatusDidChangedNotification:(NSNotification *)notification;

// 通知插件用户身份信息发生改变。
- (void)userInformationDidUpdatedNotification:(NSNotification *)notification;

// 通知插件用户改变皮肤
- (void)userChangeSkinNotification:(NSNotification *)notification;

// 通知插件网络连接发生变化
- (void)reachabilityStatusDidChangeNotification: (NSNotification *)notification;
@end

@protocol XLPluginPageProtocol <XLPluginSetupProtocol,XLPluginNotificationProtocol>
@required
- (NSArray *)navigationItems;
- (NSView *)toolbarViewForItem:(id)item;
- (NSView *)contentViewForItem:(id)item;

@optional
// 内容试图加载 卸载通知
- (void)pluginViewWillAppearForItem:(id)item;
- (void)pluginViewDidAppearForItem:(id)item;
- (void)pluginViewWillDisappearForItem:(id)item;
- (void)pluginViewDidDisappearForItem:(id)item;

@end

@protocol XLHostPageProtocol
@required
- (XLNavigationItemView *)makeNavigationItemWithIdentifer:(NSString *)identifier
                                                    title:(NSString *)title;

@end
@protocol XLHostSkinProtocol <NSObject>
@required
@property (copy,readonly) NSString *skinIdentifier;

- (NSColor *)fontColorForKey:(NSString *)key;
- (NSColor *)backgroundColorForKey:(NSString *)key;
- (NSColor *)borderColorForKey:(NSString *)key;
- (NSImage *)imageForKeyPath:(NSString *)keyPath;
- (id)themeForKey:(NSString *)key;

@end

@interface XLPluginBaseController : NSObject <XLPluginNotificationProtocol,XLPluginSetupProtocol> {} @end

