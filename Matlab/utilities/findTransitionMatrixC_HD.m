function [bigallT, allTallDensities, bigAll_flux, allTs, allTdensities, allTstateDefs] ...
    = findTransitionMatrixC_HD(WR, eliminateZeros, eliminateSelfTransitions, M)
% FINDTRANSITIONMATRIXC_HD: calculate transition matrices for ensemble of
% ethograms (e.g. different mice)
%
% Input:
% - WR: class data, cell array of shape 1xn
% - eliminateZeros: boolean, if true, delete states that are 0
% - eliminateSelfTransitions: boolean, if true, only consider different states and
% not the duration of the states, otherwise use each frame
% - M: number of classes
%
% Output: 
% - bigallT: average over the transition matrices for all mice when weighting p_ij by the probability of mouse m to be in
% state i
% - allTallDensities: average probability distribution of classes
% - bigAll_flux: average transition matrix column-wise multiplied with averaged probability density
% - allTs: cell array with transition matrices for all mice
% - allTdensities: cell array with probability densities for all mice
% - allTstateDefs: cell array with class numbers for all mice

% If there are behavioral classes == 0
allStates = cell(size(WR));
for i = 1:length(WR)
    CC = bwconncomp(WR{i}==0);
    a = WR{i};
    for j = 1:CC.NumObjects
        % if the interval extends until the end of the recording interval
        if CC.PixelIdxList{j}(end)==length(a)
            % set the values which are zero to the value just before the
            % interval of zeros
            a(CC.PixelIdxList{j}) = a(CC.PixelIdxList{j}(1)-1);
        else
            % set the valus which are zero to the value just after the
            % interval of zeros
            a(CC.PixelIdxList{j}) = a(CC.PixelIdxList{j}(end)+1);
        end
    end
    allStates{i} = a;
end

% initialize cell arrays to store results
allTs = cell(1,size(allStates,2));
allTdensities = cell(1,size(allStates,2));
allTstateDefs = cell(1,size(allStates,2));

% calculate the transition rates for all mice separately
for i = 1:length(allStates)
    % allTs: transition matrices 
    % allTdensities: probability densities 
    % allTstateDefs: class numbers
    [allTs{i}, allTdensities{i}, allTstateDefs{i}] = findTransitionMatrix(allStates{i}', eliminateZeros, eliminateSelfTransitions);
end

% initialize arrays for average transition rates and densities (averaged
% over all mice)
bigallT = zeros(M);
allTallDensities = zeros(M,1);

for i = 1:length(allStates)
    % multiply the probability density for the current state with the transition 
    % probability to go from the current to the next state for each mouse
    F = bsxfun(@times,allTs{i},allTdensities{i});
    % add up the transition fluxes and densities 
    bigallT(allTstateDefs{i},allTstateDefs{i}) = bigallT(allTstateDefs{i},allTstateDefs{i}) + F;
    allTallDensities(allTstateDefs{i}) = allTallDensities(allTstateDefs{i}) + allTdensities{i};
end

% normalize such that rows of bigallT sum to 1 (the result is the same as taking the average
% over all transition probabilities for all mice when weighting p_ij by the probability of mouse m to be in
% state i)
% note: here, sum(bigallT,2) = allTallDensities
bigallT = bsxfun(@rdivide, bigallT, sum(bigallT,2)); 
% normalize such that allTallDensities sum to 1
% note: sum(allTallDensities) = number of mice
allTallDensities = allTallDensities ./ sum(allTallDensities);
bigallT(isnan(bigallT)) = 0;
% to get the fluxes, multiply transition matrix with averaged probability density
bigAll_flux = bsxfun(@times, bigallT, allTallDensities); 

end