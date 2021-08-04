#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ConfigParameters)
@interface NCAConfigParameters : NSObject

/// The addParam method shall add a configuration parameter either to the specified group or to the default group.
/// @param group Group to which the configuration parameter is to be added.
/// @param paramName Name of the configuration parameter.
/// @param paramValue Value of the configuration parameter.
/// @param error InvalidInput This exception shall be thrown if paramName is not provided or if a variable already exists in the dictionary.
- (void)addParamWithGroup:(NSString * _Nullable)group paramName:(NSString * _Nonnull)paramName paramValue:(NSString * _Nonnull)paramValue error:(NSError * _Nullable * _Nullable)error NS_SWIFT_NAME(addParam(group:paramName:paramValue:))  __attribute__((swift_error(nonnull_error)));

/// The getParamValue method shall return a configuration parameter’s value either from the specified group or from the default group.
/// @param group Group from which the configuration parameter’s value is to be returned.
/// @param paramName Name of the configuration parameter.
/// @param error InvalidInput This exception shall be thrown if paramName is not provided.
- (NSString * _Nullable)getParamValueWithGroup:(NSString * _Nullable)group paramName:(NSString * _Nonnull)paramName error:(NSError * _Nullable * _Nullable)error NS_SWIFT_NAME(getParamValue(group:paramName:)) __attribute__((swift_error(nonnull_error)));

/// The removeParam method shall remove a configuration parameter either from the specified group or from the default group.
/// @param group Group from which the configuration parameter is to be removed.
/// @param paramName Name of the configuration parameter.
/// @param error InvalidInput This exception shall be thrown if paramName is not provided.
- (NSString * _Nullable)removeParamWithGroup:(NSString * _Nullable)group paramName:(NSString * _Nonnull)paramName error:(NSError * _Nullable * _Nullable)error NS_SWIFT_NAME(removeParam(group:paramName:)) __attribute__((swift_error(nonnull_error)));

@end

NS_ASSUME_NONNULL_END
