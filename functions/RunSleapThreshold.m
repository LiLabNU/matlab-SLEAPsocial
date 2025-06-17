function RunSleapThreshold(Parameters)
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

    %%% read H5 files
    method = 'simple'; % or 'flow' % Sleap tracker method used for the prediction
    [intruder] = ReadH5Files(Parameters.H5, Parameters.groupName, method);

    %%%  extract features
    gaussSmooth = true;
    interpolation = true;
    [intruder] = ExtractSleapFeatures(intruder, gaussSmooth, interpolation, Parameters.residentLabel, Parameters.intruderLabel, Parameters.bodyPart, Parameters.vidpath, Parameters.vidFormat);
    cd(Parameters.save_dir)
    save(strcat(Parameters.cohort,'_features.mat'), 'intruder','-v7.3');
end

% if PlotSocialTime == 1
%     %%% Calculate time spent socializing (threshold methods)
%     featuresToUse = ["res_body_dist", "res_angle_body"];
%     feature_threshs = [80, 2*pi];
%     MinByMinPlot = false;
%     yaxisLim = 200;
%     [socTime, socTime_STATS, byMinute] = plotSocializingTime(intruder, featuresToUse, feature_threshs, Parameters.epochWindow, Parameters.groupName, Parameters.condName, yaxisLim, MinByMinPlot);
%     socTime_threshold.socTime = socTime;
%     socTime_threshold.socTime_STATS = socTime_STATS;
%     socTime_threshold.byMinute = byMinute;
%     cd(Parameters.save_dir)
%     save(strcat(Parameters.cohort,'_threshold.mat'), 'socTime_threshold');
%     saveas(gcf,strcat(Parameters.cohort,'_threshold.png'));
% end

   
