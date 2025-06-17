function MakeClusterVideo(data_labels,intruderAll, Parameters)
%% Video with frames from all videos (FIXED)
intruder = {};
for i = 1:size(intruderAll,1)
    intruder = cat(2,intruder,intruderAll{i});
end

rng(1)
UMAPData = 1;
idx = double(data_labels.Cluster)'; %for UMAP'd data
numClusters = length(unique(data_labels.Cluster)); % for UMAP'd data
c1 = rand(numClusters,1);
c2 = rand(numClusters,1);
c3 = rand(numClusters,1);
colors = [c1,c2,c3]/2;
seshidx = data_labels.SessionIdx;

brightnessFactor = 0; % some value between 0 and 200
numFrames = 600;

cluster = 1:numClusters; % Select which clusters you want to view %41
frames = {};
count = 0;
% for i = 1:length(unique(idx))-1
for i = cluster    
    tempidx = find(idx == i);
%     tempFrames = find(idx == i);
%     tempFrames = nanflag(tempFrames);
    
    if UMAPData == 1
        figure(101)
        
        hold off
        scatter(data_labels.UMAP(:,1),data_labels.UMAP(:,2), 1, [0.7,0.7,0.7]);
        hold on
%         scatter(umap.embedding(idx == i,1), umap.embedding(idx == i,2), 0.5, colors(i,:));
        scatter(data_labels.UMAP(idx == i,1), data_labels.UMAP(idx == i,2), 0.5, colors(i,:));
        title(sprintf('Cluster %i', i), 'Color', colors(i,:), 'FontSize', 9)
        set(gcf, 'Color', 'w')
        pause(0.01)
    else
        figure(101)
        hold off
        scatter3(pcadata(:,1), pcadata(:,2), pcadata(:,3), 0.5, [0.7,0.7,0.7]);
        hold on
        scatter3(pcadata(idx == i,1), pcadata(idx == i,2),pcadata(idx == i,3), 0.5, colors(i,:));
        title(sprintf('Cluster %i', i), 'Color', colors(i,:), 'FontSize', 9)
        set(gcf, 'Color', 'w')
        pause(0.01)
        xlim([quantile(pcadata(:,1),.001),quantile(pcadata(:,1),.999)])
        ylim([quantile(pcadata(:,2),.001),quantile(pcadata(:,2),.999)])
        zlim([quantile(pcadata(:,3),.001),quantile(pcadata(:,3),.999)])
    end
    
    for ii = 1:min(numFrames, length(tempidx))
        count = count +1;
        figure(102)
        set(gcf, 'Color', 'w');
        tempseshID = data_labels.SessionIdx(tempidx(ii));
        tempAnimal = data_labels.animal(tempidx(ii));
        tempSession = data_labels.session(tempidx(ii));
        tempVidFile = data_labels.vidFile(tempidx(ii));
        tempVidFrame = data_labels.vidFrame(tempidx(ii));
        
        if ii == 1
            vid = VideoReader(tempVidFile);
        elseif tempseshID ~= seshidx(tempidx(ii-1))
            vid = VideoReader(tempVidFile);
            
            pause(0.05)
        end
            
        frame = read(vid, tempVidFrame)+brightnessFactor;
        
        image(frame);
        
        res_body_cent = intruder{tempseshID}.Intruder.res_body_cent(find(intruder{tempseshID}.int_frames == tempVidFrame),:);
        int_body_cent = intruder{tempseshID}.Intruder.int_body_cent(find(intruder{tempseshID}.int_frames == tempVidFrame),:);
        
        hold on
        scatter(res_body_cent(1), res_body_cent(2), 140, 'MarkerFaceColor', [0 0.5 1], 'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'None');
        scatter(int_body_cent(1), int_body_cent(2), 140, 'MarkerFaceColor', [0.5 0 1], 'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'None');
        hold off
        set(gcf, 'Color', 'w');
        axis off
        title(sprintf("Cluster %i; %s %s: Frame %i", i, tempAnimal, tempSession, tempVidFrame), 'Color', colors(i,:),'FontSize', 9);
%         waitforbuttonpress
        drawnow
        
        F = getframe(gcf);
        if i == 1
            frames{count} = F;
        else
            frames{count} = F;
        end
        
    end
    %totalFramesinVideo(i) = ii;    
end
vid = VideoWriter(strcat(Parameters.cohort,'_UMAPVideos'),'MPEG-4');
vid.FrameRate = 15;
vid.Quality = 90;
open(vid);
for i = 1:length(frames)
    frame = cell2mat(frames(i));
    writeVideo(vid, frame);
end
close(vid);