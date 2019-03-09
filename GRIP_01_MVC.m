% Project name: MRSI_GRIP 
% Project owner: Justin Andrushko (PiNG, Oxford)
% Catharina Zich, Oxford, 6/5/19
% on Matlab 2018b
% get MVC

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

prompt = {'Subject Number:','Hand','Timepoint'};
dlgname = 'Run Information';
LineNo = 1;
default  =  {'0','L-R','pre-post'};
answer = inputdlg(prompt,dlgname,LineNo,default); % display dialog
[subj_num, hand, timepoint] = deal(answer{:}); % stores all subject answers in separate variables

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

% REFRESH RATE OF MONITOR
ifi = Screen('GetFlipInterval', window);

force_duration = 3;  % all durations in secs
interval_duration = [1 3 3];  % inter trial interval for fixation cross
prep_duration = 1; % prep cue
frame_duration=1;
% DEFINE NUMBER OF REPETITIONS
number_of_trials=3;

%% -----------------------------------------------------------%
%                    INSTRUCTIONS                             %
%-------------------------------------------------------------%

text_start = 'Instrucitons here.';
text_final = 'You have completed the task. Thank you';
text_relax = 'RELAX';
text_task = 'CONTRACT';
text_prep = 'PREPARE';

text_size= 20;
Screen('TextSize', window, text_size);
Screen('TextFont', window, 'Calibri');

%% -----------------------------------------------------------%
%                      EXPERIMENTAL LOOP                      %
%-------------------------------------------------------------%
HideCursor; %hide mouse when experiment is on

% DSIPLAY INSTRUCTIONS
DrawFormattedText(window, text_start, 'center', 'center', black);
Screen('Flip', window);
WaitSecs(2);
      
for n=1:number_of_trials   
    % Draw FIXATION CROSS
    Screen('DrawLines',window,fixcrossLines,fixcrossWidth,orange,[screenXcenter,screenYcenter-50])
    DrawFormattedText(window, text_relax, 'center', 'center', black);
    fixOn = Screen('Flip', window); 
    
    % RECORD FORCE DURING REST TO DETERMINE OFFSET 
    tic
    base_loc=[];
    while (1)
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode(escapeKey) % allows to stop experiment is esc is pressed
            ShowCursor;
            sca;
            return
        end %if
        
        % GET FORCE (single value)
        base_temp = SSQ_get_force(dyno);
        
        % ADD INFO FROM CURRENT FLIP TO THE END OF MATRIX
        base_loc=[base_loc;base_temp];  
        
        if toc >=interval_duration(n)
            break;
        end
    end
    
    % Draw FIXATION CROSS FOR PREP INTERVAL
    Screen('DrawLines',window,fixcrossLines,fixcrossWidth,black,[screenXcenter,screenYcenter-50])
    DrawFormattedText(window, text_prep, 'center', 'center', black);
    prepOn = Screen('Flip', window, fixOn + prep_duration); 
    
    % Draw FIXATION CROSS FOR CONTRACTION INTERVAL
    Screen('DrawLines',window,fixcrossLines,fixcrossWidth,green,[screenXcenter,screenYcenter-50])
    DrawFormattedText(window, text_task, 'center', 'center', black);
    taskOn = Screen('Flip', window, prepOn + interval_duration(n)); 
    
    % RECORD FORCE DURING CONTRACTION 
    tic
    force_loc=[];
    while (1)
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
            ShowCursor;
            sca;
            return
        end %if
        
        % GET FORCE (single value)
        force_temp = SSQ_get_force(dyno);
        
        % ADD INFO FROM CURRENT FLIP TO THE END OF MATRIX
        force_loc=[force_loc;force_temp];  
        
        if toc <=frame_duration
            force_loc_ind(1)=size(force_loc,1);
        elseif toc <=force_duration-frame_duration 
            force_loc_ind(2)=size(force_loc,1);
        elseif toc >=force_duration
            break;
        end
    end %while
    
    % HAND OVER FORCE FROM CURRENT REPETITION
    base_glob{n}=base_loc;
    force_glob{n}=force_loc;
    force_glob_ind(n,:)=force_loc_ind;
end

% DSIPLAY FINAL TEXT
DrawFormattedText(window, text_final, 'center', 'center', black);
Screen('Flip', window);
WaitSecs(2);

sca;
clear Screen;
ShowCursor();

if ~isempty(dyno), fclose(dyno); end

%% -----------------------------------------------------------%
%                        VISUALIZATION                        %
%-------------------------------------------------------------%
figure('units','normalized','outerposition',[0 0 1 1]);
for n=1:length(force_glob)    
    % SMOOTH FORCE
    Span=100;
    force_glob{n}=smoothdata(force_glob{n},Span,'sgolay');
    % GET MAX
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
    
    % GET 'OFFSET'
    base_mean_loc(n)=median(base_glob{n});
end

good_trials=input('Input the Index of good Trials (e.g. [1 2 3]): ');
force_max_glob=mean(force_max_loc(good_trials));
base_mean_glob=mean(base_mean_loc);
%% -----------------------------------------------------------%
%                             SAVE                            %
%-------------------------------------------------------------%
cd(SCRIPTPATH);
save('calibration','force_max_glob','base_mean_glob');

filename = ['S',subj_num,'_', hand,'_MVC_',timepoint,'_',datestr(datetime)];
cd(PATHOUT);
save(filename,'force_glob','force_glob_ind','force_max_glob');
 
