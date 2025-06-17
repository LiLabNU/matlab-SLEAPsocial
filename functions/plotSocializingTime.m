
function [socTime_filt, STATS, IntFrames_byMinute_filt, framesForCalcium, mouse] = plotSocializingTime(intruder, features, feature_threshs, Parameters, cohort, yaxisLim, type)

epochWindow = Parameters.epochWindow;
groupName = Parameters.groupName;
condName = Parameters.condName;


IntFrames_byMinute = [];
socTime = table();

if length(epochWindow) >1
    secondEpoch = true;
else
    secondEpoch = false;
end


for sesh = 1:length(intruder)
    %     if sum(sesh == skipFiles)
    %         continue
    %     end
    disp(sesh)
    socTime.Animal(sesh) = string(intruder{sesh}.sessionID);
    socTime.Session(sesh) = string(intruder{sesh}.session);

    tempIntFrames = find(getfield(intruder{sesh}.Intruder, features(1))<feature_threshs(1) & rad2deg(getfield(intruder{sesh}.Intruder, features(2)))<feature_threshs(2));
    if size(features,2) == 4
        temp = find(getfield(intruder{sesh}.Intruder, features(3))<feature_threshs(1) & rad2deg(getfield(intruder{sesh}.Intruder, features(4)))<feature_threshs(2));
        tempIntFrames = [tempIntFrames; temp];
        tempIntFrames = unique(tempIntFrames);
    end
    
    tempIntFramesTotal = tempIntFrames + intruder{sesh}.intruderFrames.IntEnt;

    socTime.IntTime(sesh) = length(tempIntFrames)/intruder{sesh}.intruderFrames.fps;

    framesForCalcium{sesh} = ceil(tempIntFramesTotal);
    mouse(sesh,:) = intruder{sesh}.sessionID;
    % first epoch
    tempIntFrames_on = tempIntFrames(tempIntFrames > 1 & tempIntFrames < epochWindow(1)*60*intruder{sesh}.intruderFrames.fps);
    socTime.IntTime_on(sesh) = length(tempIntFrames_on)/intruder{sesh}.intruderFrames.fps;

    if secondEpoch == 1
        IntTotalFrames = epochWindow(1)*60*intruder{sesh}.intruderFrames.fps;
    else
        IntTotalFrames = intruder{sesh}.intruderFrames.Frames - intruder{sesh}.intruderFrames.IntEnt;
    end
    socTime.IntTimePercentage_on(sesh) = length(tempIntFrames_on)/IntTotalFrames;

    if secondEpoch == 1
        % second epoch
        tempIntFrames_off = tempIntFrames(tempIntFrames > epochWindow(1)*60*intruder{sesh}.intruderFrames.fps+1 & tempIntFrames < (epochWindow(1)+epochWindow(2))*60*intruder{sesh}.intruderFrames.fps);
        socTime.IntTime_off(sesh) = length(tempIntFrames_off)/intruder{sesh}.intruderFrames.fps;
        IntTotalFrames = intruder{sesh}.intruderFrames.Frames - intruder{sesh}.intruderFrames.IntEnt - epochWindow(1)*60*intruder{sesh}.intruderFrames.fps;
        socTime.IntTimePercentage_off(sesh) = length(tempIntFrames_off)/IntTotalFrames;
    end

    counter = 0;
    % minute by minute
    for j = 1:epochWindow(end)
        counter = counter + 1;
        tempIntFrames_byMinute = tempIntFrames(tempIntFrames > (j-1)*60*intruder{sesh}.intruderFrames.fps+1 & tempIntFrames < j*60*intruder{sesh}.intruderFrames.fps);
        IntFrames_byMinute(sesh,counter) = length(tempIntFrames_byMinute)/intruder{sesh}.intruderFrames.fps;
    end

end

socTime_filt = {};
IntFrames_byMinute_filt = {};

for i = 1:length(groupName)
    socTime_filt{i} = socTime(socTime.Session == groupName{i}, :);
    IntFrames_byMinute_filt{i} = IntFrames_byMinute(socTime.Session == groupName{i}, :);
end

idx = ~cellfun('isempty',IntFrames_byMinute_filt);
IntFrames_byMinute_filt = IntFrames_byMinute_filt(idx);
socTime_filt = socTime_filt(idx);
groupNameLabels = groupName(idx);

if length(socTime_filt) == 1 
    socTime_filt{2} = socTime_filt{1};
end

if type == "Raw"

    figure
    subplot(1,length(epochWindow),1)
    HaoBarErrorbar(socTime_filt{1}.IntTime_on, socTime_filt{2}.IntTime_on);
    title(cohort + condName{1})
    set(gca,'xticklabel',groupNameLabels)
    ylabel("Interaction time (s)", 'FontSize', 12)
    ylim([0 yaxisLim])
    [H,P,CI,STATS{1}] = ttest2(socTime_filt{1}.IntTime_on, socTime_filt{2}.IntTime_on);
    STATS{1}.pvalue = P;
    xLimits = xlim;
    yLimits = ylim;
    text((xLimits(2)/2),(yLimits(2)*.92),["p: " + num2str(STATS{1}.pvalue)],'Color',[.5 .5 .5]);
    text((xLimits(2)/2),(yLimits(2)*.82),["tstat: " + num2str(STATS{1}.tstat)],'Color',[.5 .5 .5]);
    text((xLimits(2)/2),(yLimits(2)*.72),["df: " + num2str(STATS{1}.df)],'Color',[.5 .5 .5]);
    text((xLimits(2)/2),(yLimits(2)*.62),["sd: " + num2str(STATS{1}.sd)],'Color',[.5 .5 .5]);

    if secondEpoch == 1
        subplot(1,length(epochWindow),2)
        HaoBarErrorbar(socTime_filt{1}.IntTime_off, socTime_filt{2}.IntTime_off);
        title(cohort + condName{2})
        set(gca,'xticklabel',groupNameLabels)
        ylabel("Interaction time (s)", 'FontSize', 12)
        ylim([0 yaxisLim])
        [H,P,CI,STATS{2}] = ttest2(socTime_filt{1}.IntTime_off, socTime_filt{2}.IntTime_off);
        STATS{2}.pvalue = P;
        xLimits = xlim;
        yLimits = ylim;
        text((xLimits(2)/2),(yLimits(2)*.92),["p: " + num2str(STATS{2}.pvalue)],'Color',[.5 .5 .5]);
        text((xLimits(2)/2),(yLimits(2)*.82),["tstat: " + num2str(STATS{2}.tstat)],'Color',[.5 .5 .5]);
        text((xLimits(2)/2),(yLimits(2)*.72),["df: " + num2str(STATS{2}.df)],'Color',[.5 .5 .5]);
        text((xLimits(2)/2),(yLimits(2)*.62),["sd: " + num2str(STATS{2}.sd)],'Color',[.5 .5 .5]);
    end

elseif type == "Percentage"

    figure
    subplot(1,length(epochWindow),1)
    HaoBarErrorbar(socTime_filt{1}.IntTimePercentage_on, socTime_filt{2}.IntTimePercentage_on);
    title(cohort + condName{1})
    set(gca,'xticklabel',groupNameLabels)
    ylabel("Interaction time (s)", 'FontSize', 12)
    ylim([0 yaxisLim])
    [H,P,CI,STATS{1}] = ttest2(socTime_filt{1}.IntTimePercentage_on, socTime_filt{2}.IntTimePercentage_on);
    STATS{1}.pvalue = P;
    xLimits = xlim;
    yLimits = ylim;
    text((xLimits(2)/2),(yLimits(2)*.92),["p: " + num2str(STATS{1}.pvalue)],'Color',[.5 .5 .5]);
    text((xLimits(2)/2),(yLimits(2)*.82),["tstat: " + num2str(STATS{1}.tstat)],'Color',[.5 .5 .5]);
    text((xLimits(2)/2),(yLimits(2)*.72),["df: " + num2str(STATS{1}.df)],'Color',[.5 .5 .5]);
    text((xLimits(2)/2),(yLimits(2)*.62),["sd: " + num2str(STATS{1}.sd)],'Color',[.5 .5 .5]);

    if secondEpoch == 1
        subplot(1,length(epochWindow),2)
        HaoBarErrorbar(socTime_filt{1}.IntTimePercentage_off, socTime_filt{2}.IntTimePercentage_off);
        title(cohort + condName{2})
        set(gca,'xticklabel',groupNameLabels)
        ylabel("Interaction time (s)", 'FontSize', 12)
        ylim([0 yaxisLim])
        [H,P,CI,STATS{2}] = ttest2(socTime_filt{1}.IntTimePercentage_off, socTime_filt{2}.IntTimePercentage_off);
        STATS{2}.pvalue = P;
        xLimits = xlim;
        yLimits = ylim;
        text((xLimits(2)/2),(yLimits(2)*.92),["p: " + num2str(STATS{2}.pvalue)],'Color',[.5 .5 .5]);
        text((xLimits(2)/2),(yLimits(2)*.82),["tstat: " + num2str(STATS{2}.tstat)],'Color',[.5 .5 .5]);
        text((xLimits(2)/2),(yLimits(2)*.72),["df: " + num2str(STATS{2}.df)],'Color',[.5 .5 .5]);
        text((xLimits(2)/2),(yLimits(2)*.62),["sd: " + num2str(STATS{2}.sd)],'Color',[.5 .5 .5]);
    end

end

end



