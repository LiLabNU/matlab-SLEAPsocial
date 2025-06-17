function MakeUMAPClusterVideos(data_labels)

rng(1)

clusterIdx = double(data_labels.Cluster)'; %for UMAP'd data
numClusters = length(unique(data_labels.Cluster))-1; % for UMAP'd data
c1 = rand(numClusters,1);
c2 = rand(numClusters,1);
c3 = rand(numClusters,1);
colors = [c1,c2,c3]/2;

seshidx = data_labels.SessionIdx;
animal = data_labels.animal;
session = data_labels.session;
videoFile = data_labels.vidFile;
vidFrame = data_labels.vidFrame;



brightnessFactor = 0; % some value between 0 and 200
numFrames = 60;

clusters = 1:numClusters;%1:numClusters; % Select which clusters you want to view %41

count = 0;
% for i = 1:length(unique(idx))-1

for i = clusters
    
    tempFrames = find(clusterIdx == i);
    
    v = VideoWriter("cluster" + num2str(i));
    v.FrameRate = 10;
    %vid.Quality = 90;
    
    figure(101)
    set(gcf, 'Position', get(0, 'Screensize'));
    
    subplot(1,25,[1:6])
    hold off
    scatter(data_labels.UMAP(:,1),data_labels.UMAP(:,2), [], [0.7,0.7,0.7]);
    hold on
    %       scatter(umap.embedding(idx == i,1), umap.embedding(idx == i,2), 0.5, colors(i,:));
    scatter(data_labels.UMAP(clusterIdx == i,1), data_labels.UMAP(clusterIdx == i,2), [], colors(i,:));
    %title(sprintf('Cluster %i', i), 'Color', colors(i,:), 'FontSize', 16)
    set(gcf, 'Color', 'w')
    
    
    skipFlag = 0;
    open(v);
    if length(tempFrames) > numFrames*60
        
        temp = randsample(tempFrames, numFrames);
        
    elseif length(tempFrames) > 20*60
        numFrames = 20;
        temp = randsample(tempFrames, numFrames);
    else
        skipFlag = 1;
        f = getframe(figure(101));
        title(sprintf("Cluster %i; %s %s %s: Frame %i", i, "Less than 1200 Frames"), 'Color', colors(i,:),'FontSize', 16);
        writeVideo(v, f)
        close(v)
        clear v
    end
    
    if skipFlag == 0
        
        clustercount{i} = 0;
        
        for j = 1: numFrames
            temp2 = temp(j);
            tempseshID = seshidx(temp2);
            tempAnimal = animal(temp2);
            tempSession = session(temp2);
            tempVidFile = videoFile(temp2);
%             %%%%%
%             if server == 0
%                 tempVidFile = char(tempVidFile);
%                 tempVidFile(tempVidFile=='/') = '\';
%                 tempVidFile = strrep(tempVidFile,'\nadata\snlkt\data\','Z:\');
%                 tempVidFile = strrep(tempVidFile,'ProcessedVideos','VideosWithSkeleton');
%                 tempVidFile = strrep(tempVidFile,'.mp4','.avi');
%             end
%             %%%%%
            
            if ~ismember(any(temp2:temp2+59),clustercount{i})
                vid = VideoReader(tempVidFile);
                for k = 0:59
                    temp3 = temp2 + k;
                    if temp3 < length(vidFrame)
                        tempVidFrame = vidFrame(temp3);
                        if temp3 < max(tempFrames) && tempVidFrame < vid.NumFrames && data_labels.intruder(temp3) ~= "" ...
                                && clusterIdx(temp3) == i
                            
                            count = count +1;
                            clustercount{i}(count) = tempVidFrame;
                            
                            subplot(1,25,1:6)
                            h = scatter(data_labels.UMAP(temp3,1), data_labels.UMAP(temp3,2), [], [1 1 1],'filled');
                            
                            tempIntruder = data_labels.intruder(temp3);
                            frame = read(vid, tempVidFrame) + brightnessFactor;
                            
                            subplot(1,25,7:25)
                            set(gcf, 'Color', 'w');
                            image(frame);
                            set(gcf, 'Color', 'w');
                            axis off
                            title(sprintf("Cluster %i; %s %s %s: Frame %i", i, tempAnimal, tempSession, tempIntruder, tempVidFrame), 'Color', colors(i,:),'FontSize', 10);
                            drawnow
                            
                            %         F = getframe(gcf);
                            %         if i == 1
                            %             frames{count} = F;
                            %         else
                            %             frames{count} = F;
                            %         end
                            %
                            f = getframe(figure(101));
                            writeVideo(v, f)
                            
                            sprintf("Cluster %i; %s %s %s: Frame %i", i, tempAnimal, tempSession, tempIntruder, tempVidFrame)
                            
                            set(h,'Visible','off')
                        end
                    end
                end
            end
        end
        hold off
        close(v)
        clear v
    end
    
end