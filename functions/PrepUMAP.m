function [data, data_labels] = PrepUMAP(intruderAll, features, epouchWin, cohortAll, dataFilter, f) 

intruder = intruderAll{f};
cohort = cohortAll(f);
num = cell2mat(cellfun(@(x) size(x,2),intruderAll,'UniformOutput',false));

data = [];
data_labels = [];

if length(epouchWin) >1
    secondEpoch = true;
else
    secondEpoch = false;
end

% compile all features into one large matrix
features_all = [];
seshidx = [];
intidx = [];
vidFrame = [];
frameRate = [];
videoFile = string();
session = string();
animal = string();

for sesh = 1:length(intruder)    
        disp(sesh)
        
        if isempty(dataFilter)
            socFramesPos = 1:size(intruder{sesh}.int_frames,2);
            socFramesPos = socFramesPos';
            vidFrame_current = intruder{sesh}.int_frames';
        else
            [vidFrame_current,socFramesPos] = intersect(intruder{sesh}.int_frames',dataFilter{sesh});
        end

        % get frame numbers
        temp_features = intruder{sesh}.Intruder.features(socFramesPos,:);
        features_all = [features_all; temp_features];
        vidFrame = [vidFrame; vidFrame_current];

        % get session info
        if f == 1
            idxTemp = ones(height(temp_features),1) * sesh;
        else
            idxTemp = ones(height(temp_features),1) * sesh + sum(num(1:f-1));
        end
        seshidx = [seshidx; idxTemp];

        % get frame rates
        fps = ones(height(temp_features),1) * intruder{sesh}.intruderFrames.fps;
        frameRate = [frameRate; fps];

        % give labels for 1st epouch
        intidxTemp = zeros(length(vidFrame_current),1);
        intidxTemp(1: epouchWin(1)*60*fps(1)) = 1;

        % give labels for 2nd epouch
        if secondEpoch == 1
            intidxTemp(epouchWin(1)*60*fps(1) + 1: (epouchWin(2)+epouchWin(1))*60*fps(1)) = 2;
        end
        intidx = [intidx; intidxTemp];
      
       
        session(sesh,1) = intruder{sesh}.session;        
        animal(sesh,1) = intruder{sesh}.sessionID;        
        vidname = intruder{sesh}.sessionID + intruder{sesh}.vidFormat;
        tempVidFile = fullfile(intruder{sesh}.vidpath, vidname);
        videoFile(sesh,1) = tempVidFile;    
end

features_all_filt = table2array(features_all(:,features));
nanflag = find(sum(~isnan(features_all_filt),2) == size(features_all_filt,2)); % looking at all non-nan frames
tempdata = zscore(features_all_filt(nanflag,:),0,1); % excluding centroids
z_filter = find(sum(tempdata<5,2) == size(features_all_filt,2)); % get rid of high z-score values

nanflag = intersect(nanflag, nanflag(z_filter));
tempdata = zscore(features_all_filt(nanflag,:),0,1);

tempdata_labels = table();
if f == 1
    seshidxTemp = seshidx;
else
    seshidxTemp = seshidx - sum(num(1:f-1));
end
tempdata_labels.animal = animal(seshidxTemp(nanflag));
tempdata_labels.session = session(seshidxTemp(nanflag));
tempdata_labels.intidx = (intidx(nanflag));
tempdata_labels.intruder(tempdata_labels.intidx == 1) = "1stEpoch";
if secondEpoch == 1
    tempdata_labels.intruder(tempdata_labels.intidx == 2) = "2ndEpoch";
end

tempdata_labels.intidx = [];
tempdata_labels.vidFile = videoFile(seshidxTemp(nanflag));
tempdata_labels.vidFrame = vidFrame(nanflag);
tempdata_labels.SessionIdx = seshidx(nanflag);
tempdata_labels.frameRate = frameRate(nanflag);
tempdata_labels.sessionType = repmat(cohort,[size(tempdata_labels,1),1]);

data = [data;tempdata];
data_labels = [data_labels; tempdata_labels];

% remove entries with a missing intruder label
[~,temp] = rmmissing(data_labels.intruder);
data_labels = data_labels(~temp,:);
data = data(~temp,:);
