//
//  ViewController+NotesController.m
//  McApp
//
//  Created by Booker Washington on 10/23/15.
//  Copyright © 2015 Booker Washington. All rights reserved.
//

#import "NotesController.h"

@implementation NotesController 

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.delegate notesText:self.notes.text];
    NSLog(@"%@", self.notes.text);

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
