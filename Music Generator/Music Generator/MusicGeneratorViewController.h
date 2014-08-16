
/////////////////////////////////////////////////////////////
//                                                         //
//  MusicGeneratorViewController.h                         //
//  MusicGenerator                                         //
//                                                         //
//  Created by Robert Stephens on 2014/08/13.              //
//  Copyright 2014 Robert Stpehens. All rights reserved.   //
//                                                         //
/////////////////////////////////////////////////////////////

#import <UIKit/UIKit.h>
#import <AudioUnit/AudioUnit.h>

@interface MusicGeneratorViewController : UIViewController {
    UILabel *frequencyLabel;
    UILabel *freq_val_Label;
    UISlider *frequencySlider;

    UILabel *var_a_Label;
    UILabel *var_a_val_Label;
    UISlider *var_a_Slider;
    
    UILabel *var_b_Label;
    UILabel *var_b_val_Label;
    UISlider *var_b_Slider;
    
    UILabel *var_c_Label;
    UILabel *var_c_val_Label;
    UISlider *var_c_Slider;
    
    UIButton *playButton;
    UIButton *resetButton;
    
    //@property (nonatomic, retain) bool run_drift_loop;
    
    AudioComponentInstance MusicUnit;
    
    UISegmentedControl *var_depth_seg_Button;
    
@public
    double frequency;
    double sampleRate;
    //double theta;
    
    double var_a;
    double var_b;
    double var_c;
    
    int depth;
    
    //double realfreq;
    
    int index;
}

@property (nonatomic, retain) IBOutlet UISlider *frequencySlider;
@property (nonatomic, retain) IBOutlet UILabel *frequencyLabel;
@property (nonatomic, retain) IBOutlet UILabel *freq_val_Label;

@property (nonatomic, retain) IBOutlet UISlider *var_a_Slider;
@property (nonatomic, retain) IBOutlet UILabel *var_a_Label;
@property (nonatomic, retain) IBOutlet UILabel *var_a_val_Label;

@property (nonatomic, retain) IBOutlet UISlider *var_b_Slider;
@property (nonatomic, retain) IBOutlet UILabel *var_b_Label;
@property (nonatomic, retain) IBOutlet UILabel *var_b_val_Label;

@property (nonatomic, retain) IBOutlet UISlider *var_c_Slider;
@property (nonatomic, retain) IBOutlet UILabel *var_c_Label;
@property (nonatomic, retain) IBOutlet UILabel *var_c_val_Label;

- (IBAction)slider_freq_Changed:(UISlider *)frequencySlider;  //609
- (IBAction)slider_a_Changed:(UISlider *)var_a_Slider;  //13
- (IBAction)slider_b_Changed:(UISlider *)var_b_Slider;  //40
- (IBAction)slider_c_Changed:(UISlider *)var_c_Slider;  //0

- (IBAction)seg_depth_changed:(UISegmentedControl *)depth_control;

@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UIButton *resetButton;
@property (nonatomic, retain) IBOutlet UISegmentedControl *var_depth_seg_Button;




- (IBAction)togglePlay:(UIButton *)selectedButton;
- (void)stop;
- (IBAction)spawn_drift_loop:(id)sender;
- (void) init_sliders;

@end

