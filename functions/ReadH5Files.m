function [intruder,flag] = ReadH5Files(Parameters,fileIdentifier,groupIdentifier)

dir_h5 = Parameters.H5;
groupName = Parameters.groupName;
intruderLabel = Parameters.intruderLabel;
residentLabel = Parameters.residentLabel;

cd (dir_h5)
h5files = dir("*.h5*");
intruder = {};
flag = false;


if ~isempty(fileIdentifier)
    for i = 1:size(h5files,1)
    temp(i) = contains(h5files(i).name,fileIdentifier);
    end
    h5files = h5files(temp);
end

for i = 1:length(h5files)
    fprintf("\nFile %i of %i\n", i, length(h5files));
    file = h5files(i).name;
    
    intruder{i}.track_names = h5read(file, '/track_names');
    intruder{i}.instance_scores = h5read(file, '/instance_scores');    
    intruder{i}.node_names = h5read(file, '/node_names');
    intruder{i}.point_scores = h5read(file, '/point_scores');    
    intruder{i}.track_occupancy = h5read(file, '/track_occupancy');
    intruder{i}.point_scores = h5read(file, '/point_scores');
    intruder{i}.tracking_scores = h5read(file, '/tracking_scores');
    intruder{i}.tracks = h5read(file, '/tracks');

    % remove all the unsigned instances
    idx = contains(intruder{i}.track_names,intruderLabel) | contains(intruder{i}.track_names,residentLabel);
    if sum(idx) > 2
        warning("Check intruder and resident labels in the H5 file " + i + " " + file)
        flag = true;
        break
    end

    intruder{i}.track_names = intruder{i}.track_names(idx);
    intruder{i}.instance_scores = intruder{i}.instance_scores(:,idx);
    intruder{i}.point_scores = intruder{i}.point_scores(:,:,idx);
    intruder{i}.track_occupancy = intruder{i}.track_occupancy(idx,:);
    intruder{i}.point_scores = intruder{i}.point_scores(:,idx);
    intruder{i}.tracking_scores = intruder{i}.tracking_scores(:,idx);
    intruder{i}.tracks = intruder{i}.tracks(:,:,:,idx);
    
    % add additional info.
    intruder{i}.file = file;
%     intruder{i}.sessionID = string(extractBefore(file, method)); 
    
    if isempty(groupIdentifier)
        for n = 1:length(groupName)
            gn = groupName{n};
            idxx{n} = contains(intruder{i}.file,gn,IgnoreCase=true);
        end
        intruder{i}.session = cell2mat(groupName(logical(cell2mat(idxx))));
        if isempty(intruder{i}.session)
            intruder{i}.session = groupName;
        end
    else  
        intruder{i}.session = cell2mat(groupName(groupIdentifier(i)));
    end
  
end

