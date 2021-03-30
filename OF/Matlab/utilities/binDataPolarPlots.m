function [velsBinned,phasesBinned,nBinned] = binDataPolarPlots(vels,phases,edges)
% BINDATAPOLARPLOTS: bin data in polar plots accounting for periodicity of
% the data
%
% Input:
% - vels: centroid velocities
% - phases: phases of the paws entering stance
% - edges: edges used for binning
%
% Output:
% - velsBinned: median centroid velocities per bin
% - phasesBinned: average phases per bin
% - nBinned: number of measurements per bin

vels_bins = discretize(vels,edges);
nbins = max(vels_bins);

velsBinned = NaN(nbins,1);
phasesBinned = NaN(nbins,size(phases,2));
nBinned = NaN(nbins,1);
for i = 1:nbins
    velsBinned(i) = median(vels(vels_bins == i));
    for j = 1:size(phases,2)
        data = phases(vels_bins == i,j);
        z = exp(1i.*data); % as complex number
        zmean = sum(z);
        phasesBinned(i,j) = angle(zmean);
    end
    if ~isempty(vels(vels_bins == i))
        nBinned(i) = length(vels(vels_bins == i));
    end
end
end