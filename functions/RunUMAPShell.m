function [data,data_labels] = RunUMAPShell(intruder,Parameters,MakeUMAPtemplate,RunUMAP,PlotUMAPVideo, dataFilter)
cd(Parameters.save_dir)

%%% concatenate files from all conditions for UMAP
data = [];
data_labels = [];
totalFramesinVideo = [];
for i = 1:size(Parameters.combineData_dir,1)
    if ~isempty(dataFilter)
        df = dataFilter{i};
    else
        df = [];
    end
    [temp1, temp2] = PrepUMAP(intruder, Parameters.featuresUMAP, Parameters.epochWindow, Parameters.combineCohort, df, i);
    data = [data; temp1];
    data_labels = [data_labels; temp2];
end

%%% Making a UMAP templete
if MakeUMAPtemplate == 1
    for i = 1:size(Parameters.templateIdx,2)
        idx1(i,:) = contains(data_labels.intruder, Parameters.templateIdx(1,i),IgnoreCase=true);
        idx2(i,:) = contains(data_labels.session, Parameters.templateIdx(2,i),IgnoreCase=true);
        idx3(i,:) = contains(data_labels.sessionType, Parameters.templateIdx(3,i),IgnoreCase=true);
    end
    idx1 = sum(idx1,1);
    idx1 = idx1 ~=0;
    idx2 = sum(idx2,1);
    idx2 = idx2 ~=0;    
    idx3 = sum(idx3,1);
    idx3 = idx3 ~=0;

    idx = idx1 & idx2 & idx3;
    data_template = data(idx,:);
    
    [~, umap, ~] = run_umap(data_template, 'match_supervisors', 1);
    cd(Parameters.UMAPtemp_dir)
    save(Parameters.templateName, 'umap');
end

%%% run UMAP on actual data
if RunUMAP == 1
    cd(Parameters.UMAPtemp_dir)
    [reduction,umap,clusterIds]=run_umap(data, 'cluster_output', 'graphic',...
        'template_file', Parameters.templateName,...
        'randomize', false,...
        'cluster_detail', Parameters.ClusterDetail);
    grid off
    data_labels.UMAP = reduction;
    data_labels.Cluster = clusterIds';
    cd(Parameters.save_dir)
    save(strcat(Parameters.cohort,'_UMAPData.mat'), 'data_labels', 'data', 'Parameters');
end

%%% make videos for each cluster
if PlotUMAPVideo == 1
    cd(Parameters.save_dir)
    load(strcat(Parameters.cohort,'_UMAPData.mat'));
    MakeClusterVideo(data_labels, intruder, Parameters);
    close all
end