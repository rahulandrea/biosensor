%% PROJECT SETUP
%
%   exit code
%       0  -  all tests passed
%       4  -  Rbeast setup failed
%       5  -  ddindd failed
%
disp("[INFO][setup] Starting environment test ...");
y   = sin((1:100)/10);  % dummy data

%% RBEAST
try
    result = beast(y);
    disp('[✓][setup] Rbeast installed and running');
catch ME
    disp('[✗][setup] Rbeast failed:');
    disp(ME.message);
    exit(4);
end

%% DDINDD
try
    addpath('ddindd');  % relative path inside the Docker image (/matlab/ddindd)

    % optional test call
    ddindd(y);  % Wenn Argumente benötigt werden, hier entsprechend anpassen
    disp('[✓][setup] ddindd ran successfully');
catch ME
    disp('[✗][setup] ddindd failed:');
    disp(ME.message);
    exit(1);
end

disp('[INFO][setup] All checks passed.');
exit(0);