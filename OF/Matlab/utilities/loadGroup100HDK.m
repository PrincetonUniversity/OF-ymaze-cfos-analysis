function [dataDC,dataLEAPout,dataTracks] = loadGroup100HDK(grouptoanalyze,d,allcGuesses,allLEAPout,allTracks)
% LOADGROUP100HDK: get data for specific group
%
% Input:
% - grouptoanalyze: indices of the rows in the data sets that correspond to
% the specific group of interest
% - d: number of days considered
% - allcGuesses: mat file with behavioral classes
% - allLEAPout: mat file with LEAP joints
% - allTracks: mat file with centroid positions
%
% Output:
% - dataDC: behavioral classes in [1:100]
% - dataLEAPout: joint positions from LEAP
% - dataTracks: centroid positions of mice

n = length(grouptoanalyze); % number of animals

dataDC = cell(n,d); 
dataLEAPout = cell(n,d); 
dataTracks = cell(n,d);  

for i = 1:n
    disp([num2str(i) '/' num2str(n)])
    for j = 1:d
        cGuesses = allcGuesses.('allcGuesses')(grouptoanalyze(i),j);
        cGuesses = cGuesses{1};
        LEAPout = allLEAPout.('positions_pred_by_day')(grouptoanalyze(i),j);
        LEAPout = LEAPout{1};
        Tracks = allTracks.('allTracks')(grouptoanalyze(i),j);
        Tracks = Tracks{1};
        
        if isempty(cGuesses)
            dataDC{i,j} = [];
            dataLEAPout{i,j} = [];
            dataTracks{i,j} = [];
        else
            dataDC{i,j} = cGuesses(:,1);
            dataLEAPout{i,j} = LEAPout;
            dataTracks{i,j} = Tracks;
        end
    end
end

clear cGuesses LEAPout Tracks

end
