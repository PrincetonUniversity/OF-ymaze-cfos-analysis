function [joints_OF] = convertToRealCoordinates(joints,trafoinfo)
% CONVERTTOREALCOORDINATES: convert body part coordinates (joints) in box
% to coordinates in open field arena
%
% Input:
% - joints: body part coordinates relative to box (njoints x 2 x nframes)
% - trafoinfo: information about box coordinates
% 
% Output:
% - joints_OF: corresponding body part coordinates in open field arena

tempc = trafoinfo.centroidsF; 
tempr = deg2rad(trafoinfo.rotVal);

% translate joint coordinates to center of box
tempCents = 200*ones(size(joints));
midJoints = double(joints)-tempCents;
jx = double(squeeze(midJoints(:,1,:)));
jy = double(squeeze(midJoints(:,2,:)));

n_joints = size(joints,1);
n_frames = size(joints,3);

if n_joints == 1
    jx = jx';
    jy = jy';
end

% calculate coordinates in open field
joints_OF = zeros(size(joints));

for i = 1:n_frames
    ang = zeros(n_joints,1);
    rad = zeros(n_joints,1);
    xnew = zeros(n_joints,1);
    ynew = zeros(n_joints,1);
    % conversion to polar coordinates
    [ang(:), rad(:)] = cart2pol(jx(:,i)',jy(:,i)'); % output: [angle, radius]
    % add rotation angle to angle coordinates
    ang(:) = ang(:) + repmat(tempr(i),[n_joints 1]);
    % conversion back to cartesian coordinates
    [xnew(:), ynew(:)] = pol2cart(ang(:),rad(:));
    % translate coordinates 
    joints_OF(:,1,i) = xnew(:) + tempc(i,1);
    joints_OF(:,2,i) = ynew(:) + tempc(i,2);
end

end