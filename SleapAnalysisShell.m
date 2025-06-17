%% 
clear all
close all

%% Common Parameters

% Set Parameters for the analysis
% Parameters.combineData_dir = {'Z:\Reesha\Cohort12_BLAtomPFC_opto\Resident_Intruder\Chrimson\Sleap\preisolation';
%     'Z:\Reesha\Cohort12_BLAtomPFC_opto\Resident_Intruder\Chrimson\Sleap\postisolation'};

% give a name for the experiment
Parameters.cohort = 'SISM'; 
% provide the folder paths that contain H5 and ProcessedVideos folders
    Parameters.combineData_dir = {'Z:\PBS\LiPatel_Labs\Personal_Folders\Frankie\Projects\Social_Memory\DaheeCohort6\T1_5\Trial1';
                              'Z:\PBS\LiPatel_Labs\Personal_Folders\Frankie\Projects\Social_Memory\DaheeCohort6\T1_5\Trial5'};
                             %  'Z:\PBS\LiPatel_Labs\Personal_Folders\Frankie\Projects\DaheeOctober\SLEAP\Summarized\Fibers\Trial3';
                              % 'Z:\PBS\LiPatel_Labs\Personal_Folders\Frankie\Projects\DaheeOctober\SLEAP\Summarized\Fibers\Trial4';
                              % 'Z:\PBS\LiPatel_Labs\Personal_Folders\Frankie\Projects\DaheeOctober\SLEAP\Summarized\Fibers\Trial5'};
% give a name for each of the folder path above
Parameters.combineCohort = ["Trial 1"; "Trial 5"];% "Trial 3"; "Trial 4"; "Trial 5"]; 

% You don't need it unless there are multiple groups in one folder. 
% See example usage in ReadH5Files.m function
Parameters.fileIdentifier = [];

% directory all files to save
Parameters.save_dir = 'Z:\PBS\LiPatel_Labs\Personal_Folders\Frankie\Projects\Social_Memory\DaheeCohort6\T1_5\SleapAnalysis';

% names for different groups
Parameters.groupName = {'Females'; 'Males'} % the 1st or 2nd groupName
% leave it empty if only one group
Parameters.groupIdentifier = [2 2 2 2 2 2 2 2 1    ;...
                              2 2 2 2 2 2 2 2 1   ];%...
                             % 1 1 1 1 1 2 2 2 2 2   ;...
                             % 1 1 1 1 1 2 2 2 2 2   ;...
                              %1 1 1 1 1 2 2 2 2 2  ];

% used as plotting labels
Parameters.condName = {'1-5 minutes'};

% time windows for ploting and calculation of socialization. e.g. durations for each epoch (in minutes)
Parameters.epochWindow = [5]; % 3 6 9 

% video format
Parameters.vidFormat = ".mp4";

% skeletion labels for nose, head, body, and butt
Parameters.bodyPart = [1, 2, 3, 4];

% instance labels in sleap
Parameters.residentLabel = "track_0";
Parameters.intruderLabel = "track_1";

% UMAP template
Parameters.templateName = 'UMAPtemplate_Frankie';
Parameters.UMAPtemp_dir = Parameters.save_dir;
addpath(genpath(Parameters.UMAPtemp_dir));

% Settings for running UMAP
Parameters.templateName = strcat(fullfile(Parameters.UMAPtemp_dir, Parameters.templateName),'.mat');

%% Read H5 files and Extract Sleap features
int = ExtractFeatureShell(Parameters);

cd(Parameters.save_dir)
save(strcat(Parameters.cohort,'_intruder.mat'), 'int','Parameters');
%% calibratting for social interaction time ONLY needed if this is the first time for your video setup
%%%%%%%%%%%% To calibrate, you need to measure the pixels of the length (longside) of the homecage in your video screenshot (first_frame.png) using ImageJ. 
%%%%%%%%%%%% And then replace the value in the 'cur' variable below
% save the first frame of the video
filename = 'Z:\PBS\LiPatel_Labs\Personal_Folders\Frankie\Projects\Social_Memory\Yeonju_SocialMemory\SLEAP\Summarized\Trial1\ProcessedVideos\C2_M1_T1.mp4';
video = VideoReader(filename);
frame = readFrame(video);
imwrite(frame, 'first_frame.png');

%% plotting social interaction time
% plot social time using feature threshold
featuresToUse = ["res_body_dist", "res_angle_body", "int_body_dist", "int_angle_body"];
ref = 608; % 438 pixels of the length of the long side of home cage in Chris's video 530 for FSM SM for Dahee: 417
cur = 497;
factor = cur/ref; % ratio of video size to the Chris's video. Get the ratio using ImageJ
dist_thresh = 80*factor;
angle_thresh = 135; %was 135 in original code
feature_threshs = [dist_thresh, angle_thresh];
yaxisLim = 200;
for i = 1:size(Parameters.combineData_dir,1)
    [thresh(i).socTime, ~, minutes{i}, threshFrames{i}, mouse] = plotSocializingTime(int{i}, featuresToUse, feature_threshs, Parameters, Parameters.combineCohort(i), yaxisLim, "Raw"); % Percentage vs. Raw
    cd(Parameters.save_dir)    
    saveas(gcf,strcat(Parameters.combineCohort(i),'_threshold.emf'));
end
save(strcat(Parameters.cohort,'_threshold.mat'), 'thresh');
%% convert frames to binary 
matlabbinary = zeros(1,8851); % x is the length of the boris binary
matlabbinary(threshFrames{1,1}{1,1}) = 1; % frame is the variable containing the social interaction frames 


%% make threshold behavior videos (may not be accurate)
close all
cd(Parameters.save_dir)
timeThresh = 60; % 60 frames to determine approach interaction

sessionToPlot = int{1}{1};
BehThresholdVideo(sessionToPlot, featuresToUse, dist_thresh, angle_thresh, timeThresh, Parameters);

%% Run UMAP
close all

% features used for UMAP
Parameters.featuresUMAP = ["head_dist", "angle_heads", "res_butt_dist", "res_angle_butt", "int_butt_dist", ...
        "int_angle_butt", "butt_dist", "res_velocity", "int_velocity"];

Parameters.templateIdx = ["Epoch"; "Control"; "Stress"]; % corresponding labels are intruder, session, sessionType
dataFilter = []; %only using interacting frames dataFilter = threshFrames for UMAP or dataFilter = []; to use all frames
Parameters.ClusterDetail = 'low';

MakeUMAPtemplate = 0;
RunUMAP = 1;
PlotUMAPVideo = 0;

[data,data_labels] = RunUMAPShell(int, Parameters, MakeUMAPtemplate, RunUMAP, PlotUMAPVideo, dataFilter);

%% plotting clusters

% plot social time using UMAP clusters
sessionToPlot = "1stEpoch";
% % NpHR
% socialC = [1, 2];
% AvoidanceC = [4];
% %Chrimson
% socialC = [5];
% AvoidanceC = [7, 8];
% % cohort 13
% socialC = [4 6 9 11 12];
% AvoidanceC = [];
[IndvCluster, ThreeClusters,mouseUMAP] = plotUMAPclusters(data_labels, Parameters, sessionToPlot, [], []);

%% plot UMAP for illustrator
figure
gscatter(data_labels.UMAP(data_labels.Cluster~=0,1), data_labels.UMAP(data_labels.Cluster~=0,2), data_labels.Cluster(data_labels.Cluster~=0));
set(gcf, 'Renderer', 'painters');
saveas(gcf, 'UMAP.emf');


%% get a frame
% v = VideoReader('12222022_Cohort12b_M5.1_NpHR-processed.mp4');
% frame = read(v,1);
% imshow(frame)




















