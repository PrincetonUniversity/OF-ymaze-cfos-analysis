function [] = makeInfoFiles(data_path,out_path,sH)
% MAKEINFOFILES: create mat files with infos for 100 and M different
% classes (M: number of classes in sH);
% ensures that the same frame number is used for all recordings of the mice
% in the selected groups
%
% Input: 
% - data_path: path to data from cluster analysis 
% - out_path: path where mat files are saved
% - sH: mapping to M <= 100 number of clusters

%% get data

% load data sets
load([data_path 'miceIDs.mat'],'group_by_day'); % group names of mice
load([data_path 'filenames.mat'],'files_by_day'); % file names of experiments

% access data without loading the whole data set into memory
allcGuesses = matfile([data_path 'allcGuesses.mat']);
allLEAPout = matfile([data_path 'allLEAPOUT.mat']);
allTracks = matfile([data_path 'allTracks.mat']);

% groups of interest
groups = {'C57Bl','AcuteVehicleonly2D','AcuteCNOonly2D','AcuteCNOnLobVI1D','AcuteCNOnCrusIRT2D','AcuteCNOnCrusILT2D',...
    'AcuteCNOnCrusI2D','AcuteCNOnmcherry2D','L7-Cre-Tsc1'};

%% write k100 mat files

if ~exist([out_path 'k100/'],'dir')
    mkdir([out_path 'k100/'])
end

M = max(sH);

if ~exist([out_path num2str(M) 'states/'],'dir')
    mkdir([out_path num2str(M) 'states/'])
end

for i = 1:length(groups)
    disp(groups{i})
    % paths to save .mat files
    matfilePath = [out_path 'k100/' groups{i} '.mat'];
        
    % get dataDC (if file does not exist, generate and save 100 state info file)
    if ~exist(matfilePath,'file')
        % find data for the specific group in the data set
        indices = cellfun(@(x) strcmp(x,groups{i}), group_by_day);
        [row,~] = find(indices);
        grouptoanalyze = unique(row)'; % indices of the rows that correspond to the specific group name
        
        % we consider the first two days only
        d = 2;
        
        file_ids = files_by_day(grouptoanalyze,1:d);
        
        [dataDC, dataLEAPout, dataTracks] = loadGroup100HDK(grouptoanalyze, d, allcGuesses, allLEAPout, allTracks);
        save(matfilePath,'dataDC','dataLEAPout','dataTracks','file_ids','-v7.3');
        clear dataLEAPout dataTracks
    end
end

%% get minimal number of frames such that the data sets in Mstates/ all consider the same recording time
    
nframes = cell(1,length(groups));
for i = 1:length(groups)
    matfilePath = [out_path 'k100/' groups{i} '.mat'];
    load(matfilePath,'dataDC')
    nframes{i} = unique(cellfun(@(x) size(x,1),dataDC));
    clear dataDC
end
maxframe = min(vertcat(nframes{:}));

%% create Mstate files

for i = 1:length(groups)
    disp(groups{i})
    matfilePath = [out_path 'k100/' groups{i} '.mat'];
    MStatesPath = [out_path num2str(M) 'states/' groups{i} '.mat'];
    load(matfilePath,'dataDC','file_ids')
    % generate and save M-state info file
    if ~exist(MStatesPath,'file')
        saveMstateInfo(MStatesPath,dataDC,sH,file_ids,maxframe);
    end
end

end
