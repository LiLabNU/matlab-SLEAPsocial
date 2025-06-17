%% Video with thresholds
function BehThresholdVideo(intruder, features, dist_thresh, angle_thresh, timeThresh, Parameters)

%tempVidFile = intruder.vidFile;
tempVidFile = fullfile(intruder.vidpath, intruder.sessionID) + intruder.vidFormat;
figure(1);
set(gcf, 'Color', 'w');
disp(tempVidFile)
v = VideoReader(tempVidFile);
% figure(101)

intruder.Intruder.res_body_dist = getfield(intruder.Intruder, features(1));
intruder.Intruder.res_angle_body = getfield(intruder.Intruder, features(2));

count = 0;
for i = intruder.int_frames
    count = count+1;
    frame = read(v, i);
    image(frame)
    %image(imadjust(frame, [.08 .08 .08; .95 .9 .9], []))
    if size(features,2) == 2
        if intruder.Intruder.res_body_dist(count) < dist_thresh & rad2deg(intruder.Intruder.res_angle_body(count)) < angle_thresh
            viscircles([intruder.Intruder.int_body_cent(count,1), intruder.Intruder.int_body_cent(count,2)] ,dist_thresh, 'LineStyle', '--', 'Color', [0 1 0], 'EnhanceVisibility', 0);

        elseif intruder.Intruder.res_body_dist(count) > dist_thresh & rad2deg(intruder.Intruder.res_angle_body(count)) <45 & sum(intruder.Intruder.res_body_dist(count:count+timeThresh) < dist_thresh)>1
            viscircles([intruder.Intruder.int_body_cent(count,1), intruder.Intruder.int_body_cent(count,2)] ,dist_thresh, 'LineStyle', '-', 'Color', 'y', 'EnhanceVisibility', 0);

        else
            viscircles([intruder.Intruder.int_body_cent(count,1), intruder.Intruder.int_body_cent(count,2)] ,dist_thresh, 'LineStyle', '-', 'Color', 'r', 'EnhanceVisibility', 0);

        end

    elseif size(features,2) == 4
        if intruder.Intruder.res_body_dist(count) < dist_thresh & rad2deg(intruder.Intruder.res_angle_body(count)) < angle_thresh
            viscircles([intruder.Intruder.int_body_cent(count,1), intruder.Intruder.int_body_cent(count,2)] ,dist_thresh, 'LineStyle', '--', 'Color', [0 1 0], 'EnhanceVisibility', 0);

        elseif intruder.Intruder.int_body_dist(count) < dist_thresh & rad2deg(intruder.Intruder.int_angle_body(count)) < angle_thresh
            viscircles([intruder.Intruder.res_body_cent(count,1), intruder.Intruder.res_body_cent(count,2)] ,dist_thresh, 'LineStyle', '--', 'Color', [0 1 0], 'EnhanceVisibility', 0);


        elseif intruder.Intruder.res_body_dist(count) > dist_thresh & rad2deg(intruder.Intruder.res_angle_body(count)) <45 & sum(intruder.Intruder.res_body_dist(count:count+timeThresh) < dist_thresh)>1
            viscircles([intruder.Intruder.int_body_cent(count,1), intruder.Intruder.int_body_cent(count,2)] ,dist_thresh, 'LineStyle', '-', 'Color', 'y', 'EnhanceVisibility', 0);


        elseif intruder.Intruder.int_body_dist(count) > dist_thresh & rad2deg(intruder.Intruder.int_angle_body(count)) <45 & sum(intruder.Intruder.int_body_dist(count:count+timeThresh) < dist_thresh)>1
            viscircles([intruder.Intruder.res_body_cent(count,1), intruder.Intruder.res_body_cent(count,2)] ,dist_thresh, 'LineStyle', '-', 'Color', 'y', 'EnhanceVisibility', 0);

        end

    end


    %     roi = images.roi.Ellipse(gca,'Center',[intruder.Intruder.int_body_cent(count,1), intruder.Intruder.int_body_cent(count,2)],'Semiaxes',[70 50], 'RotationAngle', abs(rad2deg(intruder.Intruder.int_phi(count))));
    axis off
    title(sprintf("Interaction Demo: %s, %s, %i pixels threshold", intruder.sessionID, dist_thresh), 'FontSize', 12);
    drawnow
    F = getframe(gcf);
    frames{count} = F;
    %     cla reset
end

vid = VideoWriter(strcat(Parameters.cohort,'_ThresholdVideos'),'MPEG-4');
vid.FrameRate = intruder.intruderFrames.fps;
vid.Quality = 90;
open(vid);
for i = 1:1000
    frame = cell2mat(frames(i));
    writeVideo(vid, frame);
end
close(vid);