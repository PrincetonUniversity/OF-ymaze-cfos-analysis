function [median_vel,mean_vel,vels,inner_time,inner_vel,outer_vel,crossings,total_distance] = ...
    getSpatialInfosOF(group,out_path,pixel_size,fps,M)
% GETSPATIALINFOSOF: calculate open field metrics
% 
% Input:
% - group: experimental group of interest
% - out_path: path to processed data
% - pixel_size: pixel size (in mm)
% - fps: frames per second
% - M: number of behavioral classes
%
% Output:
% - median_vel: median velocity of the mouse during locomotion
% - mean_vel: mean velocity of the mouse during locomotion
% - vels: vector with velocities of the mouse during locomotion
% - inner_time: fraction of time spent in inner part of the arena
% - inner_vel: median velocity in inner part of the arena during locomotion
% - outer_vel: median velocity in outer part of the arena during locomotion
% - crossings: number of crossings between inner / outer part
% - total_distance: total distance travelled


mfile = matfile([out_path 'k100/' group '.mat']);
tracks = mfile.('dataTracks');

MStatesfile = matfile([out_path num2str(M) 'states/' group '.mat']);
wrAll = MStatesfile.('wr_by_day');

[n_mice, n_days] = size(tracks);

median_vel = NaN(n_mice,n_days);
mean_vel = NaN(n_mice,n_days); 
vels = cell(n_mice,n_days); 
inner_time = NaN(n_mice,n_days); 
inner_vel = NaN(n_mice,n_days); 
outer_vel = NaN(n_mice,n_days); 
crossings = NaN(n_mice,n_days); 
total_distance = NaN(n_mice,n_days); 

for i = 1:n_mice
    for j= 1:n_days
        if all(all(~isnan(tracks{i,j}))) % no nan value
            % track positions
            tt = tracks{i,j};
            wr = wrAll{j}{i};
            
            % cut track positions to same length as wr (such that all
            % experiments considered have the same length)
            tt = tt(1:length(wr),:);
            
            % smooth the x- and y-coordinates of the trajectory
            tt(:,1) = smooth(tt(:,1),12); % 12-point moving average
            tt(:,2) = smooth(tt(:,2),12);
            
            % velocities
            t2 = diff(tt);
            t3 = sqrt((t2(:,1)).^2+(t2(:,2)).^2);
            
            total_distance(i,j) = sum(t3)*pixel_size*0.001; % in m
            
            % median and mean velocity during locomotion (in m/s)
            locomotion = ismember(wr,6);
            median_vel(i,j) = median(t3(locomotion(1:end-1)))*pixel_size*0.001*fps; 
            mean_vel(i,j) = mean(t3(locomotion(1:end-1)))*pixel_size*0.001*fps; 
            
            % velocities during locomotion
            vels{i,j} = t3(locomotion(1:end-1))*pixel_size*0.001*fps; % in m/s
            
            % measurements for inner and outer region
            limx = [min(tt(:,1))+150 max(tt(:,1))-150];
            limy = [min(tt(:,2))+150 max(tt(:,2))-150];           
            
            % plot to check the inner / outer regions
%             figure()
%             plot(tt(:,1),tt(:,2))
%             hold on
%             line([limx(1) limx(2)],[limy(1) limy(1)],'Color','k','LineWidth',2);
%             line([limx(2) limx(2)],[limy(1) limy(2)],'Color','k','LineWidth',2);
%             line([limx(2) limx(1)],[limy(2) limy(2)],'Color','k','LineWidth',2);
%             line([limx(1) limx(1)],[limy(2) limy(1)],'Color','k','LineWidth',2);
%             line([min(tt(:,1)) max(tt(:,1))],[min(tt(:,2)) min(tt(:,2))],'Color','k','LineWidth',2);
%             line([max(tt(:,1)) max(tt(:,1))],[min(tt(:,2)) max(tt(:,2))],'Color','k','LineWidth',2);
%             line([max(tt(:,1)) min(tt(:,1))],[max(tt(:,2)) max(tt(:,2))],'Color','k','LineWidth',2);
%             line([min(tt(:,1)) min(tt(:,1))],[max(tt(:,2)) min(tt(:,2))],'Color','k','LineWidth',2);
%             xlim([min(tt(:,1)) max(tt(:,1))]);
%             ylim([min(tt(:,2)) max(tt(:,2))]);
%             axis equal off
%             saveas(gcf,'../Figures/Additional_Figures/example_inner_outer_region.png')
%             close(gcf)
            
            index_inner = (tt(:,1)>limx(1) & tt(:,1)<limx(2) & tt(:,2)>limy(1) & tt(:,2)<limy(2));
            index_outer = (tt(:,1)<limx(1) | tt(:,1)>limx(2) | tt(:,2)<limy(1) | tt(:,2)>limy(2));
            
            inner_time(i,j) = sum(index_inner)/size(tt,1); % fraction of time in inner area
            
            % median velocity in inner and outer region (all behaviors!)
            inner_vel(i,j) = median(t3(index_inner(1:end-1)))*pixel_size*0.001*fps; % in m/s
            outer_vel(i,j) = median(t3(index_outer(1:end-1)))*pixel_size*0.001*fps;
            % vector with +1 if crossing from outer to inner and -1 if
            % crossing from inner to outer region
            crossing = diff(index_inner);
            crossings(i,j) = size(find(crossing>0.5),1)/size(tt,1)*(fps*60); % number of crossings from outer to inner (in 1/min)
            clear tt t2 t3 index_inner index_outer
        end
    end
end

end