function [int] = ExtractFeatureShell(Parameters)

for i = 1:size(Parameters.combineData_dir,1)
    % Sleap folder
    Parameters.data_dir = Parameters.combineData_dir{i};
    addpath(genpath(Parameters.data_dir));
    % H5 files
    Parameters.H5 = fullfile(Parameters.data_dir, 'H5');
    addpath(genpath(Parameters.H5));
    % Videos
    Parameters.vidpath = fullfile(Parameters.data_dir, 'ProcessedVideos');
    addpath(genpath(Parameters.vidpath));
    % cohort info
    Parameters.cohort = Parameters.combineCohort(i);

    %     if length(method) == 1
    %         mtd = repmat(method,1,size(Parameters.combineData_dir,1));
    %     else
    %         mtd = method;
    %     end
    if ~isempty(Parameters.fileIdentifier)
        if size(Parameters.fileIdentifier,1) == 1
            fileIdentifier = Parameters.fileIdentifier;
        else
            fileIdentifier = Parameters.fileIdentifier(i,:);
        end
    else
        fileIdentifier = [];
    end

    if ~isempty(Parameters.groupIdentifier)
        if size(Parameters.groupIdentifier,1) == 1
            groupIdentifier = Parameters.groupIdentifier;
        else
            groupIdentifier = Parameters.groupIdentifier(i,:);
        end
    else
        groupIdentifier = [];
    end
    %%% read H5 files
    [intruder,flag] = ReadH5Files(Parameters,fileIdentifier, groupIdentifier);

    if flag == 1
        break
    end

    %%%  extract features
    gaussSmooth = true;
    interpolation = true;
    [intruder] = ExtractSleapFeatures(intruder, gaussSmooth, interpolation, Parameters);

    %%% get videos information
    [intruder] = ExtractVideoInfo(intruder, Parameters);

    %save(strcat(Parameters.cohort,'_features.mat'), 'intruder','-v7.3');
    int{i,:} = intruder;
end




