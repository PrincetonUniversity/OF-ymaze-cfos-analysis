function joints_centered = findP1Center(joints,span,up)
% FINDP1CENTER: center body parts with respect to tailbase and align them
% to the direction from tailbase to position along body 
%
% Input: 
% - joints: joint positions (18 x 2 x n_frames)
% - span: number of frames to use for smoothing (if span = 1: no
% smoothing)
% - up: boolean - if true, the mouse is aligned with positive y axis,
% otherwise negative y axis
%
% Output: 
% - joints_centered: centered (w.r.t. tailbase), rotated (w.r.t. line between tailbase and body position) 
% and smoothed joint positions (36 x n_frames with 18 x-positions and 18 y-positions stacked together)

tailP = double(squeeze(joints(16,:,:))); % tailbase position
centerP = double(squeeze(joints(9,:,:))); % position along body axis

% subtract the tailbase position from all joint positions in joints --> position
% relative to tailbase
tP = zeros(18,2,size(joints,3));
tP(:,1,:) = repmat(tailP(1,:),[18,1,1]);
tP(:,2,:) = repmat(tailP(2,:),[18,1,1]);
tP1 = double(joints)-double(tP);

% convert cartesian coordinates to polar coordinates
tP2 = zeros(size(tP1));
for i  = 1:length(tailP) % number of frames
    [tP2(:,1,i), tP2(:,2,i)] = cart2pol(tP1(:,1,i),tP1(:,2,i)); % angle, radius
end

% get rotation of mouse in radiant (defined by line between tailbase and center)
rotDir = zeros(length(tailP),1);
for i = 1:length(tailP)
    xtemp = tailP(:,i)-centerP(:,i);
    rotDir(i) = deg2rad(rem(atan2d(xtemp(1),xtemp(2))+360,360));
end

% rotate all joint positions by entry in rotDir and convert back to
% cartesian coordinates
tP3 = zeros(size(tP2));
for i = 1:length(tailP)
    if up
        degtemp = tP2(:,1,i) + repmat(rotDir(i)+pi,[18 1]);
    else
        degtemp = tP2(:,1,i) + repmat(rotDir(i),[18 1]);
    end
    [tP3(:,1,i), tP3(:,2,i)] = pol2cart(degtemp,tP2(:,2,i)); % angle in radians
end

% smooth the trajectories for each joint
tP4 = zeros(size(tP3));
for i = 1:18
    tP4(i,1,:) = smooth(tP3(i,1,:),span);
    tP4(i,2,:) = smooth(tP3(i,2,:),span);
end

joints_centered = reshape(tP4,[36 size(tP3,3)]);
end