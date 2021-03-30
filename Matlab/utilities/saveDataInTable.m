function [] = saveDataInTable(groups,days,M,out_path,save_path)
% SAVEDATAINTABLE: save data in table to be used as input in R script to perform statistical
% analyses 
%
% Input:
% - groups: experimental groups of interest
% - days: days of experiments of interest
% - M: number of behavioral classes
% - out_path: path to processed data
% - save_path: path to save table

%% load the data

probs = cell(1,length(groups));
counts = cell(1,length(groups));
counts_total = cell(1,length(groups));

for g = 1:length(groups)
    MStatesPath = [out_path num2str(6) 'states/' groups{g} '.mat'];
    load(MStatesPath,'wr_by_day_loco');
    wr_by_day = wr_by_day_loco;
    
    % calculate probabilities for each mouse on each day
    probs{g} = cellfun(@(x) cellfun(@(y) histcounts(y,'BinLimits',[1,M],'Normalization','probability','BinMethod','integer'),x,...
        'UniformOutput',false), wr_by_day,'UniformOutput',false);
    
    % calculate count of frames for each mouse on each day
    counts{g} = cellfun(@(x) cellfun(@(y) histcounts(y,'BinLimits',[1,M],'Normalization','count','BinMethod','integer'),x,...
        'UniformOutput',false), wr_by_day,'UniformOutput',false);
    
    % get total number of frames
    counts_total{g} = cellfun(@(x) cellfun(@(y) size(y,2), x,'UniformOutput',false), wr_by_day,'UniformOutput',false);
end

% get data for first 2 days
probs_day = cellfun(@(x) x(days), probs, 'UniformOutput', false);
counts_day = cellfun(@(x) x(days), counts, 'UniformOutput', false);
counts_total_day = cellfun(@(x) x(days), counts_total, 'UniformOutput', false);

%% create table (input for R)
tab = [];

for i = 1:size(probs_day,2) % group indices
    for j = 1:size(probs_day{i},2) % number of days
        for m = 1:size(probs_day{i}{j},2) % number of mice
            tab = [tab; repmat(i,M,1) repmat(m,M,1) repmat(j,M,1) (1:M)' probs_day{i}{j}{m}' counts_day{i}{j}{m}' repmat(counts_total_day{i}{j}{m},M,1)];
        end
    end
end
tab = array2table(tab,'VariableNames',{'group', 'mouse', 'day', 'class', 'prob', 'count', 'count_total'});

% give the name of the group in the table
tab.group = groups(tab.group)';

%% write table 
write(tab,save_path)

end
