//
//  UIImage+DispatchLoad.m
//  DreamChannel
//
//  Created by Slava on 3/28/11.
//  Copyright 2011 Alterplay. All rights reserved.
//

#import "UIImageView+DispatchLoad.h"
#import "FileUtil.h"
#import "NSString+Addition.h"
@implementation UIImageView (DispatchLoad)

- (void) setImageFromUrl:(NSString*)urlString {
    [self setImageFromUrl:urlString completion:NULL];
}

- (void) setImageFromUrl:(NSString*)urlString 
              completion:(void (^)(void))completion {


    
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        NSString *str = [FileUtil getCachePicPath] ;
        NSString *aa = [str stringByAppendingFormat:@"/%@",[urlString md5Value]];
        UIImage *avatarImage = nil;
        NSData *data = [NSData dataWithContentsOfFile:aa];
        avatarImage = [UIImage imageWithData:data];

//        if(data)
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.image = avatarImage;
//            });
//
//        }
//        else
        {
            NSData *responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
       
            avatarImage = [UIImage imageWithData:responseData];
            
            if (avatarImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.image = avatarImage;
                    [responseData writeToFile:aa  atomically:YES];

                });
                dispatch_async(dispatch_get_main_queue(), completion);
            }
            else {
                NSLog(@"-- impossible download: %@", urlString);
            }
        }
	});
    
}

@end