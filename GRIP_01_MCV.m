% Project name: MRSI_GRIP 
% Project owner: Justin Andrushko (PiNG, Oxford)
% Catharina Zich, Oxford, 6/5/19
% on Matlab 2018b
% get MCV

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

% KEYS
KbName('UnifyKeyNames');% Consistent mapping of keyCodes to key names on all operating systems.
escapeKey = KbName('ESCAPE');

%% -----------------------------------------------------------%
%                           PROMPT                            %
%-------------------------------------------------------------%

prompt = {'Subject Number:','Hand','MVF Attempt', 'Timepoint'};
dlgname = 'Run Information';
LineNo = 1;
default  =  {'0','L/R','1/2/3', 'pre/post'};
answer = inputdlg(prompt,dlgname,LineNo,default); % display dialog
[subj_num, hand, attempt, timepoint] = deal(answer{:}); % stores all subject answers in separate variables

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
%                      FIXATION CROSS                         %
%-------------------------------------------------------------%

% PROPERTIES
fixcrossLength = 20;
fixcrossWidth =5;

% COORDINATES
fixcrossLines = [ -fixcrossLength, 0;fixcrossLength, 0;0, -fixcrossLength;0, fixcrossLength ];
fixcrossLines = fixcrossLines';

%% -----------------------------------------------------------%
%                          TIMING                             %
%-------------------------------------------------------------%

% REFRESH RATE of monitor
ifi = Screen('GetFlipInterval', window);

% durations in seconds
force_duration = 3;  % duration of contraction
iti = 3;  % inter trial interval for fixation cross
frame=1;

%% -----------------------------------------------------------%
%                    INSTRUCTIONS                             %
%-------------------------------------------------------------%

% END OF EXPERIMENT TEXT
startText = 'Instrucitons here.';
finalText = 'You have completed the task. Thank you';
relaxText = 'RELAX';
taskText = 'CONTRACT';

% PROPERTIES
textSize= 20;
Screen('TextSize', window, textSize);
Screen('TextFont', window, 'Calibri');

%% -----------------------------------------------------------%
%                           FORCE                             %
%-------------------------------------------------------------%

% DEFINE VARIABLES FOR FORCE GRIP
force_gain = 1; % calibration gain factor in Newtons per ADC unit
force_offset = 0; % calibration intercept value in Newtons

% DEFINE NUMBER OF REPETITIONS
trialN=6;

%% -----------------------------------------------------------%
%                      EXPERIMENTAL LOOP                      %
%-------------------------------------------------------------%
% MOUSE
HideCursor;

% DSIPL INSTRUCTION
DrawFormattedText(window, startText, 'center', 'center', black);
Screen('Flip', window);
WaitSecs(2);
      
for n=1:trialN
    %vbl = Screen('Flip', window); % initial flip
    
    % Draw FIXATION CROSS FOR INTERTRIAL INTERVAL
    Screen('DrawLines',window,fixcrossLines,fixcrossWidth,black,[screenXcenter,screenYcenter-50])
    DrawFormattedText(window, relaxText, 'center', 'center', black);
    fixOn = Screen('Flip', window); 
    
    % Draw FIXATION CROSS FOR TASK INTERVAL
    Screen('DrawLines',window,fixcrossLines,fixcrossWidth,black,[screenXcenter,screenYcenter-50])
    DrawFormattedText(window, taskText, 'center', 'center', black);
    taskOn = Screen('Flip', window, fixOn + iti); 
    
    tic
    force_loc=[];
    while (1)
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
            ShowCursor;
            sca;
            return
        end %if
        
        % GET AND SCALE FORCE (single value)
        force_temp = SSQ_get_force(dyno) * force_gain + force_offset;
        
        % ADD INFO FROM CURRENT FLIP TO THE END OF MATRIX
        force_loc=[force_loc;force_temp];  
        
        if toc <=frame
            force_loc_ind(1)=size(force_loc,1);
        elseif toc <=force_duration-frame 
            force_loc_ind(2)=size(force_loc,1);
        elseif toc >=force_duration
            break;
        end
    end %while
    
    % HAND OVER FORCE FROM CURRENT REPETITION
    force_glob{n}=force_loc;
    force_glob_ind(n,:)=force_loc_ind;
end

sca;
clear Screen;
ShowCursor();

if ~isempty(dyno), fclose(dyno); end

%% -----------------------------------------------------------%
%                        VISUALIZATION                        %
%-------------------------------------------------------------%
figure('units','normalized','outerposition',[0 0 1 1]);
for n=1:length(force_glob)
    force_max_loc(n)=mean(force_glob{n}(force_glob_ind(n,1):force_glob_ind(n,2)));
    
    subplot(2,3,n); hold on;
    plot(force_glob{n},'k','Linewidth',2);
    plot([force_glob_ind(n,1) force_glob_ind(n,1)],[min(force_glob{n}) max(force_glob{n})],'g');
    plot([force_glob_ind(n,2) force_glob_ind(n,2)],[min(force_glob{n}) max(force_glob{n})],'g');
    plot([1 length(force_glob{n})],[force_max_loc(n) force_max_loc(n)],'r');
    grid on;
    axis tight;
    set(gca,'XTick',[force_glob_ind(n,:)]);
    set(gca,'XTickLabel',{'start eval','end eval'});
    xlabel('Time [samples]');ylabel('Force');
    title({['Repetition: ',num2str(n)],['Mean: ',num2str(force_max_loc(n))]},'interp','none');
end

good_trials=input('Input the Index of good Trials (e.g. [1,2,3]): ');
force_max_glob=mean(force_max_loc(good_trials));
%% -----------------------------------------------------------%
%                             SAVE                            %
%-------------------------------------------------------------%
cd(SCRIPTPATH);
save('calibration','force_max_glob');

filename = ['S',subj_num,'_', hand,'_MVF_',timepoint,'_',attempt,'_',datestr(datetime,'yymmdd')];
cd(PATHOUT);
save(filename,'force_glob','force_glob_ind','force_max_glob');
 
