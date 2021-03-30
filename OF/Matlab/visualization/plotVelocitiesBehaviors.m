function [] = plotVelocitiesBehaviors(groups,fig_path,out_path,MSortedLabels,M,fps,pixel_size)
% PLOTVELOCITIESBEHAVIOR: plot boxplot of centroid velocities for each
% behavior including all animals in 'groups'
%
% Input:
% - groups: experimental groups of interest
% - fig_path: path to save figure
% - out_path: path to processed data
% - MSortedLabels: labels for M behavioral classes
% - M: number of behavioral classes
% - fps: frames per second
% - pixel_size: pixel size (in mm)

if ~exist(fig_path,'dir')
    mkdir(fig_path)
end

%% get the data

wr = cell(1,length(groups));
vels_tracks = cell(1,length(groups));
for g = 1:length(groups)
    StatesPath = [out_path 'k' num2str(100) '/' groups{g} '.mat'];
    load(StatesPath,'dataTracks');
    load([out_path '6states/' groups{g} '.mat'],'wr_by_day_loco');
    
    wr{g} = vertcat(wr_by_day_loco{:})';
    
    % calculate velocities
    vels_tracks{g} = cellfun(@(x) getVelocity(x,1,fps,pixel_size),dataTracks,'UniformOutput',false);
end

%% get velocities per behavior (collect the velocities for all frames in this behavior)
vels_tracks_behaviors = cell(1,M);
for i = 1:M
    vels_tmp = [];
    for g = 1:length(groups)
        for m = 1:size(wr{g},1)
            for d = 1:size(wr{g},2)
                vels_tmp = [vels_tmp; vels_tracks{g}{m,d}(wr{g}{m,d} == i)];
            end
        end
    end
    vels_tracks_behaviors{i} = vels_tmp;
end

median_vels = cellfun(@median,vels_tracks_behaviors);
disp(MSortedLabels)
disp(median_vels)

behaviors = arrayfun(@(x) repmat(x,length(vels_tracks_behaviors{x}),1),1:length(vels_tracks_behaviors),'UniformOutput',false);
behaviors = vertcat(behaviors{:});
vels_tracks_behaviors = vertcat(vels_tracks_behaviors{:});

%% plot boxplot of velocities per behavior
f = figure;
f.Units = 'centimeters';
f.Position = [10,10,7,4.5];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

b = boxplot(vels_tracks_behaviors,behaviors); 

% do not show outliers
h = findobj(b,'tag','Outliers');
delete(h)
set(findobj(gcf,'LineStyle','--'),'LineStyle','-')

% delete horizontal line at end of whiskers
h = findobj(gcf,'tag','Lower Adjacent Value');
delete(h)
h = findobj(gcf,'tag','Upper Adjacent Value');
delete(h)

% Change the boxplot color to black
a = get(get(gca,'children'),'children');
set(a, 'Color', 'k');
    
ylim([-0.01 0.4])
ylabel('Velocity (m/s)')
xticks(1:M)
xticklabels(MSortedLabels)
xtickangle(45)
prepfig()

print(gcf,[fig_path 'Figure_SI_1/velocities_for_each_behavior'],'-dpdf','-r0')
close(gcf)

end