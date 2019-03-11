function [timestamps] = GoNoGo(isub,isEyelinked, isMEG, trlinfo, isPractice);

gamma = 2.2;
lumibg = 0;
ppd = 47;
res = [1920 1080];
iscreen = max(Screen('Screens'));

ntrials = trlinfo.ntrials;
timings = trlinfo.timings;
movementTime = timings.movementTime
cueDuration = timings.cueDuration ;
CueTargetISIDuration  =timings.CueTargetISIDuration;
targetDuration = timings.targetDuration; 

Screen('Preference', 'SkipSyncTests', 0);
Screen('Preference','VisualDebugLevel', 0);

HideCursor;
FlushEvents;
ListenChar(2);
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask','General','UseFastOffscreenWindows');
PsychImaging('AddTask','General','NormalizedHighresColorRange');
PsychImaging('AddTask','FinalFormatting','DisplayColorCorrection','SimpleGamma');
video = struct;
video.id = iscreen;
video.h = PsychImaging('OpenWindow',video.id,0);
[video.x,video.y] = Screen('WindowSize',video.h);
video.fps = Screen('FrameRate',video.h);
video.ifi = Screen('GetFlipInterval',video.h,100,50e-6,10);
Screen('BlendFunction',video.h,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
LoadIdentityClut(video.h);
PsychColorCorrection('SetColorClampingRange',video.h,0,1);
PsychColorCorrection('SetEncodingGamma',video.h,1/gamma);
Priority(MaxPriority(video.h));
Screen('ColorRange',video.h,1);
window = video.h;
winRect = Screen('Rect', window);

KbName('UnifyKeyNames');
keyabort = KbName('q'); % abort key (press until next trial)
keymoveOn = KbName({'n'})

if isMEG
    IOpath = 'C:\IOPort'; %this is the actual location of the toolbox on the stim pc
    addpath(IOpath);
    [portobject, portaddress] = OpenIOPort;
    triggerlength = 0.010;
    holdvalue = 0;
    
    if isEyelinked
        if EyelinkInit() ~= 1
            return
        end
        el = EyelinkInitDefaults(video.h);
        Eyelink('Command','file_sample_data = GAZE,AREA');
        Eyelink('Command','file_event_data = GAZE,AREA,VELOCITY');
        Eyelink('Command','file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK');
        Eyelink('OpenFile','motimeye');
        EyelinkDoTrackerSetup(el);
    end
    Screen('FillRect',video.h,lumibg);
    Screen('Flip',video.h);
end

%% Calibration

cuerct = CenterRectOnPoint([0,0,100,100],video.x/2,video.y/2); %place the cue %% Change here if too small

Screen('TextFont',video.h,'Calibri');
Screen('TextSize',video.h,round(0.9*ppd));
myText = ['Task will start soon' ];
Screen('FillRect',video.h,lumibg);
DrawFormattedText(window,myText, 'center', 'center', [0.7,0.7,0.7]);
Screen('Flip',video.h);

WaitSecs(2);

%% Generate images
        
myText = ['Get your index finger ready...'];
    
Screen('FillRect',video.h,lumibg); % set background luminance
DrawFormattedText(window, myText, 'center', 'center',[0.7,0.7,0.7]);
Screen('Flip',window);

cuerct = CenterRectOnPoint([0,0,100,100],video.x/2,video.y/2); %place the cue

[patch,map,alpha1] = imread('./Toolbox/cue_long.png');
patch = double(patch)/255;
alpha1 = double(alpha1)/255;
texcue(1) = Screen('MakeTexture',video.h,cat(3,patch,alpha1),[],[],2);

[patch,map,alpha1] = imread('./Toolbox/go.png');
patch = double(patch)/255;
alpha1 = double(alpha1)/255;
textg(1) = Screen('MakeTexture',video.h,cat(3,patch,alpha1),[],[],2);

[patch,map,alpha1] = imread('./Toolbox/nogo.png');
patch = double(patch)/255;
alpha1 = double(alpha1)/255;
textg(2) = Screen('MakeTexture',video.h,cat(3,patch,alpha1),[],[],2);

timestamps=[];

% Wait until the MEG recording has started
key = 0;
while key == 0
    [key,tkey] = CheckKeyPress(keymoveOn);
end

counter=0;
for itrial = 1:ntrials;
    counter=counter+1;
    
    curr_trial_timestamps=[];
    
    if CheckKeyPress(keyabort)
        break
    end
    
    if isMEG
        if isEyelinked
            Eyelink('StartRecording');
        end
    end
    %% Trial Starts Now.
           
    % Display the cue
    Screen('DrawTexture',video.h,texcue(trlinfo.icue(itrial)),[],cuerct,[],[],[],0.4); % cue
    Screen('DrawingFinished',video.h);
    t = Screen('Flip',video.h);
    cuePresentation = t;
    
    curr_trial_timestamps=[curr_trial_timestamps,t];
    
    if isMEG
        curr_code = trlinfo.icodes(itrial);
        io64( portobject, portaddress, curr_code);
        WaitSecs(triggerlength);
        io64( portobject, portaddress, holdvalue);
        
        if isEyelinked
            Eyelink('Message',sprintf('%03d',itrial));
        end
    end
    
    WaitSecs(cueDuration);
    
    Screen('FillRect',video.h,lumibg);

    t = Screen('Flip',video.h); %% After 0.2 s Fixation
    StartCueTargetISI = t;
    
    % Here you want a variable cue-target interval
    
    WaitSecs(CueTargetISIDuration - cueDuration);
    
    Screen('DrawTexture',video.h,textg(trlinfo.gonogo(itrial)),[],cuerct,[],[],[],0.4);
    Screen('DrawingFinished',video.h);
    t = Screen('Flip',video.h); %% Go/NoGo 
    
    curr_trial_timestamps=[curr_trial_timestamps,t];
    targetOnset = t;
    
    if isMEG
        curr_code = trlinfo.icodes(itrial)+10; 
        io64( portobject, portaddress, curr_code);
        WaitSecs(triggerlength);
        io64( portobject, portaddress, holdvalue);
        if isEyelinked
            Eyelink('Message',sprintf('TRIAL%03d',trlinfo.icodes(itrial)));
        end
      
    end
    
    WaitSecs(targetDuration);
    
    t = Screen('Flip',video.h); %% After 0.2 s Fixation
    
   movementTime = Shuffle(movementTime); %NEW 
   WaitSecs(movementTime(1)); %NEW
    
timestamps(itrial,:) = curr_trial_timestamps;   

if counter==100
    
cuerct = CenterRectOnPoint([0,0,100,100],video.x/2,video.y/2); %place the cue %% Change here if too small

Screen('TextFont',video.h,'Calibri');
Screen('TextSize',video.h,round(0.9*ppd));
myText = ['Break' ];
Screen('FillRect',video.h,lumibg);
DrawFormattedText(window,myText, 'center', 'center', [0.7,0.7,0.7]);
Screen('Flip',video.h);
    
WaitSecs(26);

cuerct = CenterRectOnPoint([0,0,100,100],video.x/2,video.y/2); %place the cue %% Change here if too small

Screen('TextFont',video.h,'Calibri');
Screen('TextSize',video.h,round(0.9*ppd));
myText = ['Break' ];
Screen('FillRect',video.h,lumibg);
DrawFormattedText(window,myText, 'center', 'center', [0, 0, 0]);
Screen('Flip',video.h);

WaitSecs(4);

end

end

t= Screen('Flip',window,2);
if isMEG
    if isEyelinked
        Eyelink('StopRecording');
    end
end
    
if isMEG
    CloseIOPort;
    if isEyelinked
        Eyelink('CloseFile');
        Eyelink('ReceiveFile');
        Eyelink('ShutDown');
    end
end

Screen('CloseAll');

FlushEvents;
ListenChar(0);
ShowCursor;

display('Done!');

end