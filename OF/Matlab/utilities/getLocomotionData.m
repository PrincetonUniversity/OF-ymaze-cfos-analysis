function [] = getLocomotionData(groups,out_path)
% GETLOCOMOTIONDATA: Get locomotion bouts from the data and store them in a
% mat file
%
% Input: 
% - groups: experimental groups of interest
% - out_path: path to processed data

n_groups = length(groups);

joints = cell(1,n_groups);
behaviors = cell(1,n_groups);
tracks = cell(1,n_groups);

% load joint data (in box), behaviors and centroid tracks in OF
for g = 1:n_groups
    StatesPath = [out_path 'k100/' groups{g} '.mat'];
    load(StatesPath,'dataLEAPout','dataTracks'); 
    load([out_path '6states/' groups{g} '.mat'],'wr_by_day');
    wr_by_day = vertcat(wr_by_day{:})';
    nframes = length(wr_by_day{1,1});
    joints{g} = cellfun(@(x) x(:,:,1:nframes), dataLEAPout,'UniformOutput',false);
    behaviors{g} = wr_by_day;
    tracks{g} = cellfun(@(x) x(1:nframes,:), dataTracks,'UniformOutput',false);
end

joints_by_bout = cell(1,n_groups);
tracks_by_bout = cell(1,n_groups);
ids_by_bout = cell(1,n_groups);

for g = 1:length(joints)
    disp(groups{g})
    joints_all = cell(size(joints{g}));
    tracks_all = cell(size(joints{g}));
    ids_all = cell(size(joints{g}));
    for m = 1:size(joints{g},1)
        for d = 1:size(joints{g},2)
            data = behaviors{g}{m,d};
            % select locomotion behavior
            ids_loco = (data == 6);
            CC = bwconncomp(ids_loco);
            n_samples = CC.NumObjects;
            
            % get phases of selected behavior (sorted by longest to
            % shortest)
            joints_tmp = cell(1,sum(n_samples));
            tracks_tmp = cell(1,sum(n_samples));
            ids_tmp = cell(1,sum(n_samples));

            for i = 1:n_samples
                lengths = cellfun(@(x) length(x), CC.PixelIdxList);
                if max(lengths) < 50
                    break
                end
                idx = find(lengths == max(lengths),1); % first index
                ids = CC.PixelIdxList(idx);
                ids = ids{1};
                CC.PixelIdxList(idx) = [];
                
                ids_tmp{i} = ids;
                joints_tmp{i} = joints{g}{m,d}(:,:,ids);
                tracks_tmp{i} = tracks{g}{m,d}(ids,:);
            end
            ids_tmp = ids_tmp(cellfun(@(x) ~isempty(x), ids_tmp));
            joints_tmp = joints_tmp(cellfun(@(x) ~isempty(x), joints_tmp));
            tracks_tmp = tracks_tmp(cellfun(@(x) ~isempty(x), tracks_tmp));
            joints_all{m,d} = joints_tmp;
            ids_all{m,d} = ids_tmp;
            tracks_all{m,d} = tracks_tmp;
        end
    end
    joints_by_bout{g} = joints_all;
    tracks_by_bout{g} = tracks_all;
    ids_by_bout{g} = ids_all;
end
save([out_path 'locomotion_data.mat'],'joints_by_bout','tracks_by_bout','ids_by_bout')

end
