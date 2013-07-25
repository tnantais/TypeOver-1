//
//  ViewController.h
//  TypeOver
//
//  Created by Owen McGirr on 19/02/2013.
//  Copyright (c) 2013 Owen McGirr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <sqlite3.h>
#import <MessageUI/MessageUI.h>

@interface ViewController : UIViewController <MFMessageComposeViewControllerDelegate, UIActionSheetDelegate> {
    
    
    // outlets
	
    __weak IBOutlet UITextView *textArea;
    __weak IBOutlet UIBarButtonItem *useButton;
	__weak IBOutlet UIBarButtonItem *settingsButton;
    __weak IBOutlet UIButton *punct1Button;
    __weak IBOutlet UIButton *abc2Button;
    __weak IBOutlet UIButton *def3Button;
    __weak IBOutlet UIButton *ghi4Button;
    __weak IBOutlet UIButton *jkl5Button;
    __weak IBOutlet UIButton *mno6Button;
    __weak IBOutlet UIButton *pqrs7Button;
    __weak IBOutlet UIButton *tuv8Button;
    __weak IBOutlet UIButton *wxyz9Button;
    __weak IBOutlet UIButton *shiftButton;
    __weak IBOutlet UIButton *wordsLettersButton;
	__weak IBOutlet UIButton *speakButton;
    __weak IBOutlet UIButton *space0Button;
    __weak IBOutlet UIButton *backspaceButton;
    __weak IBOutlet UIButton *clearButton;
    
	
    // variables and pointers 
    
    NSTimer *inputTimer, *backspaceTimer;
	bool words, letters, space, shift, clearShift, clearSpace, clearWords, clearLetters;
    NSString *clearString, *clearWordString, *wordString;
	NSMutableString *add;
    NSMutableArray *predResultsArray, *clearPredResultsArray;
    int timesCycled, wordId, clearWordId;
    sqlite3 *dbWordPrediction;
	
	
}


// actions

- (IBAction)useAct:(id)sender;
- (IBAction)punct1Act:(id)sender;
- (IBAction)abc2Act:(id)sender;
- (IBAction)def3Act:(id)sender;
- (IBAction)ghi4Act:(id)sender;
- (IBAction)jkl5Act:(id)sender;
- (IBAction)mno6Act:(id)sender;
- (IBAction)pqrs7Act:(id)sender;
- (IBAction)tuv8Act:(id)sender;
- (IBAction)wxyz9Act:(id)sender;
- (IBAction)speakAct:(id)sender;
- (IBAction)shiftAct:(id)sender;
- (IBAction)space0Act:(id)sender;
- (IBAction)wordsLettersAct:(id)sender;
- (IBAction)backspaceAct:(id)sender;
- (IBAction)clearAct:(id)sender;


@end
