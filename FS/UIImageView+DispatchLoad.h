//
//  UIImage+DispatchLoad.h
//  DreamChannel
//
//  Created by Slava on 3/28/11.
//  Copyright 2011 Alterplay. All rights reserved.
//

@interface UIImageView (DispatchLoad)

- (void) setImageFromUrl:(NSString*)urlString;
- (void) setImageFromUrl:(NSString*)urlString 
              completion:(void (^)(void))completion;

@end