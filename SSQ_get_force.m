function force = SSQ_get_force(port_object)

%keyboard;
if ~isempty(port_object)
    fprintf(port_object, 'r');
    response = fgetl(port_object);
    %force = sscanf(response, '%*s%*d%d');
    parts=strsplit(response);
    force=str2num(parts{3});
else
    % The port object is empty, which means the dyno is not connected.
    % Return the seconds of the time of day instead - this is so the main
    % script can be developed and debugged without the dyno connected.
    time = clock;
    force = round(abs(rem(time(6),2)-1)*88)-5;
end


