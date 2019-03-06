%SSQ_direct_read edited by Caroline Nettekoven for Justin Andrushko
% Added save function for further post-processing and analysis of MVF
% Added Save as function to create desired file names

clear all

force_gain = 1; % calibration gain factor in Newtons per ADC unit
force_offset = 0; % calibration intercept value in Newtons

dyno = SSQ_connect_dyno;

% filename = 'savedVariable';
Subject_number_prompt = 'Subject Number (##): ';
Subject_number = input(Subject_number_prompt); 
Hand_prompt = 'Left or Right hand (Input L or R): ';
Hand = input(Hand_prompt, 's');
Trial_number_prompt = 'MVF Attempt #: ';
Trial_number = input(Trial_number_prompt);
Pre_post_task_prompt = 'Is this MVF before or after the task (Input Pre or Post): ';
Pre_post_task = input(Pre_post_task_prompt, 's');
filename = ['S', sprintf('%02.0f',Subject_number),'_', Hand,'_MVF_', num2str(Trial_number),'_', Pre_post_task,'_', datestr(datetime,'yymmdd')];

% Subject_number_prompt = 'Subject Number (##): ', 's';
% Subject_number = input(Subject_number_prompt) 
% Trial_number_prompt = 'MVF Attempt #: ', 's';
% Trial_number = input(Trial_number_prompt)
% filename = ['S', num2str(Subject_number),'_MVF_', num2str(Trial_number), '_', datestr(datetime,'yymmdd')];

force = SSQ_get_force(dyno) * force_gain + force_offset;
force_old = force;
force_max = force;
display(['Current value: ' num2str(force), ' / maximum: ' ...
    num2str(force_max)]);
newVariable = [];

%%
while 1
    
    force = SSQ_get_force(dyno) * force_gain + force_offset;
    
    if force > force_max, force_max = force; end
    
    if force ~= force_old
        display(['Current value: ' num2str(force), ' / maximum: ' ...
            num2str(force_max)]);
        values = [(force) (force_max)];
        newVariable = vertcat(newVariable, values);
        force_old = force;
    end
    [keyIsDown, seconds, keyCode] = KbCheck(-1);
    if keyIsDown, break; end
    datapath = 'C:\Users\jandr\Documents\MATLAB\Data';  %change to desired save location
    save(fullfile(datapath, filename), 'newVariable');
    
end
%%
sprintf('Saved file as : %s', fullfile(datapath, filename))
if ~isempty(dyno), fclose(dyno); end

%Plot Force Curve
plot(newVariable(:,1))

%Plot Max Force 
%plot(newVariable(:,2))