function [phases,vels,pawpos] = processDataPolarPlot(joints,tracks,pixel_size,fps)
% PROCESSDATAPOLARPLOT: calculate stride measurements for one bout of
% locomotion; right front paw is reference paw
%
% Input: 
% - joints: body part positions 
% - tracks: centroid positions 
% - pixel_size: pixel size (in mm)
% - fps: frames per second
%
% Output: 
% - phases: phases of the peak y-positions of the paws for each stride
% - vels: mean centroid velocity during stride
% - pawpos: paw positions for each stride

% get animal centered coordinates
joints_centered = findP1Center(joints,1,true);

% find peaks in the data 7 (LF), 8 (RF), 14 (LH), 15 (RH) - toe positions
LF = joints_centered(7+18,:);
RF = joints_centered(8+18,:);
LH = joints_centered(14+18,:);
RH = joints_centered(15+18,:);

% resample data at higher rate using lowpass interpolation
LF_us = interp(LF,100);
RF_us = interp(RF,100);
LH_us = interp(LH,100);
RH_us = interp(RH,100);
tracks_us = [interp(tracks(:,1),100),interp(tracks(:,2),100)];

% z-scoring of data
LF_us = zscore(LF_us); 
RF_us = zscore(RF_us); 
LH_us = zscore(LH_us); 
RH_us = zscore(RH_us);
                
[pks_LF,locs_LF] = findpeaks(LF_us,'MinPeakHeight',0,'MinPeakProminence',0.5);
[pks_RF,locs_RF] = findpeaks(RF_us,'MinPeakHeight',0,'MinPeakProminence',0.5);
[pks_LH,locs_LH] = findpeaks(LH_us,'MinPeakHeight',0,'MinPeakProminence',0.5);
[pks_RH,locs_RH] = findpeaks(RH_us,'MinPeakHeight',0,'MinPeakProminence',0.5);

% plot peak detection results
% figure()
% for i = [5 6 7 8]
%     plot(joints_centered(i+13,:))
%     hold on 
% end
% scatter(locs_LF,pks_LF)
% hold on
% scatter(locs_RF,pks_RF)
% hold on
% scatter(locs_LH,pks_LH)
% hold on
% scatter(locs_RH,pks_RH)

% find phases (RF is the reference paw)
phases = NaN(length(locs_RF)-1,4); % RF, LF, RH, LH
pawpos = cell(length(locs_RF)-1,1);
for i = 1:(length(locs_RF)-1)
    ids = locs_RF(i):locs_RF(i+1);
    len = length(ids);
    start = ids(1);
    inter_LF = intersect(ids,locs_LF);
    inter_LH = intersect(ids,locs_LH);
    inter_RH = intersect(ids,locs_RH);
    if (length(inter_LF) == 1 && length(inter_LH) == 1 && length(inter_RH) == 1)
        phase_LF = (inter_LF-start)/len*2*pi;
        phase_LH = (inter_LH-start)/len*2*pi;
        phase_RH = (inter_RH-start)/len*2*pi;
        phases(i,:) = [0,phase_LF,phase_RH,phase_LH];
        pawpos{i} = [LF_us(ids)',RF_us(ids)',LH_us(ids)',RH_us(ids)'];
    end
end

% find centroid velocity during stride
vels = NaN(length(locs_RF)-1,1); 
for i = 1:(length(locs_RF)-1)
    ids = locs_RF(i):locs_RF(i+1);
    track = tracks_us(ids,:);
    vel = sqrt(sum(diff(track,1).^2,2))*pixel_size*fps*100/1000; % in m/s
    vels(i) = mean(vel);
%     if mean(vel) > 0.5
%         disp('check')
%         figure()
%         plot(vel)
%         figure()
%         scatter(track(:,1),track(:,2))
%         figure()
%         plot(LF_us(ids))
%         hold on 
%         plot(RF_us(ids))
%         hold on 
%         plot(LH_us(ids))
%         hold on 
%         plot(RH_us(ids))       
%     end
end

% delete NaNs
del = all(isnan(phases),2);
phases = phases(~del,:);
vels = vels(~del);
pawpos = pawpos(~del);

end
