function H = plotddindd(d, varargin)
%
% Args:
%       d (struct): output struct from ddindd function
%
%   optional:
%       plotCorrType (int): which injection type should be plotted too with correction (default = 1)
%       plotUncorrType (int): which injection type should be plotted too without correction (default = NaN)
%       plotUncorrToo (bool): should uncorrected drift be plotted too (default = 0)
%       plotFitToo (bool): should fit function plotted too (default = 0)
%
%       plotType (int): plot design for output (default = 0)
%           possibile options:
%               0: plot negative sample and positive sample
%               1: plot only positive sample but w/ corrections from negative sample and correct to zero at 
%                  beginning of positive sample
%
%       plotMarker (bool): should markers be added (default = NaN; then depends on plotColorType) 
%       plotColorType (int): plot design color (default = 0) 
%           possible options:
%               0: red and black
%               1: different color for each sensor (blue - brown)           
%
%       plotSensors (cell array): plot only these sensors (default = [1:n_sensors])
%       plotRounds (cell array): plot only these sensors (default = [1:n_rounds])
%
% Results:
%       ans (cell): cell array of figures
%
if isstruct(d) && strcmp(d.meta.type, 'ddindd')
    %% parse second argument (option parameter)
    n = length(varargin);
        if mod(n,2) ~= 0
            error("[ERROR][input parsing] optional arg list must be paired keywords and values. # of extra args must be even.");
        end
    
    KeyList = varargin(1:2:n);
    KeyList = cellfun(@char,KeyList,'UniformOutput',false); % convert strings to chars
    KeyList = lower(KeyList);
    ValList = varargin(2:2:n);
    %% define vars

    shortFileId     = GetValue(d, 'meta.shortFileId', "NaN"); % "193";
    dateStr         = GetValue(d, 'meta.dateStr', "0000-00-00"); % "2025-05-23";
   
    injections      = GetValue(d, 'meta.injections', []); 

    relInj          = GetValue(d, 'meta.relInj', 0); % int;

    fitFunction     = GetValue(d, 'meta.method', {"no fit function found"}); % "Langmuir";
    fitFunctionH    = GetValue(d, 'meta.methodFunc', 0); % function handle
    fitFunctionEx   = GetValue(d, 'meta.methodEx', {"no ex for fit function found"}); % "b*(1-e^(-(k*(x-t))";
    
    n_rounds        = GetValue(d, 'meta.n_rounds', 2); % 2; 
    nRoundsStr      = convertCharsToStrings(num2str(n_rounds));

    n_sensors       = GetValue(d, 'meta.n_sensors', 8); % 8;

    data            = GetValue(d, 'raw', table());

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

    %% get values from keys. second last arg is expected type. last arg is default value if the key is missing from varagin/KeyList or unvalid type

    plotCorrType    = GetValueByKey(KeyList, ValList, 'plotCorrType', 'double', 1);
    plotUncorrType  = GetValueByKey(KeyList, ValList, 'plotUncorrType', 'double', NaN);
    plotCorrToo     = GetValueByKey(KeyList, ValList, 'plotCorrToo', 'double', 1);
    plotUncorrToo   = GetValueByKey(KeyList, ValList, 'plotUncorrToo', 'double', 0);
    plotFitToo      = GetValueByKey(KeyList, ValList, 'plotFitToo', 'double', 0);
    plotType        = GetValueByKey(KeyList, ValList, 'plotType', 'double', 0);

    plotColorType   = GetValueByKey(KeyList, ValList, 'plotColorType', 'double', 0);
    plotMarker      = GetValueByKey(KeyList, ValList, 'plotMarker', 'double', NaN);

    plotSensors     = GetValueByKey(KeyList, ValList, 'plotSensors', 'double', [1:n_sensors]);
    plotRounds      = GetValueByKey(KeyList, ValList, 'plotRounds', 'double', [1:n_rounds]);

    %% style vars
    switch plotColorType
        case 1
            colmap = jet(8);
            if isnan(plotMarker)
                plotMarker = 0;
            end
        otherwise % default case %% case 0
            colmap = repmat([1 0 0; 0 0 1], n_sensors, 1);
            if isnan(plotMarker)
                plotMarker = 1;
            end
    end

    markermap = {'o', '+', 'square', 'x', 'diamond', '*', '^', '|', '>', '<', 'v', 'hexagram', '.'};

    %% MAIN

    switch plotType

        case 1

            for r = plotRounds
                round = "round" + r;

                clf(figure(r));             % clear figure
                H{r}        = figure(r);    % create figure for round
                fig_handles = [];           % create empty array for handles

                % load data
                pltData     = data(data.round == r & (data.inj_type == relInj | data.inj_type == plotCorrType), :);  
                plttgLength = height(data);
            
                relInjEnd   = find(diff(pltData.inj_type) ~= 0) + 1;

                for s = plotSensors
                    sensor      = "sensor" + s; 
                    sensor_name = pltData.Properties.VariableNames{s+4};
        
                    strVal      = GetValue(d, char(round + "." + sensor + "." + "strVal"), 0);

                    posBeginn   = find(diff(pltData.inj_type == plotCorrType) == 1) + 1;
                    posStrVal   = pltData{posBeginn, s+4};
        
                    if plotUncorrToo
                        % plot raw data corrected by strVal
                        if plotMarker
                            plot(pltData{posBeginn:end, "T_s_"}, pltData{posBeginn:end, s+4} - posStrVal, Color = colmap(s, :), Marker = markermap{s}, LineStyle = '--', HandleVisibility = 'off'); hold on;
                        else
                            plot(pltData{posBeginn:end, "T_s_"}, pltData{posBeginn:end, s+4} - posStrVal, Color = colmap(s, :), Marker = 'none', LineStyle = '--', HandleVisibility = 'off'); hold on;
                        end
                    end
        
                    % calc model
                    t_rel       = (1:(length(pltData.T_s_) - drift_sp_T{r, s} + 1))';
                    model       = fitFunctionH;
                    y_model     = model(best_a_T{r, s}, best_b_T{r, s}, t_rel);
        
                    % add zeros at beginning and strVal correction 
                    y_model     = [zeros(drift_sp_T{r, s}-1, 1); y_model];
        
                    if plotFitToo
                        % plot fit
                        if plotMarker
                            plot(pltData{posBeginn:end, "T_s_"}, y_model(posBeginn:end), ':k', Marker = markermap{s}, HandleVisibility = 'off');
                        else
                            plot(pltData{posBeginn:end, "T_s_"}, y_model(posBeginn:end), ':k', Marker = 'none', HandleVisibility = 'off');
                        end
                    end
        
                    % plot result
                    if plotCorrToo || (~plotCorrToo && ~plotUncorrToo && ~plotFitToo)
                        if plotMarker
                            h = plot(pltData{posBeginn:end, "T_s_"}, pltData{posBeginn:end, s+4} - y_model(posBeginn:end) - posStrVal + y_model(posBeginn), Color = colmap(s, :), Marker = markermap{s}, LineStyle = '-', LineWidth = 1.5, DisplayName = sensor_name + ": corrected data"); hold on; 
                        else
                            h = plot(pltData{posBeginn:end, "T_s_"}, pltData{posBeginn:end, s+4} - y_model(posBeginn:end) - posStrVal + y_model(posBeginn), Color = colmap(s, :), Marker = 'none', LineStyle = '-', LineWidth = 1.5, DisplayName = sensor_name + ": corrected data"); hold on;
                        end
                    else
                        if plotMarker
                            h = plot(NaN, NaN, Color = colmap(s, :), Marker = markermap{s}, LineStyle = '-', LineWidth = 1.5, DisplayName = sensor_name); hold on;
                        else
                            h = plot(NaN, NaN, Color = colmap(s, :), Marker = 'none', LineStyle = '-', LineWidth = 1.5, DisplayName = sensor_name); hold on;
                        end
                    end
                    fig_handles = [fig_handles h];
                end

                if plotUncorrToo
                    h = plot(NaN, NaN, Color = 'k', Marker = 'none', LineStyle = '--', DisplayName = "Uncorrected (raw) data"); % handle for legend
                    fig_handles = [fig_handles h];
                end

                if plotFitToo
                    h = plot(NaN, NaN, Color = 'k', Marker = 'none', LineStyle = ':', DisplayName = "Data fit"); % handle for legend
                    fig_handles = [fig_handles h];
                end
                
                yline(0, Color = 'k', LineStyle = '--', HandleVisibility = 'off'); % add 0 base line

                xline(pltData.T_s_(posBeginn), Color = 'k', LineStyle = '--', HandleVisibility = 'off', Label = GetInjectionType(plotCorrType));

                title(shortFileId + " (round " + r + "/" + n_rounds + "): correcting " + GetInjectionType(plotCorrType) + " w/ drift from " + GetInjectionType(relInj));
                xlabel("time [s]"); ylabel("raw signal [nm]");
                legend(fig_handles, 'Location', 'best');

                hold off;

            end

        otherwise % default case %% case 0

            for r = plotRounds
                round = "round" + r;

                clf(figure(r));             % clear figure
                H{r}        = figure(r);    % create figure for round
                fig_handles = [];           % create empty array for handles
        
                % load data
                pltData     = data(data.round == r & (data.inj_type == relInj | data.inj_type == plotCorrType), :);  
                plttgLength = height(data);

                relInjEnd   = find(diff(pltData.inj_type) ~= 0) + 1;           
        
                for s = plotSensors
                    sensor      = "sensor" + s; 
                    sensor_name = pltData.Properties.VariableNames{s+4};
        
                    %strVal      = GetValue(d, char(round + "." + sensor + "." + "strVal"), 0);
                    strVal      = pltData{drift_sp_T{r, s}, s+4};
        
                    if plotUncorrToo
                        % plot raw data corrected by strVal
                        if plotMarker
                            plot(pltData.T_s_, pltData{:, s+4} - strVal, Color = colmap(s, :), Marker = markermap{s}, LineStyle = '--', HandleVisibility = 'off'); hold on;
                        else
                            plot(pltData.T_s_, pltData{:, s+4} - strVal, Color = colmap(s, :), Marker = 'none', LineStyle = '--', HandleVisibility = 'off'); hold on;
                        end
                    end
        
                    % calc model
                    t_rel       = (1:(length(pltData.T_s_) - drift_sp_T{r, s} + 1))';
                    model       = fitFunctionH;
                    y_model     = model(best_a_T{r, s}, best_b_T{r, s}, t_rel);
        
                    % add zeros at beginning and strVal correction 
                    y_model     = [zeros(drift_sp_T{r, s}-1, 1); y_model];
        
                    if plotFitToo
                        % plot fit
                        if plotMarker
                            plot(pltData.T_s_, y_model, ':k', Marker = markermap{s}, HandleVisibility = 'off'); hold on;
                        else
                            plot(pltData.T_s_, y_model, ':k', Marker = 'none', HandleVisibility = 'off'); hold on;
                        end
                    end
        
                    % plot result
                    if plotMarker
                        h = plot(pltData.T_s_, pltData{:, s+4} - y_model - strVal, Color = colmap(s, :), Marker = markermap{s}, LineStyle = '-', LineWidth = 1.5, DisplayName = sensor_name + ": corrected data"); hold on; 
                    else
                        h = plot(pltData.T_s_, pltData{:, s+4} - y_model - strVal, Color = colmap(s, :), Marker = 'none', LineStyle = '-', LineWidth = 1.5, DisplayName = sensor_name + ": corrected data"); hold on;
                    end
                    fig_handles = [fig_handles h];
                end

                if plotUncorrToo
                    h = plot(NaN, NaN, Color = 'k', Marker = 'none', LineStyle = '--', DisplayName = "Uncorrected (raw) data"); % handle for legend
                    fig_handles = [fig_handles h];
                end

                if plotFitToo
                    h = plot(NaN, NaN, Color = 'k', Marker = 'none', LineStyle = ':', DisplayName = "Data fit"); % handle for legend
                    fig_handles = [fig_handles h];
                end
                
                yline(0, Color = 'k', LineStyle = '--', HandleVisibility = 'off'); % add 0 base line

                xline(pltData.T_s_(1), Color = 'k', LineStyle = '--', HandleVisibility = 'off', Label = GetInjectionType(relInj));
                xline(pltData.T_s_(relInjEnd), Color = 'k', LineStyle = '--', HandleVisibility = 'off', Label = GetInjectionType(plotCorrType));

                title(shortFileId + " (round " + r + "/" + n_rounds + "): correcting " + GetInjectionType(plotCorrType) + " w/ drift from " + GetInjectionType(relInj));
                xlabel("time [s]"); ylabel("raw signal [nm]");
                legend(fig_handles, 'Location', 'best');

                hold off;

            end

    end

else
    error("[ERROR][printddindd] input is not of type ddindd (output struct from ddindd function)")
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

%% GetValueByKey: return default value if field is missing from opt or wrong type
%
% Args:
%       KeyList (cell): List of keys from varargin input
%       ValList (cell): List of values from varargin input
%       key (char): name of key
%       expectedType (char): expected type of value
%       defaultValue (any): default value (if no val in ValList)
%
% Result:
%       value (any): from ValList if available and correct type, else defaultValue
%
function value = GetValueByKey(KeyList, ValList, key, expectedType, defaultValue)
    idx = find(strcmp(KeyList,lower(key)));
    if isempty(idx) 
        value = defaultValue;
    else
        value = ValList{idx(1)};
        if ~isa(value, expectedType)
            value = defaultValue;
        end
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
        otherwise
            inj_type = "Unknown";
    end
end