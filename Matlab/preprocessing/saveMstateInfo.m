function [] = saveMstateInfo(MStatesPath,dataDC,sH,file_ids,maxframe)
% SAVEMSTATEINFO: calculate observables for M-state predictions and save in
% mat file for further analysis and visualization
%
% Input: 
% - MStatesPath: path to save the data
% - dataDC: data obtained from behavioral clustering (100 clusters)
% - sH: mapping to M <= 100 number of clusters
% - file_ids: file ids of the experiments considered
% - maxframe: maximal number of frames considered for each recording (to
% include data of the same length for all groups)

[n,d] = size(dataDC); % n = number of animals; d = number of days
M = max(sH); % number of behavioral classes

% initialize cell arrays
wr_by_day = cell(1,d);
wr100_by_day = cell(1,d);
T_by_day = cell(1,d);
TF_by_day = cell(1,d);
allTs_by_day = cell(1,d);
allTstateDefs_by_day = cell(1,d);

ALDCs = cell(n,d);
for i = 1:n
    for j=1:d
        ALDCs{i,j} = dataDC{i,j};
    end
end

% cut frames such that all frames are the same length
ALDCs = cellfun(@(x) x(1:maxframe), ALDCs,'UniformOutput', false);

disp(['number of mice (included in analysis): ' num2str(n)])

for day = 1:d    
    % calculate quantities we want to save
    wr = cell(1,n);
    wr100 = cell(1,n);
    for i = 1:n
        wr_tmp = sH(ALDCs{i,day}); % sH containes info to assign to M clusters
        % majority filtering to get rid of very short behaviors
        wr_new = zeros(size(wr_tmp));
        for j = 1:length(wr_tmp)
            if j < 6
                wr_new(j) = wr_tmp(j);
            elseif j > length(wr_tmp)-5
                wr_new(j) = wr_tmp(j);
            else
                wr_new(j) = mode(wr_tmp(j-5:j+5));
            end
        end
        wr{i} = wr_new;
        wr100{i} = ALDCs{i,day};
    end
    
    [T,~,TF,allTs,~,allTstateDefs] = findTransitionMatrixC_HD(wr,true,true,M);
    
    % save results into cell array
    wr_by_day{day} = wr;
    wr100_by_day{day} = wr100;
    T_by_day{day} = T;
    TF_by_day{day} = TF;
    allTs_by_day{day} = allTs;
    allTstateDefs_by_day{day} = allTstateDefs;
    
    clear wr wr100 T TF allTs allTstateDefs
end

% save data to file
save(MStatesPath,'wr_by_day','wr100_by_day','T_by_day','TF_by_day','allTs_by_day','allTstateDefs_by_day','file_ids');

% - wr_by_day: for each day: data with classes in [1:M]
% - wr100_by_day: for each day: data with classes in [1:100]
% - T_by_day: for each day: average over the transition matrices for all mice when weighting p_ij by the probability of mouse m to be in
% state i
% - TF_by_day: for each day: average transition matrix column-wise multiplied with averaged probability density
% - allTs_by_day: for each day: cell array with transition matrices for all mice
% - allTstateDefs_by_day: states that occur in allTs_by_day (this
% information is necessary if not all behavioral classes occur in the data
% set and therefore the transition matrix does not have the full size; then
% allTstateDefs gives the classes the data in transition matrix belongs to)
% - file_ids: file ids of the experiments considered
end
