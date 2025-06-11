function T = tableddindd(d)
%
% Args:
%       d (struct): output struct from ddindd function
%
% Results:
%       T (table): input data table with corrected data
%
if isstruct(d) && strcmp(d.meta.type, 'ddindd')
    %% define vars
    shortFileId   = GetValue(d, 'meta.shortFileId', "NaN"); % "193";
    dateStr       = GetValue(d, 'meta.dateStr', "0000-00-00"); % "2025-05-23";
   
    injections    = GetValue(d, 'meta.injections', []); 
 
    relInj        = GetValue(d, 'meta.relInj', 0); % int;
    
    fitFunction   = GetValue(d, 'meta.method', {"no fit function found"}); % "Langmuir";
    fitFunctionH    = GetValue(d, 'meta.methodFunc', 0); % function handle
    fitFunctionEx = GetValue(d, 'meta.methodEx', {"no ex for fit function found"}); % "b*(1-e^(-(k*(x-t))";
    
    n_rounds      = GetValue(d, 'meta.n_rounds', 2); % 2; 
    nRoundsStr    = convertCharsToStrings(num2str(n_rounds));

    n_sensors     = GetValue(d, 'meta.n_sensors', 8); % 8;

    raw           = GetValue(d, 'raw', []);

    drift_sp_T = cell(n_rounds, n_sensors); sp_corr_T = cell(n_rounds, n_sensors); best_a_T = cell(n_rounds, n_sensors); best_b_T = cell(n_rounds, n_sensors); rsquared_T = cell(n_rounds, n_sensors);
    for r = 1:n_rounds
        round = "round" + r;
        for s = 1:n_sensors
            sensor = "sensor" + s;
            drift_sp_T{r, s}    = GetValue(d, char(round + "." + sensor + "." + "driftSP"), NaN); % d.(round).(sensor).driftSP
            sp_corr_T{r, s}     = GetValue(d, char(round + "." + sensor + "." + "SPcorr"), NaN); % d.(round).(sensor).SPcorr
            best_a_T{r, s}      = GetValue(d, char(round + "." + sensor + "." + "a"), NaN); % d.(round).(sensor).a
            best_b_T{r, s}      = GetValue(d, char(round + "." + sensor + "." + "b"), NaN); % d.(round).(sensor).b
            rsquared_T{r, s}    = GetValue(d, char(round + "." + sensor + "." + "Rsquared"), NaN); % d.(round).(sensor).Rsquared;
        end
    end

    %% MAIN

    if isempty(raw)
        error("[ERROR][tableddindd] raw data table in ddindd struct is empty")
    else
        table = raw;
        
        for r = 1:n_rounds
            round   = "round" + r;

            pltData     = data(data.round == r & (data.inj_type == relInj | data.inj_type == plotCorrType), :);  
            plttgLength = height(data);

            relInjEnd   = find(diff(pltData.inj_type) ~= 0) + 1;

            for s = 1:n_sensors
                sensor      = "sensor" + s; 
                sensor_name = pltData.Properties.VariableNames{s+4};

                % calc model
                t_rel       = (1:(length(pltData.T_s_) - drift_sp_T{r, s} + 1))';
                model       = fitFunctionH;
                y_model     = model(best_a_T{r, s}, best_b_T{r, s}, t_rel);

                % add zeros at beginning and strVal correction 
                y_model     = [zeros(drift_sp_T{r, s}-1, 1); y_model];


                % relevanter abscnitt
                % relevanter p


                table








            end
        end

    
    
        T = table;
    end
    


   


else
    error("[ERROR][tableddindd] input is not of type ddindd (output struct from ddindd function)")
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
            inj_type = "FLush";
        case 4
            inj_type = "Urea";
        otherwise
            inj_type = "Unknown";
    end
end