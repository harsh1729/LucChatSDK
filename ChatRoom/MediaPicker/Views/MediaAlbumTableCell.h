/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

#import <MatrixKit/MatrixKit.h>

/**
 'MediaAlbumTableCell' is a base class for displaying a user album.
 */
@interface MediaAlbumTableCell : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *albumThumbnail;
@property (weak, nonatomic) IBOutlet UIImageView *bottomLeftIcon;

@property (strong, nonatomic) IBOutlet UILabel *albumDisplayNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *albumCountLabel;

@end

