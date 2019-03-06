function port_object = SSQ_connect_dyno(device_id, query_string)

%% Check for function call arguments

% If a device identification string was not specified when this function
% was called, use a default:
if nargin < 1
    device_id = 'Gripper: v';
    % (This string is part of the squeezymajig's response when queried for
    % the software version, e.g. "v	    Gripper: v1.1.1". We use this to
    % check if we are talking to the right device.)
end

% If a device identification query string was not specified when this
% function was called, use a default:
if nargin < 2
    query_string = 'v';
    % (This command queries the squeezymajig for the software version.)
end

%% Try to find the device on the available serial ports

% Delete existing serial port connections (this deals with orphaned
% connections from previous attempts, and connections not closed properly
% due to crashes):
delete(instrfindall);
% NB: This might interfere with the functioning of unrelated devices that
% use serial ports. Hopefully this won't be a problem on our PCs. If it is,
% use a more targeted approach than "delete all you can find".

% Find all the serial connections that exist on this system:
display('Looking for serial ports...');
try
    serial_ports = instrhwinfo('serial');
    serial_ports = serial_ports.SerialPorts;
catch
    serial_ports = instrfindall; %%%%%%%% Need this because instrhwinfo doesn't exist in Matlab 2014 - not sure how this is going to work yet
end
display(['Found ' num2str(numel(serial_ports)) ...
    ' serial ports on this system.']);
        
% Return an empty object if there are no serial ports:
if numel(serial_ports) == 0, port_object = []; end

% Try to connect to the ports one by one until the right device is found:
for i_port = 1 : numel(serial_ports)
    try
        % Try to connect to port:
        display(['Trying to connect to serial port ' num2str(i_port) ...
            ' of ' num2str(numel(serial_ports))]);
        port_object = serial(serial_ports{i_port}); %#ok<TNMLP>
        % Set a short timeout so it won't take forever to scan all the
        % ports on a system for the presence of a squeezy doodah:
        port_object.Timeout = 1;
        % Try to open the port:
        fopen(port_object);
        % Try to talk to the device at this port:
        %         % send break command in case it's busy:
        %         fprintf(port_object, 'b');
        %         % clear input buffer from any stale data:
        %         flushinput(port_object);
        % Ask for version (to identify device):
        fprintf(port_object, query_string);
        % Read response from device
        response = fgetl(port_object);
        %         display(['Response: ' response]);
        % Check if the device has replied with a Gripper software version
        % number, or whatever else has been specified in the function call:
        if strfind(response, device_id)
            % the connected device is a teensy grip force device
            % so stop looking and exit the for loop
            display('Device ID match!');
            break
        else
            % the connected device is something else, so close the
            % connection and keep looking
            display(['There does not seem to be a grip force device '...
                'on this port. Closing port...']);
            fclose(port_object);
            % If we can't find the device, return an empty value:
            port_object = [];
        end
    catch
        % failed to connect to this port, try the next one
        display('Error occured. Going to try next port...');
        % If we can't find the device, return an empty value:
        port_object = [];
    end
end


