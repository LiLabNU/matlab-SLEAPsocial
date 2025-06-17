function [ClusterFinal, threeCFinal, mouse] = plotUMAPclusters(data_labels, Parameters, type, socialC, AvoidanceC)

if nargin < 4
    socialC = [];
    AvoidanceC = [];
end

numClusters = length(unique(data_labels.Cluster)); % for UMAP'd data
cluster = 1:numClusters-1; % Select which clusters you want to view; the last cluster is always the background

for n = 1:size(Parameters.combineData_dir,1)

    temp = data_labels(data_labels.intruder == type & data_labels.sessionType == Parameters.combineCohort(n),:);
    animal = unique(temp.animal);
    Cluster = [];
    results = {};
    threeC = [];
    counter1 = 0;
    counter2 = 0;
   

    for i = 1:size(animal,1)

        temp2 = temp(temp.animal == animal(i),:);
        temp2 = temp2(temp2.intruder ~= "",:);
        
        if length(Parameters.groupName) > 2
            condition1 = temp2.Cluster(temp2.session == Parameters.groupName{1} | temp2.session == Parameters.groupName{3});
            condition2 = temp2.Cluster(temp2.session == Parameters.groupName{2} | temp2.session == Parameters.groupName{4});
        else
            condition1 = temp2.Cluster(temp2.session == Parameters.groupName{1});
            condition2 = temp2.Cluster(temp2.session == Parameters.groupName{2});
        end

        if temp2.session(1) == Parameters.groupName{1}
            counter1 = counter1 + 1;
            for j = cluster
                Cluster(counter1,1,j) = sum(condition1 == j)/size(temp2,1);                    
            end
            threeC(counter1,1,1) = sum(ismember(condition1,socialC))/size(temp2,1);
            threeC(counter1,1,2) = sum(ismember(condition1,AvoidanceC))/size(temp2,1);
            threeC(counter1,1,3) = sum(~ismember(condition1,[socialC, AvoidanceC]))/size(temp2,1);
            mouse(counter1,1) = animal(i);
        elseif temp2.session(1) == Parameters.groupName{2}
            counter2 = counter2 + 1;
            for j = cluster
                Cluster(counter2,2,j) = sum(condition2 == j)/size(temp2,1);
            end
            threeC(counter2,2,1) = sum(ismember(condition2,socialC))/size(temp2,1);
            threeC(counter2,2,2) = sum(ismember(condition2,AvoidanceC))/size(temp2,1);
            threeC(counter2,2,3) = sum(~ismember(condition2,[socialC, AvoidanceC]))/size(temp2,1);
            mouse(counter2,2) = animal(i);
        end
    end
    
    ClusterFinal{n} = Cluster;
    threeCFinal{n} = threeC;

    figure
    for i = 1:length(cluster)
        temp = Cluster(:,:,i);
        subplot(ceil(numClusters/4),4,i)
        HaoBarErrorbar(temp(:,1), temp(:,2));
        set(gca,'xticklabel',{Parameters.groupName{1}, Parameters.groupName{2}})
        ylabel("Proportion", 'FontSize', 12)
        title("Cluster " + string(i))
        ylim([0 0.5])

        [H,P,CI,STATS{i}] = ttest2(temp(:,1), temp(:,2));
        STATS{i}.pvalue = P;

        xLimits = xlim;
        yLimits = ylim;

        text((xLimits(2)/2),(yLimits(2)*.92),["p: " + num2str(STATS{i}.pvalue)],'Color',[.5 .5 .5]);
        if P < 0.05
            text((xLimits(2)/2),(yLimits(2)*.82),["tstat: " + num2str(STATS{i}.tstat)],'Color',[.5 .5 .5]);
            text((xLimits(2)/2),(yLimits(2)*.72),["df: " + num2str(STATS{i}.df)],'Color',[.5 .5 .5]);
            text((xLimits(2)/2),(yLimits(2)*.62),["sd: " + num2str(STATS{i}.sd)],'Color',[.5 .5 .5]);
        end
    end
    sgtitle(strcat(Parameters.combineCohort(n)," - ", type))

    a = ["Social","Avoidance","Other"];

    if ~isempty(socialC)
        figure
        for i = 1:size(threeC,3)
            temp = threeC(:,:,i);
            subplot(1,3,i)
            HaoBarErrorbar(temp(:,1), temp(:,2));
            set(gca,'xticklabel',{Parameters.groupName{1}, Parameters.groupName{2}})
            ylabel("Proportion", 'FontSize', 12)
            title("Cluster " + string(a(i)))
            ylim([0 1])

            [H,P,CI,STATS{i}] = ttest2(temp(:,1), temp(:,2));
            STATS{i}.pvalue = P;

            xLimits = xlim;
            yLimits = ylim;

            text((xLimits(2)/2),(yLimits(2)*.92),["p: " + num2str(STATS{i}.pvalue)],'Color',[.5 .5 .5]);
            if P < 0.05
                text((xLimits(2)/2),(yLimits(2)*.82),["tstat: " + num2str(STATS{i}.tstat)],'Color',[.5 .5 .5]);
                text((xLimits(2)/2),(yLimits(2)*.72),["df: " + num2str(STATS{i}.df)],'Color',[.5 .5 .5]);
                text((xLimits(2)/2),(yLimits(2)*.62),["sd: " + num2str(STATS{i}.sd)],'Color',[.5 .5 .5]);
            end
        end
        sgtitle(strcat(Parameters.combineCohort(n)," - ", type))
    end
end
