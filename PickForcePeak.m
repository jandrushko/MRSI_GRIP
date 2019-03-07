function [mean_values] = PickForcePeak(force_data,dt)

% Function to pick boundaries of a force profile and then return the
% average of the middle portion of the profile.

% Inputs:
% -------
% force_data --> this is the force profile(s) to be analyzed. The routine
% expects data points to be in rows. Multiple force profiles can be
% analyzed if each one is a different column.

% dt --> sample time (i.e. 1/sample rate). This is needed if the window is
% to be expressed in seconds

% Output:
% -------
% mean_values --> vector of mean force values. One element for each input
% column.

% Created: March 6/2019 by J. Lanovaz
% Updated: March 6/2019
% =======================

% ------------------
% NEED TO SET THIS:
avg_window = 1.0; % averaging window size, in seconds
% ------------------

avg_window_n = round(avg_window / dt); % window size in data points

[numrows,numcolumns] = size(force_data); % finds size of input assuming each column is a separate force profile

h = figure; % opens figure

% Setting x-axis:
t = [0:(numrows-1)]';
t = t * dt;

% --------------------
% Main loop:
mean_values = [];
for c = 1:numcolumns
    
    % ----------------------------------
    % Loop to get data from each column:
    
    % Initializing loop:
    num_click = 0;
    click_index = [0 0];
    done = 0;
    while done == 0
        
        clf % clear figure
        plot(t,force_data(:,c)) % plot force profile
        hold on
        v = axis;
        
        % Darw a line for previous click point, if any:
        if num_click == 1
            line([click_index(1) click_index(1)],[v(3) v(4)],'color','k')
        end
        
        title(['Force data, column ' num2str(c) ' , Pick start and end values.'])
        
        % Get user input:
        [x,y,button] = ginput(1);
        num_click = num_click + 1;
        click_index(num_click) = x; % saves click point (note this is in seconds)
        
        % Check if first and last clicks are done (i.e. 2 clicks):
        if num_click == 2
            
            line([click_index(2) click_index(2)],[v(3) v(4)],'color','k') % draw second click line
            
            % Double check with user if all is well:
            button = questdlg('Is this correct?','Done?','Yes','No','Yes');
            if button(1:2) == 'Ye'
                done = 1; % all is good, exit while loop
            else
                num_click = 0; % not good, reset clicks
            end
            
        end
        
    end % end of while loop
    
    % Find midpoint between clicks:
    mid_point_time = mean(click_index);
    mid_point_n = round(mid_point_time / dt); % convert to index
    
    % Set averaging window:
    avg_start = mid_point_n - round(avg_window_n/2);
    avg_end = mid_point_n + round(avg_window_n/2);
    
    % Find mean value:
    mean_values = [mean_values; mean(force_data(avg_start:avg_end,c))];
    
end % end of column loop

close(h) % close figure

return
        
        
        
        
        
