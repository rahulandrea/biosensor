function [] = printddindd(d)
%
% Args:
%       d (struct): output struct from ddindd function
%
% Results:
%       void
%
if isstruct(d) && strcmp(d.meta.type, 'ddindd')
    %% define vars

    shortFileId   = GetValue(d, 'meta.shortFileId', "NaN"); % "193";
    dateStr       = GetValue(d, 'meta.dateStr', "0000-00-00"); % "2025-05-23";
   
    injections    = GetValue(d, 'meta.injections', []); 
 
    relInj        = GetValue(d, 'meta.relInj', 0); % int;
    
    fitFunction   = GetValue(d, 'meta.method', {"no fit function found"}); % "Langmuir";
    fitFunctionEx = GetValue(d, 'meta.methodEx', {"no ex for fit function found"}); % "b*(1-e^(-(k*(x-t))";
    
    n_rounds      = GetValue(d, 'meta.n_rounds', 2); % 2; 
    nRoundsStr    = convertCharsToStrings(num2str(n_rounds));

    n_sensors     = GetValue(d, 'meta.n_sensors', 8); % 8;

    drift_sp_T = cell(n_rounds, n_sensors); sp_corr_T = cell(n_rounds, n_sensors); best_a_T = cell(n_rounds, n_sensors); best_b_T = cell(n_rounds, n_sensors); rsquared_T = cell(n_rounds, n_sensors);
    for r = 1:n_rounds
        round = "round" + r;
        for s = 1:n_sensors
            sensor = "sensor" + s;
            drift_sp_T{r, s} = GetValue(d, char(round + "." + sensor + "." + "driftSP"), NaN); % d.(round).(sensor).driftSP
            sp_corr_T{r, s} = GetValue(d, char(round + "." + sensor + "." + "SPcorr"), NaN); % d.(round).(sensor).SPcorr
            best_a_T{r, s} = GetValue(d, char(round + "." + sensor + "." + "a"), NaN); % d.(round).(sensor).a
            best_b_T{r, s} = GetValue(d, char(round + "." + sensor + "." + "b"), NaN); % d.(round).(sensor).b
            rsquared_T{r, s} = GetValue(d, char(round + "." + sensor + "." + "Rsquared"), NaN); % d.(round).(sensor).Rsquared;
        end
    end
    
    % init list for warnings
    warnings_list = string.empty;

    %% HEADER

    line_width = 77; % min 40

    disp(repmat('#', 1 , line_width)); %%% ln 1

    % title
    length_ln2 = 2 + strlength(shortFileId) + 2 + strlength(dateStr) + 2;
    space_at_front = ceil((line_width - length_ln2 - 1) / 2) - 2;
    space_at_end = line_width - (length_ln2 + space_at_front) - 2;
    fprintf('# %*s %s %*s # \n', space_at_front, '', [shortFileId + ": " + dateStr], space_at_end, ''); %%% ln 2

    % title 2
    length_ln3 = 2 + 26 + 2;
    space_at_front = ceil((line_width - length_ln3 - 1) / 2) - 2;
    space_at_end = line_width - (length_ln3 + space_at_front) - 2;
    fprintf('# %*s %s %*s # \n', space_at_front, '', ["DRIFT DETECTION AND APPROX"], space_at_end, '') %%% ln 3

    disp(repmat('#', 1 , line_width)); %%% ln 4

    % Val_ Info
    disp(" Inj type 1" + " = " + GetInjectionType(injections(1))); %%% ln 5
    for n = 2:length(injections)
        disp("          " + n + ' = ' + GetInjectionType(injections(n))); %%% 6a - 6z
    end

    disp(repmat('#', 1 , line_width)); %%% ln 7

    % drift type
    length_ln8 = 2 + 9 + strlength(GetInjectionType(relInj)) + 4;
    space_at_front = ceil((line_width - length_ln8 - 1) / 2);
    space_at_end = line_width - (length_ln8 + space_at_front);
    fprintf('# %*s %s %*s # \n',space_at_front ,'', ["DRIFT IN " + upper(GetInjectionType(relInj))], space_at_end, '') %%% ln 8

    % function for fit
    length_ln9 = 2 + 24 + strlength(fitFunction) + 4 + strlength(fitFunctionEx) + 2;
    if length_ln9 < line_width % if there is space for fit function example
        space_at_end = line_width - length_ln9 - 1;
        fprintf('# %s %*s # \n', ["Chosen function for fit: " + fitFunction + " (" + fitFunctionEx + ")"], space_at_end, '') %%% ln 9
    else
        space_at_end = line_width - length_ln9 + 3 + strlength(fitFunctionEx) - 1;
        fprintf('# %s %*s # \n', ["Chosen function for fit: " + fitFunction], space_at_end, '') %%% ln 9 
        %%%% TODO: fitFunctionEx in ln 9b
    end
    
    % n detected rounds
    length_ln10 = 2 + 17 + strlength(nRoundsStr) + 2;
    space_at_end = line_width - length_ln10 - 1;
    fprintf('# %s %*s # \n', ["Detected rounds: " + nRoundsStr], space_at_end, '') %%% ln 10

    disp(repmat('#', 1 , line_width)); %%% ln 11

    %% MAIN

    for r = 1:n_rounds
        fprintf('.%s. \n', repmat('-', 1, line_width - 2)); % ln 12
        
        % which round
        length_ln13 = 2 + 7 + length(num2str(r)) + 4;
        space_at_front = ceil((line_width - length_ln13) / 2);
        space_at_end = line_width - (length_ln13 + space_at_front);
        fprintf('| %*s %s %*s | \n', space_at_front, '', ["Round: " + r], space_at_end, ''); %%% ln 13

        fprintf('|%s| \n', repmat('-', 1, line_width - 2)); % ln 14

        % sensor table
        space_at_front = line_width - 2 - 7 - 55 - 3;
        fprintf('| %*s %s %54s | \n', space_at_front, '', ["Sensor:"], ''); %ln 15
        space_at_front = line_width - 2 - 66;
        fprintf('| %*s | 1     | 2     | 3     | 4     | 5     | 6     | 7     | 8     | \n', space_at_front, '') % ln 16

        % length of numbers in table 
        l = 5;

        % Drift SP
        fprintf( '| Drift SP  | %s | %s | %s | %s | %s | %s | %s | %s | \n', ...
            formatN(drift_sp_T{r,1}, l, warnings_list), formatN(drift_sp_T{r,2}, l, warnings_list), ...
            formatN(drift_sp_T{r,3}, l,warnings_list), formatN(drift_sp_T{r,4}, l, warnings_list), ...
            formatN(drift_sp_T{r,5}, l, warnings_list), formatN(drift_sp_T{r,6}, l, warnings_list), ...
            formatN(drift_sp_T{r,7}, l, warnings_list), formatN(drift_sp_T{r,8}, l, warnings_list) ) % ln 17
        
        % SP corr
        fprintf( '| SP corr   | %s | %s | %s | %s | %s | %s | %s | %s | \n', ...
            formatN(sp_corr_T{r,1}, l, warnings_list), formatN(sp_corr_T{r,2}, l, warnings_list), ...
            formatN(sp_corr_T{r,3}, l, warnings_list), formatN(sp_corr_T{r,4}, l, warnings_list), ...
            formatN(sp_corr_T{r,5}, l, warnings_list), formatN(sp_corr_T{r,6}, l, warnings_list), ...
            formatN(sp_corr_T{r,7}, l, warnings_list), formatN(sp_corr_T{r,8}, l, warnings_list) ) % ln 18

        % Best a
        fprintf( '| Best a    | %s | %s | %s | %s | %s | %s | %s | %s | \n', ...
            formatN(best_a_T{r,1}, l, warnings_list), formatN(best_a_T{r,2}, l, warnings_list), ...
            formatN(best_a_T{r,3}, l, warnings_list), formatN(best_a_T{r,4}, l, warnings_list), ...
            formatN(best_a_T{r,5}, l, warnings_list), formatN(best_a_T{r,6}, l, warnings_list), ...
            formatN(best_a_T{r,7}, l, warnings_list), formatN(best_a_T{r,8}, l, warnings_list) ) % ln 19

        % Best b
        fprintf( '| Best b    | %s | %s | %s | %s | %s | %s | %s | %s | \n', ...
            formatN(best_b_T{r,1}, l, warnings_list), formatN(best_b_T{r,2}, l, warnings_list), ...
            formatN(best_b_T{r,3}, l, warnings_list), formatN(best_b_T{r,4}, l, warnings_list), ...
            formatN(best_b_T{r,5}, l, warnings_list), formatN(best_b_T{r,6}, l, warnings_list), ...
            formatN(best_b_T{r,7}, l, warnings_list), formatN(best_b_T{r,8}, l, warnings_list) ) % ln 20

        % Rsquared
        fprintf( '| R^2       | %s | %s | %s | %s | %s | %s | %s | %s | \n', ...
            formatN(rsquared_T{r,1}, l, warnings_list), formatN(rsquared_T{r,2}, l, warnings_list), ...
            formatN(rsquared_T{r,3}, l, warnings_list), formatN(rsquared_T{r,4}, l, warnings_list), ...
            formatN(rsquared_T{r,5}, l, warnings_list), formatN(rsquared_T{r,6}, l, warnings_list), ...
            formatN(rsquared_T{r,7}, l, warnings_list), formatN(rsquared_T{r,8}, l, warnings_list) ) % ln 20
    end

    fprintf('.%s. \n', repmat('-', 1, line_width - 2)); % ln 21
    
    %% HINTS AND WARNINGS

    for w = 1:length(warnings_list)
        disp(formatW(warnings_list(w), line_width)); % ln 22 a-z
    end

    dispstr = "[HINT] Use 'plotddindd()' to plot drift approximation";
    fprintf('| %s %*s | \n', dispstr, line_width - (length(convertStringsToChars(dispstr)) + 5), '') % ln 23 a

    dispstr = "[HINT] Use 'help ddindd' for help";
    fprintf('| %s %*s | \n',dispstr, line_width - (length(convertStringsToChars(dispstr)) + 5), '') % ln 23 b

    fprintf('.%s. \n', repmat('-', 1, line_width - 2)); % ln 24
    
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

%% formatN: Function to format numbers to n characters
%
% Args:
%       x (double): number to format
%       l (int): how many characters
%       warnings (string array): array where warnings are saved in
%
% Returns:
%       s (double): formated number
%
function s = formatN(x, l, warnings)

    s_char = num2str(x); % number as character
    if x < 0 % is negative?
        neg = 1;
    else
        neg = 0;
    end

    a = abs(x);

    % (1) if length <= 5
    if neg == 0 & length(s_char) <= l
        s = sprintf('%5s', s_char);
        return;
    elseif neg == 1 & length(s_char) <= l+1
        s_char = erase(s_char, '-');
        s = sprintf('%5s', s_char);
        return;
    end

    % (2) if length > 5

        % (a) if a >= 100000
        if a >= 10^l
            e = floor(log10(a)); % calc exponent
            m = a / 10^e;
            while m >= 10
                m = m / 10;
                e = e + 1; 
            end

            if e < 10
                m = round(m, l-4);
            elseif e < 100
                m = round(m, l-5);
            else
                s = '  NaN';
                warnings(end+1) = "[WARNING][formatN] Number to long. Display not possible. Setting 'NaN' instead.";
                return;
            end

            if length(num2str(m)) + 1 + length(num2str(e)) > l
                s = '  NaN';
                warnings(end+1) = "[WARNING][formatN] Number to long. Display not possible. Setting 'NaN' instead.";
                return;
            end
            s = convertCharsToStrings(num2str(m)) + "E" + convertCharsToStrings(num2str(e));
            return;
        end

        % (b) if 1 <= a < 100000
        if a >= 1 & a < 10^l
            s = num2str(a, '%.5g');
            s = s(1:min(5, length(s))); % make sure max length 5
            if s(end) == '.'; s(end) = []; end % delete ending '.'
            if length(s) < 5
                s = [repmat(' ', 1, 5 - length(s)) s]; % fill with ' ' if necessary
            end
            return;
        end

        % (c) if 0.001 <= a < 1
        if a >= 10^(l-8) & a < 1
            s = num2str(a, '%.4f');
            s = s(2:end); % delete leading 0
            return;
        end

        % (d) if 0 < a < 0.001
        if a > 0
            e = floor(log10(a)); % calc exponent
            m = a / 10^e;
            if m >= 10
                m = m / 10;
                e = e + 1;
            end
            while m >= 10
                m = m / 10;
                e = e + 1; 
            end
            e = abs(e); % make positive
            if e > 10
                m = round(m, l-4);
            elseif e > 100
                m = round(m, l-5);
            else
                s = '  NaN';
                warnings(end+1) = "[WARNING][formatN] Number to long. Display not possible. Setting 'NaN' instead.";
                return;
            end
            if length(num2str(m)) + 1 + length(num2str(e)) > l
                s = '  NaN';
                warnings(end+1) = "[WARNING][formatN] Number to long. Display not possible. Setting 'NaN' instead.";
                return;
            end
            s = convertCharsToStrings(num2str(m)) + "e" + convertCharsToStrings(num2str(e));
            return;
        else
            s = '  NaN';
            warnings(end+1) = "[WARNING][formatN] Couldnt recognize number. Setting 'NaN' instead.";
        end

end

%% formatW: Function to format warnings (to max line length = l-4)
%
% Args:
%       x (string):
%       l (int):
%
% Results:
%       t (char):
%
function t = formatW(x, l)

    firstPrefix = '| ';
    nextPrefix = sprintf('|%5s', '');
    suffix = ' |';

    x = convertCharsToStrings(x);
    words = split(x); % split in words
    
    current_line = firstPrefix; % text of current line
    t = ""; % total text
    line_count = 0; % line count

    for i = 1:numel(words)
        word = words(i);

        if line_count == 0 % set prefix
            prefix = firstPrefix;
        else
            prefix = nextPrefix;
        end

        if (strlength(current_line) + (strlength(current_line) > length(prefix)) + strlength(word) + strlength(suffix)) <= l
            % if there is still space in current line
            if strlength(current_line) > length(prefix) % if there is already something written in current line
                current_line = current_line + " " + word;
            else % if current line is empty
                current_line = prefix + word;
            end
        else
            % if there is no space in current line
            space_at_end = l - strlength(current_line) - strlength(suffix); % how may spaces to end
            current_line = current_line + repmat(' ', 1, space_at_end) + suffix ; % end current line
            t = t + current_line + newline; % save current line in text
            line_count = line_count + 1;
            prefix = nextPrefix; % set new prefix
            if (l - strlength(prefix) - strlength(word) - strlength(suffix)) > 0
                % if word
                current_line = prefix + word; % begin new line
            else
                current_line = prefix + word; % begin new line
            end
        end

        if i == numel(words) % if last word, add last current line to text
            space_at_end = l - strlength(current_line) - strlength(suffix); % how may spaces to end
            current_line = current_line + repmat(' ', 1, space_at_end) + suffix ; % end current line
            t = t + current_line; % save current line in text
        end
    end
    t = convertStringsToChars(t);
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