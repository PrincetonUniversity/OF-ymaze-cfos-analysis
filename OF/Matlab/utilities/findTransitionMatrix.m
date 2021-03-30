function [T,densities,stateDefs,states,numTransitions] = findTransitionMatrix(states,eliminateZeros,eliminateSelfTransitions)
% FINDTRANSITIONMATRIX: calculate transition matrix for one ethogram
%
% Input:
% - states: vector with classes (dimension nx1)
% - eliminateZeros: if true, delete states that are 0
% - eliminateSelfTransitions: if true, only consider different states and
% not the duration of the states, otherwise use each frame
%
% Output:
% - T: transition matrix (rows sum to one)
% - densities: probability densities for each state
% - stateDefs: states that occur in the data set 'states' in ascending
% order
% - states: vector of classes after processing (zeros might be deleted and
% durations of states set to 1)
% - numTransitions: total number of transitions included in the calculation
% of the transition matrix

% if eliminateSelfTransitions is not set, set it to true
if nargin < 3 || isempty(eliminateSelfTransitions)
    eliminateSelfTransitions = true;
end

% if eliminateZeros is not set, set it to true
if nargin < 2 || isempty(eliminateZeros)
    eliminateZeros = true;
end

% make sure states is a column vector
if size(states,1) == 1
    states = states';
end

% stateDefs: stores the unique class numbers in ascending order
stateDefs = sort(unique(states));
% delete states that are zero (if there are any)
if eliminateZeros
    stateDefs = setdiff(stateDefs,0);
    states = states(states ~= 0);
end
% number of classes that occur in the data set
L = length(stateDefs);

% only consider states and not frames (i.e. neglect the duration of a
% state)
if eliminateSelfTransitions
    % a: boolean vector that is true at positions where the class changed
    % from previous to current frame
    a = [true; abs(diff(states)) > 0];
    % get the classes at these positions
    states = states(a);
end

% initialization
T = zeros(L);
densities = zeros(L,1);
N = length(states); % index of last state in vector states
numTransitions = 0;

for i=1:L
    % find indices where a certain class occurs (excluding an
    % occurrence as the last state)
    idx = setdiff(find(states==stateDefs(i)),N);
    % densities: save the number of times a class occurs (NOTE: this does not take into account the durations)
    densities(i) = length(idx);
    % next states of the class 'stateDefs(i)', i.e. where it transitions
    % into
    vals = states(idx + 1);
    
    % sum up number of transitions
    numTransitions = numTransitions + length(vals);
    
    % calculate transition probabilities and save in row of transition matrix T
    for j=1:L
        T(i,j) = sum(vals == stateDefs(j))./length(vals);
    end
    
end
% normalize densities to make it a probability distribution
densities = densities ./ sum(densities);

end