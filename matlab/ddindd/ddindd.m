% Run 'help ddindd' to see the following:
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <strong>USAGE: out = ddindd(data, varargin)</strong>
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   <strong>data:</strong> table of raw sensor data in the export format
%
%   <strong>varargin:</strong> series of paired keywords and values (input
%       as key-value or name-value possible) to specify the analysis and
%       add metadata
%
%       <strong>ddindd( 201253_25112022, method = 'langmuir' )</strong>
%       <strong>ddindd( 201253_25112022 )</strong> % same as above (as this uses default method = 'langmuir')
%       <strong>ddindd( 221029_17032023, 'method', 'langmuir', 'metaFile', '221029_17032023_json', 'relInj', 0)</strong>
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <strong>Possible Keywords:</strong>
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   <strong>method:</strong>
%        character (from {'langmuir', 'linear', ..}); sets the method of
%        anaylsis i.e. the function for the fit; default = 'langmuir'
%        -> -> -> Support for own functions will be added
%
%   <strong>metaFile:</strong>
%        struct (from jsondecode()); sets source for meta data. use the meta
%        data template for the right format of the JSON file; default = NaN
%
%   <strong>relInj:</strong>
%        integer; sets the relevant injection type; default = 0 (negative
%        sample injection)
%
%   <strong>irrInj:</strong>
%        integer; set the irrelevant injection type, i.e. the one to
%        delete; default = NaN
%        -> -> -> Use of this keyword is not recommended
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <strong>Result/Output:</strong>
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   <strong>out:</strong> struct; contains the following fields:
%
%       <strong>raw:</strong> table; raw data table with added columns for
%       round and injection type
%                  
%       <strong>meta:</strong> struct; holds meta data; contains the
%       following fields:
%
%           <strong>shortFileId:</strong> string; short file id
%
%           <strong>dateStr:</strong> string; file date
%
%           <strong>type:</strong> character; to recognize type of struct,
%           should be 'ddindd'; default = 'ddindd'
%
%           <strong>raw_name:</strong> string; name of raw file
%
%           <strong>origin_file_id:</strong> string; id of origin file
%
%           <strong>method:</strong> character; function that was used for
%           fit; default = 'langmuir'
%
%           <strong>methodFunc:</strong> function handle; matlab function
%           handle of fit function in method; default = @(a, b, t) b * (1 - exp(-a * t))
%
%           <strong>methodEx:</strong> character; example of fit function
%           in method; default = 'b*(1 - exp(-a * t))' (from 'langmuir')
%           
%           <strong>injections:</strong> cell array; all injections, aka
%           'inj_type' in raw data table
%
%           <strong>irrInj:</strong> integer; irrelevant injection type;
%           default = NaN
%
%           <strong>relInj:</strong> integer; relevant injection type;
%           default = 0 (negative sample injection)
%       
%           <strong>n_rounds:</strong> integer; # of rounds
%
%           <strong>n_sensors:</strong> integer; # of sensors; always 8
%
%       <strong>round{r}:</strong> struct; holds information to round #r;
%       contains the following fields:
%
%           <strong>sensor{s}:</strong> struct; holds information to sensor
%           #s in round #r; contains the following fields:
%
%               <strong>y:</strong> cell array; raw data from sensor;
%
%               <strong>strVal:</strong> double; starting value from raw
%               data array (for corrections to 0)
%           
%               <strong>driftSP:</strong> integer; starting point of drift
%               (beginn of reaction)
%
%               <strong>SPcorr:</strong> double; y value @ driftSP;
%               correction to set SP to 0
%
%               <strong>a:</strong> double; optimized a for fit function
%
%               <strong>b:</strong> double; optimized b for fit function
%
%               <strong>Rsquared:</strong> double; R^2 for fit optimized
%               with the parameters above
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <strong>Further functions:</strong>
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   
%   <strong>printddindd:</strong> prints summary of the ddindd output
%   struct
%
%   <strong>plotddindd:</strong> plots summary of the ddindd output struct
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <strong>Examples:</strong>
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   % analyze 201253_25112022 file w/ langmuir
%
%   1  data = readtable( '201253_25112022.csv', Delimiter = ',' );
%   2  json_metadata = jsondecode( fileread( '201253_25112022.json' ) );
%   3  d = ddindd(data, 'method', 'langmuir', 'metaFile', 'json_metadata', 'relInj', 2);
%   4  printddindd(d);
%   5  plotddindd(d);
%
%   <strong>Injection types:</strong>
%       0  --  negative  
%       1  --  positive
%       3  --  puffer
%       4  --  urea
%       9  --  unknown
%
%   See also PRINTDDINDD, PLOTDDINDD, TABLEDDINDD
%
%   2025; Rahul Gandbhir; University of Basel, Physics Department, Nanolino Group;
%
function out = ddindd(data, varargin)
%% ddindd: analyize data and create struct with results
%
% Args:
%       data (table): raw data
%       
%   optional:
%       method (char): which function for fit (default = 'langmuir')
%       metaFile (struct): output struct from jsondecode() (default = NaN)
%       relInj (int): relevant injection (default = 0)
%       irrInj (int): irrelevant injection (default = NaN)
%
% Returns:
%       out (struct): struct with metadata and analysis results
%
%% parse second argument (option parameter)
n = length(varargin);
    if mod(n,2) ~= 0
        error("[ERROR][input parsing] optional arg list must be paired keywords and values. # of extra args must be even.");
    end

KeyList = varargin(1:2:n);
KeyList = cellfun(@char,KeyList,'UniformOutput',false); % convert strings to chars
KeyList = lower(KeyList);
ValList = varargin(2:2:n);

%% get values from keys. last arg is default value if the key is missing from varagin/KeyList

method   = GetValueByKey(KeyList, ValList, 'method', 'langmuir');
metaFile = GetValueByKey(KeyList, ValList, 'metaFile', NaN);
relInj   = GetValueByKey(KeyList, ValList, 'relInj', 0);
irrInj   = GetValueByKey(KeyList, ValList, 'irrInj', NaN);

%% extract metadata form metadata file
out.meta.type = 'ddindd'; % save in output struct

if isnumeric(metaFile) && isnan(metaFile) % with && the second condition gets checked only if the first one is true (no error of metaFile is struct)
    return;
else
    out.meta.shortFileId    = GetValue(metaFile, 'short_file_id', "NaN"); % save in output struct %% short file id
    out.meta.dateStr        = GetValue(metaFile, 'date', "0000-00-00"); % save in output struct %% date string

    out.meta.raw_name       = GetValue(metaFile, 'raw', "");
    out.meta.origin_file_id = GetValue(metaFile, 'raw', "");

    injections              = GetValue(metaFile, 'injections', []);
    out.meta.injections     = injections; % save in output struct %% all injections

    rounds                  = GetValue(metaFile, 'rounds', []);
end

%% prepare data and set metadata

% set fit type
switch lower(method) 
    case 'langmuir'
        funcEx      = 'b*(1 - exp(-a * t))';
        func        = @(a, b, t) b * (1 - exp(-a * t));
        ft          = fittype(funcEx, independent = 't', coefficients = {'a', 'b'}); %% Langmuir b*(1-e^(-a*t))
    case 'linear'
        funcEx      = 'a*t + b';
        func        = @(a, b, t) a*t + b;
        ft          = fittype(funcEx, independent = 't', coefficients = {'a', 'b'}); %% Linear %% TODO
    otherwise % default case
        method      = 'langmuir';
        funcEx      = 'b*(1 - exp(-a * t))';
        func        = @(a, b, t) b * (1 - exp(-a * t));
        ft          = fittype(funcEx, independent = 't', coefficients = {'a', 'b'}); %% Langmuir b*(1-e^(-a*t))
end

out.meta.method = lower(method); % save in output struct
out.meta.methodFunc = func;
out.meta.methodEx = funcEx;

% delete irrInj
if relInj == irrInj % protect relInj
    disp("[WARNING][input parsing] relevant injections is same as irrelevant injection. handling by keeping both")
    out.meta.irrInj = NaN; % save in output struct
else
    data = data(~ismember(data.Val_, irrInj), :);
    out.meta.irrInj = lower(irrInj); % save in output struct
end

out.meta.relInj = relInj; % save in output struct

% create inj_type column
inj_type = 8 * ones(height(data), 1); % default: 8 %% error type
for i = 1:length(injections)
    inj_type(data.("Inj_") == i) = injections(i);
end
data.inj_type = inj_type;

% get # of rounds and create round column
if length(injections) == length(rounds) %%% && length(rounds) == numel(unique(data.("Inj_")))   
    round               = zeros(height(data), 1); % default: 0%% error type
    for i = 1:length(rounds)
        round(data.("Inj_") == i) = rounds(i);
    end
    data.round          = round;
    n_rounds            = numel(unique(rounds));
    out.meta.n_rounds   = n_rounds; % save in output struct
else
    disp("[WARNING][input parsing] No rounds in meta data. Automatic round detection could lead to problems.")
    not_one = data.Val_ ~= 1; one_before = [false; data.Val_(1:end-1) == 1];
    n_rounds = sum(not_one & one_before);
    out.meta.n_rounds = n_rounds; % save in output struct meta data

    round = 0 * ones(height(data), 1);  % default: 0
    for i = 1:n_rounds
        round(data.("Inj_") > (i-1)*3 + 1 & data.("Inj_") < i*3 + 1) = i;
    end
    data.round = round;
end

% set # of sensors
n_sensors = 8;
out.meta.n_sensors = n_sensors; % save in output struct meta data

out.raw = data; % save in output struct raw data

%% find drift

for r = 1:n_rounds
    roundName = ['round' num2str(r)]; % for naming in output struct
    
    D = data(data.round == r & data.inj_type == relInj, :); % filter data for round and inj type
    if isempty(D)
        disp("[WARNING][func fit] No matching data for round " + r + " and injection type " + GetInjectionType(relInj));
        n_rounds = n_rounds - 1; out.meta.n_rounds = n_rounds; 
        return;
    end
    
    for s = 1:n_sensors
        sensorName = ['sensor' num2str(s)]; % for naming in output struct
        
        y = D{:, s+4}; % filter data for sensor and subtract first 20 measurement points (ca. 100s)
        strVal = y(1); % starting value (for correction)

        cpt = 20;

        y_fit = y(cpt:end); % part on which we want to fit the model function
        y_fit = y_fit - y_fit(1); % set starting value to 0
        t_rel = (1:length(y_fit))'; % relative time vector on that part

        if length(y_fit) > 10 % minmum requirement to fit model function
            a0 = 1 / mean(t_rel(end)); b0 = max(y_fit); % chose starting points for optimization
            opts = fitoptions(Method = 'NonlinearLeastSquares', StartPoint = [a0, b0], Lower = [0, 0]); % define parameters for fit
            [fitted_model, gof] = fit(t_rel, y_fit, ft, opts); % fit model
            opt_a = fitted_model.a; opt_b = fitted_model.b; r2 = gof.rsquare; % save function parameters for fit
        else
            disp("[INFO][func fit (round: " + r + "sensor: " + s + ")] No fitting possible. Array is to short.")
            opt_a = NaN; opt_b = NaN; r2 = NaN; % dummy vars
        end
        
        % save array and strVal in struct
        out.(roundName).(sensorName).y = y;
        out.(roundName).(sensorName).strVal = strVal;

        % save all in output struct
        out.(roundName).(sensorName).driftSP = cpt;
        out.(roundName).(sensorName).SPcorr = y(cpt);
        out.(roundName).(sensorName).a = opt_a;
        out.(roundName).(sensorName).b = opt_b;
        out.(roundName).(sensorName).Rsquared = r2;
    end

end
end

%% GetValue: get value from struct or, if not available, set default
%
% Args:
%       s (struct): struct where input is from
%       path (char): path to relevant struct field ex.: 'path1.path2'}
%       defaultValue (any): default value, if value from struct not available
%
% Returns:
%       value (any): value to use
%
function value = GetValue(s, path, defaultValue)
    keys = strsplit(path, '.');
    try
        value = getfield(s, keys{:});
    catch
        value = defaultValue;
    end
end

%% GetValueByKey: return default value if field is missing from opt
%
% Args:
%       KeyList (cell): List of keys from varargin input
%       ValList (cell): List of values from varargin input
%       key (char): name of key
%       defaultValue (any): default value (if no val in ValList)
%
% Result:
%       value (any): from ValList if available, else defaultValue
%
function value = GetValueByKey(KeyList, ValList, key, defaultValue)
   idx = find(strcmp(KeyList,lower(key)));
   if isempty(idx)
       value = defaultValue;
   else
       value = ValList{idx(1)};
   end
end

%% GetInjectionType: Return injection type
%
% Args:
%       i (int): injection type integer
%
% Result:
%       inj_type (string): injection type string
%
function inj_type = GetInjectionType(i)
    switch i
        case 0
            inj_type = "Negative sample";
        case 1
            inj_type = "Positive sample";
        case 3
            inj_type = "Flush";
        case 4
            inj_type = "Urea";
        case 8
            inj_type  = "Error (unknown)";
        otherwise
            inj_type = "Unknown";
    end
end