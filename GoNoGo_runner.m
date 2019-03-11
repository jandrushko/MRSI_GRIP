
clear all
close all
clc

if ismac cd ('/Users/manowak/Desktop/TMS_tACS_MN');
    addpath ('/Users/manowak/Desktop/TMS_tACS_MN');

else
    cd ('D:\Experiments\TMS_tACS_MN')
    addpath(pwd)
end

addpath('./Toolbox');
addpath('./Images');
    

nblocks = 1;

argindlg = inputdlg({'Subject number','Gender','Age','Handedness','isMEG? (true/false)', 'isEyelinked? (true/false)', 'isPractice? (true/false)' },'',1);
if isempty(argindlg)
    error('Experiment cancelled.');
end

participant = struct;
participant.isub = str2num(argindlg{1});
participant.gender = argindlg{2};
participant.age = argindlg{3};
participant.handedness = argindlg{4};

if ~isempty(argindlg{5}) && ismember(argindlg{5},{'true','false'})
    participant.isMEG = str2num(argindlg{5});
else
    error('Use MEG (true/false)?');
end

if ~isempty(argindlg{6}) && ismember(argindlg{6},{'true','false'})
    participant.isEyelinked = str2num(argindlg{6});
else
    error('Use Eyelink (true/false)?');
end

if ~isempty(argindlg{7}) && ismember(argindlg{7},{'true','false'})
    participant.isPractice = str2num(argindlg{7});
    practice = participant.isPractice
else
    error('Is Practice (true/false)?');
end

clear trlinfo

trlinfo.driftcorrectfreq=200; % how often to do drift correction in eye tracker (if being used)
trlinfo.doTrigs = 0; % send trigger codes to EEG/MRI?

clear timings;
timings.cueDuration = 0.20; % duration cue is on-screen (seconds)
timings.CueTargetISIDuration = [1]; % cue target ISI (should vary!)
timings.targetDuration = 0.20; % target duration (seconds)

%Delete RT? I have EMG
timings.movementTime=[2,2.5,3,3.5,4]; % maximum RT (in seconds) allowed for responses NEW
trlinfo.timings = timings;

if practice == 1
    trlinfo.icue        = [1 1 1 1 1  1 1 1 1 1]; 
    trlinfo.gonogo      = [1 1 1 1 2  1 1 1 1 2]; % 1 - Go; 2 - NoGo
    trlinfo.icodes      = [1 1 1 1 2  1 1 1 1 2]; % trigger codes 1 - Go; 2 - NoGo
    
% elseif practice == 0
%     
%     trlinfo.icue       = [1 1 1 1 1   1 1 1 1 1   1 1 1 1 1  1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1  1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1] % 1 - Go; 2 - NoGo
%     trlinfo.gonogo     = [1 1 1 1 2   1 1 1 1 2   1 1 1 1 2  1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2  1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2] % Go/NoGo
%     trlinfo.icodes     = [1 1 1 1 2   1 1 1 1 2   1 1 1 1 2  1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2  1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2] % trigger codes
%             
% end

elseif practice == 0
    
    trlinfo.icue       = [1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1     1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1     1 1 1 1 1     1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1     1 1 1 1 1     1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1     1 1 1 1 1     1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1     1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1     1 1 1 1 1     1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1     1 1 1 1 1     1 1 1 1 1   1 1 1 1 1   1 1 1 1 1   1 1 1 1 1     1 1 1 1 1] % 1 - Go; 2 - NoGo
    trlinfo.gonogo     = [1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2] % Go/NoGo
    trlinfo.icodes     = [1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2     1 1 1 1 2   1 1 1 1 2   1 1 1 1 2   1 1 1 1 2     1 1 1 1 2] % trigger codes
            
end

ntrials = length(trlinfo.icue);
trlinfo.ntrials = ntrials

% Need to display go/nogo at random...
iperm = randperm(ntrials);
trlinfo.icue      = trlinfo.icue(iperm);
trlinfo.gonogo    = trlinfo.gonogo(iperm);
trlinfo.icodes    = trlinfo.icodes(iperm);


%%
[timestamps] = GoNoGo(participant.isub,participant.isEyelinked, participant.isMEG, trlinfo, participant.isPractice);

participant.filename = sprintf('GoNoGo_S%d_%s',participant.isub,datestr(now,'yyyymmdd-HHMM'));

save(fullfile(cd,'Data',[participant.filename,'.mat']),'participant','trlinfo','timestamps');

if participant.isMEG
    if isEyelinked
        if exist('gonogoeye.edf','file')
            movefile('gonogo.edf',fullfile(cd,'Data',[participant.filename,'.edf']));
        else
            error('Eye-tracker data file not found!');
        end
    end
end