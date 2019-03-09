% Project name: MRSI_GRIP
% Project owner: Justin Andrushko (PiNG, Oxford)
% Catharina Zich, Oxford, 9/5/19
% on Matlab 2018b
% visuaize force & max level (75/25%)

%%

% CLEAR
close all;
clear all;
clc;

% PATHS
PSYCHTOOLBOX_PATH='/Applications/Psychtoolbox/';
MAINPATH='/Users/Catha/Desktop/OX_for Justin/';
SCRIPTPATH=[MAINPATH 'scripts/MRSI_GRIP-master/'];
PATHOUT=[MAINPATH 'rawdata/'];

addpath(PSYCHTOOLBOX_PATH);
mkdir(PATHOUT);
cd(SCRIPTPATH);

%% -----------------------------------------------------------%
%                      RESPONSE KEYS                          %
%-------------------------------------------------------------%
% CONECT TO DEVICE
dyno = SSQ_connect_dyno;
%dyno=[];

% KEYS
KbName('UnifyKeyNames');% Consistent mapping of keyCodes to key names on all operating systems.
escapeKey = KbName('ESCAPE');

%% -----------------------------------------------------------%
%                           PROMPT                            %
%-------------------------------------------------------------%

prompt = {'Subject Number:','Hand','Level'};
dlgname = 'Run Information';
LineNo = 1;
default  =  {'0','L-R','25-75'};
answer = inputdlg(prompt,dlgname,LineNo,default); % display dialog
[subj_num, hand, level] = deal(answer{:}); % stores all subject answers in separate variables


%% -----------------------------------------------------------%
%                           SCREEN                            %
%-------------------------------------------------------------%

% SCREEN PREMISES
Screen('Preference', 'SkipSyncTests', 0); %set to 0 for maximum accuracy
AssertOpenGL;   % Checking Psychtoolbox
Screens = Screen('Screens');   % Get the screen numbers
ScreenNumber = max(Screens);   % draw to the ext ernal screen if needed

white = WhiteIndex(ScreenNumber);% check which codes for system is used (black or white)
black = BlackIndex(ScreenNumber);
gray = white/2;  % medium gray for the screen
red= [255 0 0];
green= [0 255 0];
yellow=[255 255 0];
orange=[255 125 0];
violet = [200 0 255];
bColor = gray;%background color for the screen as a variable

% SCREEN PROPERTIES
screenRect = [0 0 1200 850]; % small window for testing purposes
[window, rect] = PsychImaging('OpenWindow', ScreenNumber, bColor, screenRect);

% CENTRE of window
[screenXcenter, screenYcenter] = RectCenter(rect);

%% -----------------------------------------------------------%
%                          FRAME                              %
%-------------------------------------------------------------%
Rect_width=50;
Rect_hight=500;
Rect_frame = CenterRectOnPointd([0 0 Rect_width Rect_hight], screenXcenter, screenYcenter);

%% -----------------------------------------------------------%
%                          LINE                               %
%-------------------------------------------------------------%
level_num=str2num(level);
Line_hight=(screenYcenter+(Rect_hight/2))-((Rect_hight*level_num)/100);

%% -----------------------------------------------------------%
%                          TIMING                             %
%-------------------------------------------------------------%

% REFRESH RATE of monitor
ifi = Screen('GetFlipInterval', window);

force_duration = 1;  % duration of contraction (s)
total_time = 10*60; %=10 minutes
number_of_trials = total_time/force_duration;
frame = 1;

%% -----------------------------------------------------------%
%                    INSTRUCTIONS                             %
%-------------------------------------------------------------%

text_start = 'Instrucitons here.';
text_final = 'You have completed the task. Thank you';

text_size= 20;
Screen('TextSize', window, text_size);
Screen('TextFont', window, 'Calibri');

%% -----------------------------------------------------------%
%                           FORCE                             %
%-------------------------------------------------------------%

% DEFINE VARIABLES FOR FORCE GRIP
cd(SCRIPTPATH);
load('calibration.mat');

force=[];

%% -----------------------------------------------------------%
%                      EXPERIMENTAL LOOP                      %
%-------------------------------------------------------------%
HideCursor; %hide mouse when experiment is on

% DSIPLAY INSTRUCTIONS
DrawFormattedText(window, text_start, 'center', 'center', black);
Screen('Flip', window);
WaitSecs(2);

total=tic,
for n=1:number_of_trials
    rate=tic;
    while (1)
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode(escapeKey)% allows to stop experiment is esc is pressed
            ShowCursor;
            sca;
            return
        end %if
                
        % GET AND SCALE FORCE AND SUBTRACT OFFSET FROM IT 
        force_temp = SSQ_get_force(dyno)-base_mean_glob;
        
        % GET TIME FOR NEXT WRITE OUT
        Time_writeout= GetSecs;
        
        % NORMALIZE TO MAX FORCE
        force_temp=(force_temp*100)/(force_max_glob-base_mean_glob);
        
        % ADD INFO FROM CURRENT FLIP TO THE END OF MATRIX
        force=[force;force_temp Time_writeout];
        
        % TRANSLATE FORCE TO SCREEN SPACE
        force_temp=(force_temp*Rect_hight)/100;
        if force_temp<0
            force_temp=0;
        elseif force_temp>Rect_hight
            force_temp=Rect_hight;
        end
        
        % TRANSFER FORCE INTO BALL MOVEMENT
        y_ball=Rect_frame(4)-force_temp;
        
        % DRAW FRAME 
        if mod(n,2)
            Screen('FrameRect', window, orange, Rect_frame,2); 
            Textinst='R';
        else
            Screen('FrameRect', window, green, Rect_frame,2);
            Textinst='C';
        end
            
        % DRAW SHORT INSTRUCTIONS
        DrawFormattedText(window, Textinst, screenXcenter-Rect_width-10, screenYcenter, black);
        DrawFormattedText(window, Textinst, screenXcenter+Rect_width, screenYcenter, black);
        
        % DRAW LINE
        Screen('DrawLine', window,black,screenXcenter-Rect_width,Line_hight,screenXcenter+Rect_width,Line_hight,2);
        
        % DRAW DOT
        Screen('DrawDots', window, [screenXcenter y_ball], 20, white, [], 2);
        
        % FLIP EVERYTHING
        segmentON = Screen('Flip', window);
        
        % END OF SQUEEZE
        if toc(rate) >=force_duration
            break;
        end
    end
    
    % END OF TASK
    if toc(total) >=total_time
        break;
    end
end

% DSIPL END TEXT
DrawFormattedText(window, text_final, 'center', 'center', black);
Screen('Flip', window);
WaitSecs(2);

sca;
clear Screen;
ShowCursor();

if ~isempty(dyno), fclose(dyno); end

%% -----------------------------------------------------------%
%                             SAVE                            %
%-------------------------------------------------------------%

filename = ['S',subj_num,'_', hand,'_MRSI_',datestr(datetime)];%works on mc
% %filename = ['S',subj_num,'_', hand,'_MVC_',timepoint,'_',datestr(datetime,'yymmdd')];
cd(PATHOUT);
save(filename,'force','force_max_glob');