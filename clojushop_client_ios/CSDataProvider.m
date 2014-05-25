//
//  CSDataProvider.m
//  clojushop_client
//
//  Created by ischuetz on 22/05/2014.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

#import "AFHTTPRequestOperation.h"
#import "AFHTTPRequestOperationManager.h"
#import "CSDataProvider.h"
#import "CSProduct.h"
#import "CSCartItem.h"


@implementation CSDataProvider {
    NSString *host;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedDataProvider];
}

+ (CSDataProvider *)sharedDataProvider {
    static CSDataProvider *sharedDataProvider = nil;
    if (!sharedDataProvider) {
        sharedDataProvider = [[super allocWithZone:nil] init];

        [sharedDataProvider initHost];
        
    }
    return sharedDataProvider;
}

- (void) initHost {
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    host = [config objectForKey:@"host"];
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//private


- (void)request: (int) method url: (NSString *) url params: (NSDictionary *) params successHandler: (void (^)(NSDictionary *)) requestSuccessHandler
    failureHandler: (BOOL (^)(int)) requestFailureHandler {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSLog(@"Called method: %d url: %@ params: %@", method, url, params);
    
    void (^successHandler)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
//        NSLog(@"Response: %@", responseObject);
        
        if ([self isValidJSON:responseObject]) {
            
            int statusCode = [[responseObject objectForKey:@"status"] intValue];
            
            if (statusCode == 1) {
                requestSuccessHandler(responseObject);
                
            } else {
                BOOL handled = requestFailureHandler(statusCode);
                if (!handled) {
                    [self onRequestError: [self toClientStatusCode:statusCode]];
                }
            }
            
        } else {
            NSLog(@"Not valid JSON: %@", responseObject);
            int statusCode = 9;
            
            if (requestFailureHandler) {
                BOOL handled = requestFailureHandler(statusCode);
                if (!handled) {
                    [self onRequestError: statusCode];
                }
            }
            
        }
    };

    void (^failureHandler)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        
        int statusCode = 8;
        
        //TODO handling, pass map NSError to custom error
        BOOL handled = requestFailureHandler(statusCode);
        if (!handled) {
            [self onRequestError: statusCode];
        }
    };
    
    if (method == 1) {
        [manager GET:url parameters:params success:successHandler failure: failureHandler];
    } else if (method == 2) {
        [manager POST:url parameters:params success:successHandler failure: failureHandler];
    } else {
        NSLog(@"not supported request method: %d", method);
    }
}

- (void)get: (NSString *) url params: (NSDictionary *) params successHandler: (void (^)(NSDictionary *)) successHandler failureHandler: (BOOL (^)()) failureHandler {
    [self request:1 url:url params:params successHandler: successHandler failureHandler: failureHandler];
}


- (void)post: (NSString *) url params: (NSDictionary *) params successHandler: (void (^)(NSDictionary *)) successHandler failureHandler: (BOOL (^)()) failureHandler {
    [self request:2 url:url params:params successHandler: successHandler failureHandler: failureHandler];
}

- (BOOL)isValidJSON:(id)object {
    return object != nil && [object isKindOfClass: [NSDictionary class]];
}

- (void)showAlert: (NSString *) title msg: (NSString *) msg {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}



- (int)toClientStatusCode: (int) serverStatusCode {
    //TODO dictionary
    return serverStatusCode;
}


//TODO use enum? for client status codes
- (void)onRequestError: (int) statusCode {
    
    NSString *errorMsg;
    
    //TODO use map/constants
    
    switch (statusCode) {
        case 0:
        case 2:
        case 9: //wrong json format
            errorMsg = @"An unknown error ocurred. Please try again later.";
            break;
        case 4:
            errorMsg = @"Not found.";
            break;
        case 5:
            errorMsg = @"Validation error."; //TODO process fields
            break;
        case 3:
            errorMsg = @"User already exists.";
            break;
        case 6:
            errorMsg = @"Login failed, check your data is correct.";
            break;
        case 7:
            errorMsg = @"Not authenticated, please register/login and try again.";
            break;
        case 8:
            errorMsg = @"Connection error.";
            break;
        default:
            break;
    }
    
    [self showAlert: @"Error" msg: errorMsg];
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//public

- (void)getProducts: (int) start size: (int) size successHandler: (void (^)(NSArray *products)) successHandler failureHandler: (void (^)()) failureHandler {
    NSString *url = [NSString stringWithFormat:@"%@%@", host, @"/products"];
    NSDictionary *pars = @{
                           @"st":[NSNumber numberWithInteger:start],
                           @"sz":[NSNumber numberWithInteger:size]
                           };
    
    [self get:url params:pars
        successHandler:^(NSDictionary * response) {
            NSArray *productsJSON = [response objectForKey:@"products"];
        
            NSMutableArray *products = [[NSMutableArray alloc] init];
            for (id productJSON in productsJSON) {
                CSProduct *p = [CSProduct createFromDict:productJSON];
                if (p != nil) {
                    [products addObject:p];
                }
            }
        
            successHandler(products);
        }
        failureHandler:^ BOOL {
            failureHandler();
            return FALSE;
        }];
    }

- (void)getUser: (void (^)(NSDictionary *user)) successHandler failureHandler: (void (^)()) failureHandler {
    NSString *url = [NSString stringWithFormat:@"%@%@", host, @"/user"];
    
    [self get:url params:nil
        successHandler:^(NSDictionary * response) {
            NSDictionary *userJSON = [response objectForKey:@"user"];
    
            successHandler(userJSON);
        }
     
        failureHandler:^ BOOL {
            failureHandler();
            return FALSE;
        }];
}

- (void)logout: (void (^)(void)) successHandler failureHandler: (void (^)()) failureHandler {
    NSString *url = [NSString stringWithFormat:@"%@%@", host, @"/user/logout"];
    
    [self get:url params:nil
        successHandler:^(NSDictionary * response) {
            successHandler();
        }
     
        failureHandler:^ BOOL {
            failureHandler();
            return FALSE;
        }];
}

- (void)login: (NSString *) username password: (NSString *) password successHandler: (void (^)(void)) successHandler failureHandler: (void (^)()) failureHandler {
    NSString *url = [NSString stringWithFormat:@"%@%@", host, @"/user/login"];
    NSDictionary *pars = @{
                           @"una":username,
                           @"upw":password
                           };
    
    [self post:url params:pars
        successHandler:^(NSDictionary * response) {
            successHandler();
        }
        failureHandler:^ BOOL {
            failureHandler();
            return FALSE;
        }];
    }

- (void)register: (NSString *) username email: (NSString *) email password: (NSString *) password successHandler: (void (^)(void)) successHandler failureHandler: (void (^)()) failureHandler {
    NSString *url = [NSString stringWithFormat:@"%@%@", host, @"/user/register"];
    NSDictionary *pars = @{
                           @"una":username,
                           @"uem":email,
                           @"upw":password
                           };
    
    [self post:url params:pars
        successHandler:^(NSDictionary * response) {
            successHandler();
        }
        failureHandler:^ BOOL {
            failureHandler();
            return FALSE;
        }];
    }

- (void)addToCart: (NSString *) productId successHandler: (void (^)(void)) successHandler failureHandler: (void (^)()) failureHandler {
    NSString *url = [NSString stringWithFormat:@"%@%@", host, @"/cart/add"];

    //FIXME (server) not existing url that returns 7 (not auth) if not authenticated.  we get 404 only when the request is authenticated
    //NSString *url = @"http://localhost:3000/user/cart-add";
    NSDictionary *pars = @{
                           @"pid":productId
                           };
    
    [self post:url params:pars
        successHandler:^(NSDictionary * response) {
            successHandler();
        }
        failureHandler:^ BOOL (int statusCode) {
            failureHandler();
            return FALSE;
        }];
    }


- (void)getCart: (void (^)(NSArray *items)) successHandler failureHandler: (void (^)()) failureHandler {
    NSString *url = [NSString stringWithFormat:@"%@%@", host, @"/cart"];
    
    [self get:url params:nil
        successHandler:^(NSDictionary * response) {
            NSArray *itemsJSON = [response objectForKey:@"cart"];
            
            NSMutableArray *items = [[NSMutableArray alloc] init];
            for (id itemJSON in itemsJSON) {
                CSCartItem *c = [CSCartItem createFromDict:itemJSON];
                if (c != nil) {
                    [items addObject:c];
                }
            }
            successHandler(items);
        }
    failureHandler:^ BOOL (int statusCode) {
        if (statusCode == 7) {
            //for now just show empty cart when the user is not authenticated
            successHandler([[NSMutableArray alloc] init]);
            return TRUE;
        }
        failureHandler();
        return FALSE;
    }];
    }
@end