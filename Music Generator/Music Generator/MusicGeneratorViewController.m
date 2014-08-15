
/////////////////////////////////////////////////////////////
//                                                         //
//  MusicGeneratorViewController.m                         //
//  MusicGenerator                                         //
//                                                         //
//  Created by Robert Stephens on 2014/08/13.              //
//  Copyright 2014 Robert Stpehens. All rights reserved.   //
//                                                         //
/////////////////////////////////////////////////////////////


#import "MusicGeneratorViewController.h"
#import <AudioToolbox/AudioToolbox.h>

OSStatus RenderMusic(
                     void *inRefCon,
                     AudioUnitRenderActionFlags 	*ioActionFlags,
                     const AudioTimeStamp 		*inTimeStamp,
                     UInt32 						inBusNumber,
                     UInt32 						inNumberFrames,
                     AudioBufferList 			*ioData) {
    
	// Fixed amplitude is good enough for our purposes
	const double amplitude = 0.25;
    
	// Get the Music parameters out of the view controller
	MusicGeneratorViewController *viewController = (__bridge MusicGeneratorViewController *)inRefCon;
	//double theta = viewController->theta;
	//double theta_increment = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
    
    int index = viewController->index;
    
	// This is a mono Music generator so we only need the first buffer
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
	
    int shift_a, shift_b, shift_c, ascend;
    
	// Generate the samples
	for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
		
        // tone ///////////////////////////////
        /*
         buffer[frame] = sin(theta) * amplitude;
         theta += theta_increment;
         if (theta > 2.0 * M_PI) {
         theta -= 2.0 * M_PI;
         }
         */
        ////////////////
        
        ++index;
        //char sound_point = (char)(index * ( ((index>>14)|(index>>12)) | (63 & (index>>8)) ) );
        
        shift_a = (int) viewController->var_a;
        shift_b = (int) viewController->var_b;
        shift_c = (int) viewController->var_c;
        
        ascend  = (int) viewController->frequency;
        
        char sound_point = (char)(index * ( ( (index>>shift_a)   |
                                             (index>>shift_b) ) |
                                           ( ascend & (index>>shift_c)) ) );
        Float32 sound_point_norm = (Float32)sound_point;
        sound_point_norm /= (256 * 2);
        sound_point_norm -= amplitude;
        buffer[frame] = sound_point_norm;
    }
	
	// Store the theta back in the view controller
	//viewController->theta = theta;
    viewController->index = index;
	return noErr;
}

void MusicInterruptionListener(void *inClientData, UInt32 inInterruptionState) {
	MusicGeneratorViewController *viewController = (__bridge MusicGeneratorViewController *)inClientData;
	
	[viewController stop];
}

@implementation MusicGeneratorViewController

@synthesize frequencySlider;
@synthesize frequencyLabel;

@synthesize var_a_Slider;
@synthesize var_a_Label;

@synthesize var_b_Slider;
@synthesize var_b_Label;

@synthesize var_c_Slider;
@synthesize var_c_Label;

@synthesize playButton;
@synthesize resetButton;



//@synthesize run_drift_loop;
bool _run_drift_loop;

- (IBAction)slider_freq_Changed:(UISlider *)slider {
	frequency = slider.value;
	frequencyLabel.text = [NSString stringWithFormat:@"%4.0f", frequency];
}

- (IBAction)slider_a_Changed:(UISlider *)slider {
	var_a = slider.value;
	var_a_Label.text = [NSString stringWithFormat:@"%3.0f", var_a];
}

- (IBAction)slider_b_Changed:(UISlider *)slider {
	var_b = slider.value;
	var_b_Label.text = [NSString stringWithFormat:@"%3.0f", var_b];
}

- (IBAction)slider_c_Changed:(UISlider *)slider {
	var_c = slider.value;
	var_c_Label.text = [NSString stringWithFormat:@"%3.0f", var_c];
}

- (void)createMusicUnit {
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &MusicUnit);
	NSAssert1(MusicUnit, @"Error creating unit: %hd", err);
	
	// Set our Music rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderMusic;
	input.inputProcRefCon = (__bridge void *)(self);
	err = AudioUnitSetProperty(MusicUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %hd", err);
	
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = four_bytes_per_float;
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	err = AudioUnitSetProperty (MusicUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %hd", err);
}

- (IBAction)togglePlay:(UIButton *)selectedButton {
	
    
    if (MusicUnit) {
        
        [self stop_play];
		
		//[selectedButton setTitle:NSLocalizedString(@"Play", nil) forState:0];
        [self.playButton setTitle:@"play" forState:UIControlStateNormal];
	}
	else {
        [self start_play];
        
		//[selectedButton setTitle:NSLocalizedString(@"Stop", nil) forState:0];
        [self.playButton setTitle:@"stop" forState:UIControlStateNormal];
	}
}

- (void)stop {
	if (MusicUnit) {
		[self togglePlay:playButton];
	}
}

- (void)stop_play {
    AudioOutputUnitStop(MusicUnit);
    AudioUnitUninitialize(MusicUnit);
    AudioComponentInstanceDispose(MusicUnit);
    MusicUnit = nil;
    
}

- (void) start_play {
    [self createMusicUnit];
    
    // Stop changing parameters on the unit
    OSErr err = AudioUnitInitialize(MusicUnit);
    NSAssert1(err == noErr, @"Error initializing unit: %hd", err);
    
    // Start playback
    err = AudioOutputUnitStart(MusicUnit);
    NSAssert1(err == noErr, @"Error starting unit: %hd", err);
    
}

- (IBAction)reset:(UIButton *)selectedButton {

    self.frequencySlider.value = 550;
    self.var_a_Slider.value = 13;
    self.var_b_Slider.value = 40;
    self.var_c_Slider.value = 0;
    
    
    [self slider_freq_Changed:frequencySlider];
  	[self slider_a_Changed:var_a_Slider];
	[self slider_b_Changed:var_b_Slider];
	[self slider_c_Changed:var_c_Slider];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    //monkey
    //self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"pixellated_monkey.png"]];
    
	[self slider_freq_Changed:frequencySlider];
  	[self slider_a_Changed:var_a_Slider];
	[self slider_b_Changed:var_b_Slider];
	[self slider_c_Changed:var_c_Slider];
    
	//sampleRate = 44100;
    sampleRate = 20000;
    
	OSStatus result = AudioSessionInitialize(NULL, NULL, MusicInterruptionListener, (__bridge void *)(self));
	if (result == kAudioSessionNoError) {
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	}
	AudioSessionSetActive(true);

    _run_drift_loop = false;

    [self.playButton setTitle:@"play" forState:UIControlStateNormal];
}

- (void)viewDidUnload {
	self.frequencySlider = nil;
	self.frequencyLabel = nil;
    
    self.var_a_Slider = nil;
    self.var_a_Label = nil;
    
    self.var_b_Slider = nil;
    self.var_b_Label = nil;
    
    self.var_c_Slider = nil;
    self.var_c_Label = nil;   
    
    self.playButton = nil;
    
	AudioSessionSetActive(false);
}


- (IBAction)spawn_drift_loop:(id)sender {
    if(!_run_drift_loop) {
        _run_drift_loop = true;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self drift_loop_background];
        });
    }
    else {
        _run_drift_loop = false;
    }
    
}

-(void) drift_loop_background {

    while(_run_drift_loop) {
        
        //[self start_play];
        
        int var_to_change_this_iter = random() % 4;
        
        sleep(3);
        
        if(var_to_change_this_iter == 0) {
            if( self.var_a_Slider.value > 0) {
                self.var_a_Slider.value = self.var_a_Slider.value - 1;
            }
            else if( self.var_a_Slider.value == 0) {
                self.var_a_Slider.value = 26;
            }
            [self slider_b_Changed:var_b_Slider];
        }
        else if(var_to_change_this_iter == 1) {
            if( self.var_b_Slider.value > 0) {
                self.var_b_Slider.value = self.var_b_Slider.value - 1;
            }
            else if(self.var_b_Slider.value == 0) {
                self.var_b_Slider.value = 80;
            }
            [self slider_b_Changed:var_b_Slider];
        }
        else if(var_to_change_this_iter == 2) {
            if( self.var_c_Slider.value > -25) {
                self.var_c_Slider.value = self.var_c_Slider.value - 1;
            }
            else if(self.var_c_Slider.value == -25) {
                self.var_c_Slider.value = 25;
            }
            [self slider_c_Changed:var_b_Slider];
        }
        else {
            if( self.frequencySlider.value > 100) {
                self.frequencySlider.value = self.frequencySlider.value - 5;
            }
            else if ( self.frequencySlider.value == 100){
                self.frequencySlider.value = 1000;
            }
            [self slider_freq_Changed:frequencySlider];
        }
        
        //[self stop_play];
    }
    
}

@end
