function smoothed_vels_tracks = getVelocity(tracks,smoothing,fps,pixel_size)
% GETVELOCITY: get smoothed centroid velocity of the animal
%
% INPUT:
% - tracks: trajectory (nframes x 2)
% - smoothing: window size of gaussian filter (in number of frames)
% - fps: frames per second
% - pixel_size: pixel size (in mm)
%
% Output:
% - smoothed_vels_tracks: smoothed centroid velocity

diffs_tracks = diff(tracks,1);

% calculating the norm of the velocity between frames and then smooth the data 
vels_tracks = vecnorm(diffs_tracks,2,2); % 2-norm, along 2nd dim
smoothed_vels_tracks = smoothdata(vels_tracks,1,'gaussian',smoothing); 

% add first value to beginning 
smoothed_vels_tracks = [smoothed_vels_tracks(1); smoothed_vels_tracks]*fps*pixel_size/1000; % in m/s

end