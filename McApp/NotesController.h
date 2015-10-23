//
//  ViewController+NotesController.h
//  McApp
//
//  Created by Booker Washington on 10/23/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import "ViewController.h"

@protocol NotesControllerDelegate <NSObject>


@required
- (void)notesText:(NSString *)data;

@end

@interface NotesController : ViewController

@property (nonatomic, strong) id<NotesControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UITextView *notes;

@end
