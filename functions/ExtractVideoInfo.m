function [intruder] = ExtractVideoInfo(intruder, Parameters)
vidpath = Parameters.vidpath; 
vidFormat = Parameters.vidFormat;
files = dir(fullfile(vidpath, '*'+vidFormat));
fileNames = {files.name};
fileNames = string(cellfun(@(x) x(1:end-4), fileNames, 'UniformOutput', false)');

intruderFrames = table;


for sesh = 1: length(intruder)
    fileName = intruder{sesh}.file;
    matchFound = false;
    for i = 1:length(fileNames)
        if contains(fileName, fileNames(i))
            intruder{sesh}.sessionID = fileNames(i);
            vidname = fileNames(i) + vidFormat;
            matchFound = true;
            break
        end
    end

    if ~matchFound
        disp(['No matched video file found for ', fileName]);
        return
    end

    tempVidFile = fullfile(vidpath, vidname);

    disp(sesh)
    disp(tempVidFile)
    v = VideoReader(tempVidFile);

    intruderFrames.Duration(sesh) = v.Duration;

    intruderFrames.Frames(sesh) = size(intruder{sesh}.instance_scores, 1);

    intruderFrames.fps(sesh) = intruderFrames.Frames(sesh)./intruderFrames.Duration(sesh);
    intruderFrames.IntEnt(sesh) = intruder{sesh}.int_frames(1);
    intruder{sesh}.intruderFrames = intruderFrames(sesh,:);
    intruder{sesh}.vidpath = vidpath;
    intruder{sesh}.vidFormat = vidFormat;
    %      intruderFrames.min_1(sesh) = intruderFrames.IntEnt(sesh) + 60*intruderFrames.fps(sesh);
    %      intruderFrames.min_2(sesh) = intruderFrames.IntEnt(sesh) + 120*intruderFrames.fps(sesh);
    %      intruderFrames.min_3(sesh) = intruderFrames.IntEnt(sesh) + 180*intruderFrames.fps(sesh);
    %     intruderFrames.min_4(sesh) = intruderFrames.IntEnt(sesh) + 240*intruderFrames.fps(sesh);
    %     intruderFrames.min_5(sesh) = intruderFrames.IntEnt(sesh) + 300*intruderFrames.fps(sesh);
end