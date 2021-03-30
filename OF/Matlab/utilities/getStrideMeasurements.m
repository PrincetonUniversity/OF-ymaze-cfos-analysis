function [stride_data_all] = ...
    getStrideMeasurements(allJointsSLEAPSmoothed,allTracks,pixel_size,fps)
% GETSTRIDEMEASUREMENTS: save stride measurements for bouts of locomotion
% into structs
%
% Input:
% - allJointsSLEAPSmoothed: joints
% - allTracks: tracks
% - pixel_size: pixel size (in mm)
% - fps: frames per second
%
% Output:
% - stride_data_all: cell array with structs containing the stride
% measurements

stride_data_all = cell(1,length(allJointsSLEAPSmoothed));

% process data for all bouts and return measurements
for g = 1:length(allJointsSLEAPSmoothed)
    stride_data = struct('day',{},'mouse',{},'bout',{},'phases',{},'vels',{});
    disp(['group = ', num2str(g)])
    for m = 1:size(allJointsSLEAPSmoothed{g},1)
        for d = 1:size(allJointsSLEAPSmoothed{g},2)
            disp(['mouse = ' num2str(m) ', day = ' num2str(d)])
            joints = allJointsSLEAPSmoothed{g}{m,d};
            tracks = allTracks{g}{m,d};
            for i = 1:length(joints) % for all bouts
                [phases,vels,~] = processDataPolarPlot(joints{i},tracks{i},pixel_size,fps); 
                if ~isempty(phases)
                    s = struct('day',d,'mouse',m,'bout',i,'phases',phases,'vels',vels);
                    stride_data = [stride_data;s];
                end
            end
        end
    end
    stride_data_all{g} = stride_data;
end
end