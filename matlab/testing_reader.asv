%% SET FILES AND PATHS
data_file       = '../data/v2/AI_Test/195/201253_25112022.csv';
meta_file       = '../data/v2/AI_Test/195/201253_25112022.json';

output_path     = 'output/ddindd';

addpath("ddindd/");

%% READ INPUTS

try
    data        = readtable( data_file, Delimiter = ',');
catch e
    error("[ERROR][data reader] " + convertCharsToStrings(e.message));
end

try
    metadata   = jsondecode( fileread( meta_file ) );
catch e
    disp("[WARNING][metadata reader] " + convertCharsToStrings(e.message));
    metadata   = {};
end


%% DDINDD

d   = ddindd(data, method = 'langmuir', metaFile = metadata, relInj = 3);

%printddindd(d);
%plotddindd(d, plotCorrType = 0);

%T = tableddindd(d);

    %% SAVE OUTPUT TABLE
    try
        output_name = output_path + d.meta.raw_name + ".csv";
    catch
        output_name = output_path + ".csv";
    end

    writetable(T, output_name)