%% SET FILES AND PATHS
% data_file       = '../data/v2/AI_Test/195/201253_25112022.csv';
% meta_file       = '../data/v2/AI_Test/195/201253_25112022.json';

% data_file       = '../data/v2/AI_Test/192/181601_10112022.csv';
% meta_file       = '../data/v2/AI_Test/192/181601_10112022.json';

data_file       = '../data/v3/231510_27052025.csv';
meta_file       = '../data/v3/231510_27052025.json';

output_path     = 'output/ddindd';

addpath("ddindd/");

%% READ INPUTS

try
    data        = readtable( data_file, Delimiter = ',');
catch e
    error("[ERROR][data reader] " + convertCharsToStrings(e.message));
end

try
    metadata    = jsondecode( fileread( meta_file ) );
catch e
    disp("[WARNING][metadata reader] " + convertCharsToStrings(e.message));
    metadata    = {};
end

%% DISP RAW
% % figure; hold on; yyaxis left;
% % for i = 1:8
% %     plot(data{:, i+4}, Marker = 'none', LineStyle = '-', DisplayName = data.Properties.VariableNames{i+4}); 
% % end
% % yyaxis right; plot(data{:, "Val_"}, Color = 'k', HandleVisibility = 'off');

%% DDINDD

d   = ddindd(data, method = 'langmuir', metaFile = metadata, relInj = 0);

%printddindd(d);
%plotddindd(d, plotCorrType = 0);

%T = tableddindd(d);

    %% SAVE OUTPUT TABLE
%    try
%        output_name = output_path + d.meta.raw_name + ".csv";
%    catch
%        output_name = output_path + ".csv";
%    end
%
%    writetable(T, output_name)