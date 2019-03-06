%% SWR SQUEEZE TASK
%  Sebastian W Rieger, University of Oxford, December 2017 - for Stroke
%  Neurofeedback Study
%  Sebastian.Rieger@psych.ox.ac.uk


%   Adapted February 2 2019 by Melanie Flemming for Justin Andrushko
%   Ensure squeezetask_for_Justin.m SSQ_connect_dyno.m,
%   SSQ_direct_read_justin and SSQ_get_force.m are all in the same folder
%   prior to running

%   Running on Matlab R2017b
%   Need Psychtoolbox-3 (PTB-3) - http://psychtoolbox.org/download.html#alternate-download
%   version: 3.0.14 - Flavor: beta
%   Version Corresponds to SVN Revision 8424
%   To get PTB-3 version use >> UpdatePsychtoolbox(PsychtoolboxRoot, '8424')

%% Skip graphics tests
%  for debugging on Seb's Macbook. Remove from final version.
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0); clear;

%% Subject and setup specific parameters

force_gain = 1; % calibration gain factor in Newtons per ADC unit

%Specify force_offset, from SSQ direct read
%force_offset = 2; % calibration intercept value
force_offset_prompt = 'Input Force Offset Value: ';
force_offset = input(force_offset_prompt);

%Specify the participants MVF
%MVF = 50; % Maximum voluntary force (MVF)
MVF_prompt = 'Input MVF Value: ';
MVF = input(MVF_prompt);

%Specify the target force (e.g. 100 for fatigue, 5 for control)
%target_force = 75; % target marker, in percent of MVF
target_force_prompt = 'Input Target Force Value (Percent of MVF): ';
target_force_raw = input(target_force_prompt);
target_force_percentage = (target_force_raw/100) * MVF ;
target_force = target_force_percentage ;

%Specify the bar range e.g. 0-130% MVF for fatigue, 0-10%MVF for control

%Bar Minimum in Percentage of MVF
bar_min_prompt = 'Input Minimum Bar Value in Percentage(0 recommended): ';
bar_min_raw = input(bar_min_prompt);
bar_min_percentage = (bar_min_raw/100) * MVF ;
bar_min = bar_min_percentage ;

%Bar Maximum in Percentage of MVF
bar_max_prompt = 'Input Maximum Bar Value in Percentage(100 recommended): ';
bar_max_raw = input(bar_max_prompt);
bar_max_percentage = (bar_max_raw/100) * MVF ;
bar_max = bar_max_percentage ;

%Specify the duration that the squeeze should last for (in seconds)
%squeeze_duration= 5;

squeeze_duration_prompt = 'Input duration of contraction in seconds: ';
squeeze_duration = input(squeeze_duration_prompt);

%Specify fixation cross rest periods between trials
fixation_cross_prompt = 'Input duration of fixation cross rest period in seconds: ';
fixation_cross_duration = input(fixation_cross_prompt);

%% you don't need to change these
target_frequency = 0.5; % The frequency at which the target appears (Hz)
target_duty_cycle = 50; % Flashing target duty cycle in %
target_delay = 0; % Time in seconds between start of squeeze block and
% first appearance of target

dummy_scans = 0; % Number of scanner triggers to ignore at the start.
% Set this to the number of TRs that is closest to 5...7 seconds

%% Specify the type of scanner trigger (uncomment the relevant line):
scanner_trigger = 'space';
% scanner_trigger = '5';
% scanner_trigger = 'game';
% scanner_trigger = 'LPT'; LPT_address = hex2dec('379'); LPT_bit = 5;

%% Specify the sequence of conditions and onsets:

durations = [1 squeeze_duration fixation_cross_duration squeeze_duration fixation_cross_duration squeeze_duration fixation_cross_duration squeeze_duration fixation_cross_duration squeeze_duration]; %duration in seconds
conditions = {'cross'; 'feedback'; 'cross'; 'feedback'; 'cross'; 'feedback'; 'cross'; 'feedback'; 'cross'; 'feedback'};


%% Colours, font sizes, sizes of graphical elements, etc.:

font_size        = 6; % font size in % of screen height
text_col         = [0 0 0]; % colour of the text [red green blue]
screen_col       = [192 192 192]; % colour of the background
bar_col          = [0 0 255]; % colour of the bar graph
bar_bk_col       = [128 128 128]; % colour of the bar graph background
bar_height       = 90; % total bar graph height in % of display height
bar_width        = 16; % in percent of bar height
bar_scale        = [bar_min bar_max]; % range of the gauge in percent of MVF
target_col       = [255 255 0]; % color of the target marker
target_width     = 180; % width of target marker in % of bar graph width
target_linewidth = 8; % Line thickness of target in % of target width
cross_col        = [0 0 0]; % fixation cross colour
cross_size       = 8; % fixation cross size in % of display height
cross_linewidth  = 10; % fixation cross line width in % of its size


%% End of parameter block, start initialising:

%  log_filename = ['squeeze_log_' datestr(datetime(...
%      'now','Format','y_MM_d_HH_mm_SS'))];

Subject_number_prompt = 'Subject Number (##): ';
Subject_number = input(Subject_number_prompt); 
Trial_type_prompt = 'Input Condition (1 for Fatigue - 2 for Sham - 3 for Control): ';
Trial_type = input(Trial_type_prompt);
log_filename = ['S', sprintf('%02.0f',Subject_number),'_Condition_', num2str(Trial_type), '_', datestr(datetime,'yymmdd')];

% filename = 'savedVariable';
% log_filename = input('Save as: ', 's');
% log_filename = [log_filename, datestr(datetime,'yymmdd')];

try % The whole script sits inside try-catch block so we won't be stuck
    % with Psychtoolbox in full screen mode and an unresponsive keyboard
    % if a runtime error should occur.
    
    %% Try to connect to the squeeze-a-tron:
    dyno = SSQ_connect_dyno;
    
    %% Initialise parallel port, if present:
    % parport = SSQ_connect_parport;
    
    %% Try to connect to EEG system:
    % call to lab streaming layer initialisation here
    
    %% Initialise Psychtoolbox settings:
    % Make sure the system uses Psychtoolbox-3:
    AssertOpenGL;
    % Prevent key presses during the experiment from creating
    % unwanted text in the Matlab window or elsewhere:
    ListenChar(2);
    % Make sure this script will cope with different
    % keyboard types across platforms:
    KbName('UnifyKeyNames');
    % Define the keys that will be used:
    esc_key   = KbName('escape');
    enter_key = KbName('Return');
    five_key  = KbName('5%');
    space_key = KbName('space');
    game_key  = KbName('g'); 
    
    % Check how many displays are connected to this system:
    screens = Screen('Screens');
    i_screen = max(screens);
    
    % Create a graphics window (full screen for experiment,
    % smaller window for debugging):
    [ptb_window, ptb_win_size] = Screen('OpenWindow', ...
        i_screen, screen_col);
%     [ptb_window, ptb_win_size] = Screen('OpenWindow', i_screen, ...
%         screen_col, [600 100 1200 400]);

    % Get the coordinates of the window centre:
    [x0, y0] = RectCenter(ptb_win_size);
    
    % Calculate absolute sizes (in pixel) of graphics elements:
    font_size  = round(font_size * ptb_win_size(4) / 100);
    bar_height = round(bar_height * ptb_win_size(4) / 100);
    bar_width  = round(bar_width * bar_height / 100);
    target_force = target_force / diff(bar_scale) * bar_height;
    target_width = round(target_width * bar_width / 100);
    target_linewidth = round(target_linewidth * target_width / 100);
    cross_size = round(cross_size * ptb_win_size(4) / 100);
    cross_linewidth = round(cross_linewidth * cross_size / 100);
    
    % Set font size:
    Screen('TextSize', ptb_window, font_size);
    
    % Hide the mouse cursor:
    HideCursor;
    
    % Initialise variables
    force_list_Newtons = [];   %added by ZS to record force output 
    force_list_MVF = [];   %added by ZS to record force output 
    
    % Calculate onset times from the durations of the blocks:
    onsets = [0 cumsum(durations)];
    
    %% Display welcome message:
    
    welcome_message = ['The experiment is about to start.\n' ...
        'Please get ready to squeeze...\n' ];
    DrawFormattedText(ptb_window, welcome_message, 'center', 'center');
    Screen('Flip', ptb_window);
    
    
    %% Wait for scanner trigger, ignore dummy scans:
    
    switch scanner_trigger
        case 'space'
            while dummy_scans >= 0
                % Wait for a fresh (3) keypress on any (-1) of the keyboards:
                [MRI_start_time, keyCode, ~] = KbWait(-1, 3);
                keyCode = find(keyCode, 1);
                if keyCode == esc_key, error('Escape key pressed'); end
                if keyCode == space_key
                    dummy_scans = dummy_scans - 1;
                    Screen('FillRect', ptb_window, screen_col);
                    Screen('Flip', ptb_window);
                end
            end
        case '5'
            while dummy_scans >= 0
                % Wait for a fresh (3) keypress on any (-1) of the keyboards:
                [MRI_start_time, keyCode, ~] = KbWait(-1, 3);
                keyCode = find(keyCode, 1);
                if keyCode == esc_key, error('Escape key pressed'); end
                if keyCode == five_key
                    dummy_scans = dummy_scans - 1;
                    Screen('FillRect', ptb_window, screen_col);
                    Screen('Flip', ptb_window);
                end
            end
        case 'game'
            while dummy_scans >= 0
                % Wait for a fresh (3) keypress on any (-1) of the keyboards:
                [MRI_start_time, keyCode, ~] = KbWait(-1, 3);
                keyCode = find(keyCode, 1);
                if keyCode == esc_key, error('Escape key pressed'); end
                if keyCode == game_key
                    dummy_scans = dummy_scans - 1;
                    Screen('FillRect', ptb_window, screen_col);
                    Screen('Flip', ptb_window);
                end
            end
        case 'LPT'
            % initialise parallel port
            ioObj = io64();
            % check current TTL is low, set TTL last status flag
            old_TTL = bitget(io64(ioObj, LPT_address), LPT_bit);
            if old_TTL == 1
                error('Detected logic 1 on TTL in, when it should be 0.'); 
            end
            while dummy_scans >= 0
                
                % check for ESC
                [~, keyCode, ~] = KbCheck(-1, 3);
                keyCode = find(keyCode, 1);
                if keyCode == esc_key, error('Escape key pressed'); end
                % Check LPT status, set TTL current status flag
                
                % Detect rising edge, decrement counter:
                if old_TTL == 0 && new_TTL == 1 
                    dummy_scans = dummy_scans - 1;
                    Screen('FillRect', ptb_window, screen_col);
                    Screen('Flip', ptb_window);
                end
            end
    end
    
    
    
    
    
    
    
    %% Main experiment loop:
    %  Initialise loop counter variable:
    i_condition = 1;
    %  Loop until the last block has ended:
    
    while GetSecs <= MRI_start_time + onsets(end)
        
        % Increase condition counter if the next onset time has been
        % reached:
        if GetSecs >= MRI_start_time + onsets(i_condition + 1)
            i_condition = i_condition + 1;
        end
        
        % Exit the loop if the end of the list of conditions has been
        % reached:
        if i_condition > numel(conditions), break; end
        
        
        % Draw on screen depending on current condition:
        switch conditions{i_condition}
            
            case 'blank'
                Screen('FillRect', ptb_window, screen_col);
                Screen('Flip', ptb_window);
                
            case 'cross'
                %  Draw fixation cross
                Screen('FillRect', ptb_window, cross_col, [ ...
                    x0 - cross_size/2, ...   % left
                    y0 - cross_linewidth/2, ...  % top
                    x0 + cross_size/2, ...   % right
                    y0 + cross_linewidth/2]);    % bottom
                Screen('FillRect', ptb_window, cross_col, [ ...
                    x0 - cross_linewidth/2, ...   % left
                    y0 - cross_size/2, ...  % top
                    x0 + cross_linewidth/2, ...   % right
                    y0 + cross_size/2]);    % bottom
                Screen('Flip', ptb_window);
                
             
            case 'feedback'
                % Get force reading and convert from ADC units to Newtons:
                %%%%%keyboard
                force = SSQ_get_force(dyno) * force_gain + force_offset;
                
                force_list_Newtons = [force_list_Newtons; GetSecs - MRI_start_time force]; %#ok<AGROW>
                
                % Convert force value from Newtons to % of MVF:
                force = force / MVF * 100;
                
                force_list_MVF = [force_list_MVF; GetSecs - MRI_start_time force]; %#ok<AGROW>

                % Convert force from %MVF to pixels:
                force = force / diff(bar_scale) * bar_height;
                % Prevent the force diplay from going "off the scale":
                if force > bar_height, force = bar_height; end
                if force < 0, force = 0; end
                %  Draw background bar
                Screen('FillRect', ptb_window, bar_bk_col, [ ...
                    x0 - bar_width/2, ...   % left
                    y0 - bar_height/2, ...  % top
                    x0 + bar_width/2, ...   % right
                    y0 + bar_height/2]);    % bottom
                               
                % Draw force bar
                Screen('FillRect', ptb_window, bar_col, [ ...
                    x0 - bar_width/2, ...
                    y0 + bar_height/2 - force, ...
                    x0 + bar_width/2, ...
                    y0 + bar_height/2]);
                
                % Draw target marker, if appropriate:
                if (GetSecs >= MRI_start_time + onsets(i_condition) + target_delay) && ...
                        (mod(GetSecs - MRI_start_time - onsets(i_condition) + target_delay, ...
                        1/target_frequency) < 1/target_frequency * target_duty_cycle / 100) && ...
                        GetSecs - MRI_start_time + 1/target_frequency * target_duty_cycle / 100 < onsets(i_condition + 1)
                    Screen('FillRect', ptb_window, target_col, [ ...
                        x0 - target_width/2, ...
                        y0 + bar_height/2 - target_force - target_linewidth/2, ...
                        x0 + target_width/2, ...
                        y0 + bar_height/2 - target_force + target_linewidth/2]);
                end
                Screen('Flip', ptb_window);
                
        end
        
        
        
        [ keyIsDown, seconds, keyCode ] = KbCheck(-1);
        keyCode = find(keyCode, 1);
        % If the user is pressing a key, then display its code
        % number and name.
        if keyIsDown
            % Note that we use find(keyCode) because keyCode is an array.
            % See 'help KbCheck'
            % fprintf('You pressed key %i which is %s\n', keyCode, ...
            % KbName(keyCode));
            if keyCode == esc_key
                error('Escape key pressed');
            end
            % If the user holds down a key, KbCheck will report multiple
            % events. To condense multiple 'keyDown' events into a single
            % event, we wait until all keys have been released.
            %             KbReleaseWait;
        end
    end
    
    
        %% Display end message and wait for ESC key press:
    
        end_message = 'Task complete - Thank you!';
    DrawFormattedText(ptb_window, end_message, 'center', 'center');
    Screen('Flip', ptb_window);
 
                while 1
                % Wait for a fresh (3) keypress on any (-1) of the keyboards:
                [~, keyCode, ~] = KbWait(-1, 3);
                keyCode = find(keyCode, 1);
                if keyCode == esc_key, break; end
                end
    
    
    
    
    %% Cleanup:
    
catch
    ListenChar(0);
    sca;
    if ~isempty(dyno), fclose(dyno); end
    save(log_filename, 'conditions', 'onsets', 'durations', 'force_list_Newtons', 'force_list_MVF');
    rethrow(lasterror); %#ok<LERR>
    
end
ListenChar(0);
sca;
if ~isempty(dyno), fclose(dyno); end
save(log_filename, 'conditions', 'onsets', 'durations', 'force_list_Newtons', 'force_list_MVF');

%Plot force curve
plot(force_list_MVF(:,2))



