function [intruder] = ExtractSleapFeatures(intruder, gaussSmooth, interpolation, Parameters)

residentLabel = Parameters.residentLabel;
intruderLabel = Parameters.intruderLabel;
bodyPart = Parameters.bodyPart;

nose = bodyPart(1);
head = bodyPart(2);
body = bodyPart(3);
butt = bodyPart(4);

for sesh = 1:length(intruder)
    rng(1)
    fprintf('\nWorking on Video %i of %i\n', sesh, length(intruder));

    %     If there are multiple animals, the dimensions of the "tracks" matrix are:
    %     (frame#, node #, x/y coordinates, instance)

    %INTERPOLATION CODE GOES HERE
    if interpolation == 1
        for i = 1:size(intruder{sesh}.track_occupancy,1) % iterate through each animal
            for ii = 1:size(intruder{sesh}.node_names, 1) % iterate through each node
                for iii = 1:2 % iterate through x and y

                    % find the length of missing tracks
                    frame_min = min(find(intruder{sesh}.track_occupancy(i,:)));
                    frame_max = max(find(intruder{sesh}.track_occupancy(i,:)));

                    intruder{sesh}.tracks_interp(frame_min:frame_max,ii,iii,i) = interp1(intruder{sesh}.tracks(frame_min:frame_max,ii,iii,i), 1:frame_max-frame_min+1, 'pchip');

                end
            end
        end

        intruder{sesh}.tracks = intruder{sesh}.tracks_interp;
    end
    % End interpolation code

    % first, smooth points
    intruder{sesh}.tracks_smooth = smoothdata(intruder{sesh}.tracks, 1, 'sgolay', 5);

    % if we want to use smoothed tracks
    if gaussSmooth == 1
        intruder{sesh}.tracks = intruder{sesh}.tracks_smooth;
    end
    intruder{sesh}.track_names = deblank(intruder{sesh}.track_names); % Fix whitespace error in SLEAP h5 export

    residentIdx = find(contains(intruder{sesh}.track_names, residentLabel,IgnoreCase=true));
    intIdx = find(contains(intruder{sesh}.track_names, intruderLabel,IgnoreCase=true));

    % Frames containing both resident and different intruders
    int_frames = find(intruder{sesh}.track_occupancy(residentIdx,:) == 1 & intruder{sesh}.track_occupancy(intIdx,:) == 1);

    all_tracks = {int_frames}';

    intruder{sesh}.int_frames = int_frames;

    for v = 1:length(all_tracks) % Going through each intruder

        %         Specify Intruder type

        if v == 1
            intruderFrames = int_frames;
            intruderIdx = intIdx;
        end

        if isempty(intruderFrames) % skip no tracking vids (e.g. aggressive male, ended early)
            continue
        end

        temp_tracks = all_tracks{v};
        tempTrack = struct;

        % Calculate head and body centroids
        res_body = intruder{sesh}.tracks(intruderFrames,[body,butt],:, residentIdx);
        res_head = intruder{sesh}.tracks(intruderFrames,[nose,head],:, residentIdx);
        int_body = intruder{sesh}.tracks(intruderFrames,[body,butt],:, intruderIdx);
        int_head = intruder{sesh}.tracks(intruderFrames,[nose,head],:, intruderIdx);

        tempTrack.res_body_cent = permute(mean(res_body,2),[1,3,2]);
        tempTrack.res_head_cent = permute(mean(res_head,2),[1,3,2]);
        tempTrack.int_body_cent = permute(mean(int_body,2),[1,3,2]);
        tempTrack.int_head_cent = permute(mean(int_head,2),[1,3,2]);

        % Initialize matrices
        tempTrack.head_dist = zeros(length(intruderFrames),1);
        tempTrack.angle_heads = zeros(length(intruderFrames),1);
        tempTrack.res_body_dist = zeros(length(intruderFrames),1);
        tempTrack.res_angle_body = zeros(length(intruderFrames),1);
        tempTrack.res_butt_dist = zeros(length(intruderFrames),1);
        tempTrack.res_angle_butt = zeros(length(intruderFrames),1);
        tempTrack.int_body_dist = zeros(length(intruderFrames),1);
        tempTrack.int_angle_body = zeros(length(intruderFrames),1);
        tempTrack.int_butt_dist = zeros(length(intruderFrames),1);
        tempTrack.int_angle_butt = zeros(length(intruderFrames),1);
        tempTrack.res_major_axis_len = zeros(length(intruderFrames),1);
        tempTrack.res_minor_axis_len = zeros(length(intruderFrames),1);
        tempTrack.res_axis_ratio = zeros(length(intruderFrames),1);
        tempTrack.int_major_axis_len = zeros(length(intruderFrames),1);
        tempTrack.int_minor_axis_len = zeros(length(intruderFrames),1);
        tempTrack.int_axis_ratio = zeros(length(intruderFrames),1);

        fprintf("\nVideo %i, Intruder %i: NumFrames: %i\n", sesh, v, length(intruderFrames));

        for i = 1:length(intruderFrames)

            frame = intruderFrames(i);

            if i > 1
                tempTrack.res_velocity(i,1) = sqrt((tempTrack.res_body_cent(i,1) - tempTrack.res_body_cent(i-1,1))^2 + (tempTrack.res_body_cent(i,2) - tempTrack.res_body_cent(i-1,2))^2);
                tempTrack.int_velocity(i,1) = sqrt((tempTrack.int_body_cent(i,1) - tempTrack.int_body_cent(i-1,1))^2 + (tempTrack.int_body_cent(i,2) - tempTrack.int_body_cent(i-1,2))^2);
            elseif i == 1
                tempTrack.res_velocity(1) = 0;
                tempTrack.int_velocity(1) = 0;
            end
            % Coordinates for intruder's head, butt, and body
            int_head = [intruder{sesh}.tracks(frame,head,1,intruderIdx), intruder{sesh}.tracks(frame,head,2,intruderIdx)];
            int_butt = [intruder{sesh}.tracks(frame,butt,1,intruderIdx), intruder{sesh}.tracks(frame,butt,2,intruderIdx)];
            int_body = [intruder{sesh}.tracks(frame,body,1,intruderIdx), intruder{sesh}.tracks(frame,body,2,intruderIdx)];
            int_nose = [intruder{sesh}.tracks(frame,nose,1,intruderIdx), intruder{sesh}.tracks(frame,nose,2,intruderIdx)];

            % Coordinates for resident's head, butt, and body
            res_body = [intruder{sesh}.tracks(frame,body,1,residentIdx), intruder{sesh}.tracks(frame,body,2,residentIdx)]; %P0
            res_head = [intruder{sesh}.tracks(frame,head,1,residentIdx), intruder{sesh}.tracks(frame,head,2,residentIdx)]; %P1
            res_nose = [intruder{sesh}.tracks(frame,nose,1,residentIdx), intruder{sesh}.tracks(frame,nose,2,residentIdx)]; %P1
            res_butt = [intruder{sesh}.tracks(frame,butt,1,residentIdx), intruder{sesh}.tracks(frame,butt,2,residentIdx)]; %P1

            % Distance between RESIDENT'S head and INTRUDER'S body parts
            head_dist = sqrt((int_head(1) - res_head(1))^2 + (int_head(2) - res_head(2))^2);
            %             res_body_dist = sqrt((int_body(1) - res_head(1))^2 + (int_body(2) - res_head(2))^2); % Resident head to intruder body
            %             res_butt_dist = sqrt((int_butt(1) - res_head(1))^2 + (int_butt(2) - res_head(2))^2); % Resident head to intruder butt
            res_body_dist = sqrt((int_body(1) - res_nose(1))^2 + (int_body(2) - res_nose(2))^2); % Resident nose to intruder body
            res_butt_dist = sqrt((int_butt(1) - res_nose(1))^2 + (int_butt(2) - res_nose(2))^2); % Resident nose to intruder butt

            % Distance between RESIDENT'S butt and INTRUDER's butt
            butt_dist = sqrt((int_butt(1) - res_butt(1))^2 + (int_butt(2) - res_butt(2))^2);

            % Vector from RESIDENT'S body to RESIDENT'S head
            res_n2 = (res_head - res_body) / norm(res_head - res_body);

            % Vector from RESIDENT'S head to INTRUDER'S head
            n1_heads = (int_head - res_head) / norm(int_head - res_head);  % Normalized vectors
            angle_heads = (atan2(norm(det([res_n2; n1_heads])), dot(n1_heads, res_n2)));

            % Vector from RESIDENT'S head to INTRUDER'S body
            n1_body = (int_body - res_head) / norm(int_body - res_head);  % Normalized vectors
            res_angle_body = (atan2(norm(det([res_n2; n1_body])), dot(n1_body, res_n2)));

            % Vector from RESIDENT'S head to INTRUDER'S butt
            n1_butt = (int_butt - res_head) / norm(int_butt - res_head);  % Normalized vectors
            res_angle_butt = (atan2(norm(det([res_n2; n1_butt])), dot(n1_butt, res_n2)));

            % Distance between INTRUDER'S head and RESIDENT'S body parts
            %             int_body_dist = sqrt((res_body(1) - int_head(1))^2 + (res_body(2) - int_head(2))^2); % Intruder head to resident body
            %             int_butt_dist = sqrt((res_butt(1) - int_head(1))^2 + (int_butt(2) - int_head(2))^2); % Intruder head to resident butt
            int_body_dist = sqrt((res_body(1) - int_nose(1))^2 + (res_body(2) - int_nose(2))^2); % Intruder nose to resident body
            int_butt_dist = sqrt((res_butt(1) - int_nose(1))^2 + (int_butt(2) - int_nose(2))^2); % Intruder nose to resident butt

            % Vector from INTRUDER'S body to INTRUDER'S head
            int_n2 = (int_head - int_body) / norm(int_head - int_body);

            % Vector from INTRUDER'S head to RESIDENT'S body
            n1_body = (res_body - int_head) / norm(res_body - int_head);  % Normalized vectors
            int_angle_body = (atan2(norm(det([int_n2; n1_body])), dot(n1_body, int_n2)));

            % Vector from INTRUDER'S head to RESIDENT'S butt
            n1_butt = (res_butt - int_head) / norm(res_butt - int_head);  % Normalized vectors
            int_angle_butt = (atan2(norm(det([int_n2; n1_butt])), dot(n1_butt, int_n2)));



            %             tempTrack.head_dist = [tempTrack.head_dist; head_dist];
            tempTrack.head_dist(i,1) = head_dist;
            tempTrack.angle_heads(i,1) = angle_heads;

            tempTrack.res_body_dist(i,1) = res_body_dist;
            tempTrack.res_angle_body(i,1) = res_angle_body;

            tempTrack.res_butt_dist(i,1) = res_butt_dist;
            tempTrack.res_angle_butt(i,1) = res_angle_butt;

            tempTrack.int_body_dist(i,1) = int_body_dist;
            tempTrack.int_angle_body(i,1) = int_angle_body;

            tempTrack.int_butt_dist(i,1) = int_butt_dist;
            tempTrack.int_angle_butt(i,1) = int_angle_butt;

            tempTrack.butt_dist(i,1) = butt_dist;

            %             features = [features; head_dist, angle_heads, res_body_dist, res_angle_body, res_butt_dist, res_angle_butt];

            % Calculate major/minor axis of ellipse fit to RESIDENT'S body
            try
                res_ellipseTemp = fit_ellipse(intruder{sesh}.tracks(frame,[nose,head,body,butt],1, residentIdx), intruder{sesh}.tracks(frame,[nose,head,body,butt],2, residentIdx));
                int_ellipseTemp = fit_ellipse(intruder{sesh}.tracks(frame,[nose,head,body,butt],1, intruderIdx), intruder{sesh}.tracks(frame,[nose,head,body,butt],2, intruderIdx));
                if strcmp(res_ellipseTemp.status, 'Hyperbola found') == 1
                    continue
                elseif strcmp(int_ellipseTemp.status, 'Hyperbola found') == 1
                    continue
                else
                    tempTrack.res_major_axis_len(i,1) = res_ellipseTemp.long_axis;
                    tempTrack.res_minor_axis_len(i,1) = res_ellipseTemp.short_axis;
                    tempTrack.res_axis_ratio(i,1) = res_ellipseTemp.long_axis/res_ellipseTemp.short_axis;
                    tempTrack.int_major_axis_len(i,1) = int_ellipseTemp.long_axis;
                    tempTrack.int_minor_axis_len(i,1) = int_ellipseTemp.short_axis;
                    tempTrack.int_axis_ratio(i,1) = int_ellipseTemp.long_axis/int_ellipseTemp.short_axis;
                end
            catch
            end
        end

        % Change in distance between mice's heads
        tempTrack.head_dist_change = [0;diff(tempTrack.head_dist)];

        % Change in distance between RESIDENT'S head and INTRUDER'S body
        tempTrack.res_body_dist_change = [0;diff(tempTrack.res_body_dist)];

        % Change in distance between RESIDENT'S head and INTRUDER'S butt
        tempTrack.res_butt_dist_change = [0;diff(tempTrack.res_butt_dist)];

        % Change in distance between INTRUDER'S head and RESIDENT'S body
        tempTrack.int_body_dist_change = [0;diff(tempTrack.int_body_dist)];

        % Change in distance between INTRUDER'S head and RESIDENT'S butt
        tempTrack.int_butt_dist_change = [0;diff(tempTrack.int_butt_dist)];

        % Calculate absolute orientation of RESIDENT
        temp_dir = [];
        temp_dir = tempTrack.res_head_cent - tempTrack.res_body_cent;
        direction_scaled = temp_dir./vecnorm(temp_dir,2,2);
        tempTrack.res_phi = cart2pol (direction_scaled(:,1), direction_scaled(:,2));

        % Calculate absolute orientation of INTRUDER
        temp_dir = [];
        temp_dir = tempTrack.int_head_cent - tempTrack.int_body_cent;
        direction_scaled = temp_dir./vecnorm(temp_dir,2,2);
        tempTrack.int_phi = cart2pol (direction_scaled(:,1), direction_scaled(:,2));

        % Calculate orientation of nose relative to head of RESIDENT
        temp_dir = [];
        temp_dir = permute(intruder{sesh}.tracks(intruderFrames,1,:, residentIdx) - intruder{sesh}.tracks(intruderFrames,2,:, residentIdx),  [1,3,2]);
        direction_scaled = temp_dir./vecnorm(temp_dir,2,2);
        tempTrack.res_ori_head = cart2pol(temp_dir(:,1), temp_dir(:,2));

        % Calculate orientation of nose relative to head of INTRUDER
        temp_dir = [];
        temp_dir = permute(intruder{sesh}.tracks(intruderFrames,1,:, intruderIdx) - intruder{sesh}.tracks(intruderFrames,2,:, intruderIdx),  [1,3,2]);
        direction_scaled = temp_dir./vecnorm(temp_dir,2,2);
        tempTrack.int_ori_head = cart2pol(temp_dir(:,1), temp_dir(:,2));

        % Calculate orientation of head relative to tail base of RESIDENT
        temp_dir = [];
        temp_dir = permute(intruder{sesh}.tracks(intruderFrames,2,:, residentIdx) - intruder{sesh}.tracks(intruderFrames,4,:, residentIdx),  [1,3,2]);
        direction_scaled = temp_dir./vecnorm(temp_dir,2,2);
        tempTrack.res_ori_body = cart2pol(temp_dir(:,1), temp_dir(:,2));

        % Calculate orientation of head relative to tail base of INTRUDER
        temp_dir = [];
        temp_dir = permute(intruder{sesh}.tracks(intruderFrames,2,:, intruderIdx) - intruder{sesh}.tracks(intruderFrames,4,:, intruderIdx),  [1,3,2]);
        direction_scaled = temp_dir./vecnorm(temp_dir,2,2);
        tempTrack.int_ori_body = cart2pol(temp_dir(:,1), temp_dir(:,2));

        % Calculate turning angle of RESIDENT
        tempTrack.res_turning_angle = tempTrack.res_ori_head - tempTrack.res_ori_body;

        % Calculate turning angle of INTRUDER
        tempTrack.int_turning_angle = tempTrack.int_ori_head - tempTrack.int_ori_body;

        % Calculate angular velocity of RESIDENT
        tempTrack.res_ang_vel = [0; diff(tempTrack.res_phi)];

        % Calculate angular velocity of INTRUDER
        tempTrack.int_ang_vel = [0; diff(tempTrack.int_phi)];

        feature_names = fieldnames(tempTrack);
        features = table();
        for i = 1:length(feature_names)
            features = addvars(features, getfield(tempTrack, feature_names{i}), 'NewVariableNames', feature_names{i});
        end

        tempTrack.features = features;

        if v == 1
            intruder{sesh}.Intruder = tempTrack;
        end
    end

end

% % Convert USV call start times to ethovision frames
% for i = 1:length(intruder)
%     residentIdx = find(contains(intruder{i}.track_names, "resident"));
%     intruderIdx = find(contains(intruder{i}.track_names, "intruder"));
%
%     trial = extractBefore(intruder{i}.file, "_cleaned");
%     vidpath = "V:\TCoSI2\02_Processing\ethovision\02_Cropped";
%
%     tempVidFile = string();
%     video_dir = dir(fullfile(vidpath, sprintf("%s*", trial)));
%     tempVidFile = fullfile(video_dir.folder, video_dir.name);
%
%     intruder{i}.vidFile = tempVidFile;
%
%     disp(tempVidFile)
%     v = VideoReader(tempVidFile);
%     duration = v.Duration;
%
%     if sum(contains(fieldnames(intruder{i}),'USV'))
%         fprintf('\n%s, %s, Juvenile USVs\n', intruder{i}.animal, intruder{i}.session);
%         tempUSV = intruder{i}.USV;
%         USVtimeconv = linspace(0,duration,size(intruder{i}.instance_scores, 1)); % duration of video, number of frames
%         USVstart = [];
%         for ii = 1:height(tempUSV)
%             [~,tempUSVstart] = min(abs(tempUSV.Start_time(ii) - USVtimeconv));
%             USVstart = [USVstart;tempUSVstart];
%         end
%         intruder{i}.USVframes = intersect(USVstart, intruder{i}.int_frames);
%     end
% end





