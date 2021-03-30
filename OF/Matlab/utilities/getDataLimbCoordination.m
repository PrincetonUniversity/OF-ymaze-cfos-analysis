function [] = getDataLimbCoordination(out_path,pixel_size,fps)
% GETDATALIMBCOORDINATION: generate the data set for each single stride from
% the locomotion data set
%
% Input: 
% - out_path: path to processed data
% - pixel_size: pixel size (in mm)
% - fps: frames per second

% load locomotion data 
load([out_path 'locomotion_data.mat'],'joints_by_bout','tracks_by_bout')

% smooth data
for g = 1:length(joints_by_bout)
    for i = 1:size(joints_by_bout{g},1)
        for j = 1:size(joints_by_bout{g},2)
            % smooth data using Gaussian filter
            joints_by_bout{g}{i,j} = cellfun(@(x) smoothdata(x,3,'gaussian',5), joints_by_bout{g}{i,j},'UniformOutput', false);
        end
    end
end

%% Get measurements per stride

if ~exist([out_path 'stride_measurements.mat'],'file')
    % generate the data set
    stride_data_RF = ...
        getStrideMeasurements(joints_by_bout,tracks_by_bout,pixel_size,fps);
    
    % save data
    save([out_path 'stride_measurements.mat'],'stride_data_RF')
end

end