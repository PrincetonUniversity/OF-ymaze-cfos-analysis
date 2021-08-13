function [] = compareSpatialDistribution(groups,labels,fig_path,out_path,M,MSortedLabels)
% COMPARESPATIALDISTRIBUTION: plot probability distribution of time spent
% in OF arena for different experimental groups
%
% Input:
% - groups: experimental groups of interest
% - labels: labels for groups
% - fig_path: path to save figure
% - out_path: path to processed data
% - M: number of behavioral classes

%% get track data

tracks_all = cell(1,length(groups));
wr_all = cell(1,length(groups));
for g = 1:length(groups)
    MStatesfile = matfile([out_path num2str(M) 'states/' groups{g} '.mat']);
    wr_tmp = MStatesfile.('wr_by_day');
    wr_tmp = vertcat(wr_tmp{:})';
    wr_all{g} = wr_tmp;
    
    mfile = matfile([out_path 'k100/' groups{g} '.mat']);
    tracks = mfile.('dataTracks');
    for i = 1:size(tracks,1)
        for j = 1:size(tracks,2)
            tracks{i,j} = tracks{i,j}(1:numel(wr_tmp{i,j}),:);
        end
    end
    tracks_all{g} = tracks;
end

%% center tracks (the camera field of view is slightly different in the videos)
% to center the images, we consider the histogram of x and y values and
% position the peaks in the distribution symmetrically around zero

% tracks_centered_all_old = cell(size(tracks_all));
% for g = 1:numel(tracks_all)
%     tracks_centered_all_old{g} = cell(size(tracks_all{g}));
%     for m = 1:size(tracks_all{g},1)
%         for d = 1:size(tracks_all{g},2)
%             track = tracks_all{g}{m,d};
%             track_centered = zeros(size(track));
%             [f,xi] = ksdensity(track(:,1));
%             [~,locs] = findpeaks(f,xi,'MinPeakDistance',500);
%             track_centered(:,1) = track(:,1)-mean(locs);
%             [f,xi] = ksdensity(track(:,2));
%             [~,locs] = findpeaks(f,xi,'MinPeakDistance',500);
%             track_centered(:,2) = track(:,2)-mean(locs);
%             tracks_centered_all_old{g}{m,d} = track_centered;
%             disp(['g = ' num2str(g) ', m = ' num2str(m) ', d = ' num2str(d) ': ' num2str(diff(locs))])
%         end
%     end
% end

% center track w.r.t. mean of max / min positions
tracks_centered_all = cell(size(tracks_all));
for g = 1:numel(tracks_all)
    tracks_centered_all{g} = cell(size(tracks_all{g}));
    for m = 1:size(tracks_all{g},1)
        for d = 1:size(tracks_all{g},2)
            track = tracks_all{g}{m,d};
            offset_x = mean([min(track(:,1)) max(track(:,1))]);
            offset_y = mean([min(track(:,2)) max(track(:,2))]);
            track_centered = zeros(size(track));
            track_centered(:,1) = track(:,1)-offset_x;
            track_centered(:,2) = track(:,2)-offset_y;
            tracks_centered_all{g}{m,d} = track_centered;
        end
    end
end


% for g = 1:numel(groups)
%     for d = 1:2
%         figure()
%         tiledlayout(1,3)
%         nexttile
%         for m = 1:size(tracks_all{g},1)
%             p = plot(tracks_all{g}{m,d}(:,1),tracks_all{g}{m,d}(:,2));
%             p.Color(4) = 0.2;
%             hold on
%         end
%         title('tracks original')
%         set(gca,'DataAspectRatio',[1 1 1])
%         
%         nexttile
%         for m = 1:size(tracks_centered_all{g},1)
%             p = plot(tracks_centered_all{g}{m,d}(:,1),tracks_centered_all{g}{m,d}(:,2));
%             p.Color(4) = 0.2;
%             hold on
%         end
%         title('tracks centered (min / max)')
%         set(gca,'DataAspectRatio',[1 1 1])
%         
%         nexttile
%         for m = 1:size(tracks_centered_all_old{g},1)
%             p = plot(tracks_centered_all_old{g}{m,d}(:,1),tracks_centered_all_old{g}{m,d}(:,2));
%             p.Color(4) = 0.2;
%             hold on
%         end
%         title('tracks centered (peaks)')
%         set(gca,'DataAspectRatio',[1 1 1])
%     end
% end

% 
% figure('Position',[500,500,1200,200])
% tiledlayout(2,size(tracks_centered_all{g},1))
% for d = 1:2
%     for m = 1:size(tracks_centered_all{g},1)
%         nexttile
%         plot(tracks_centered_all{g}{m,d}(:,1),tracks_centered_all{g}{m,d}(:,2));
%         set(gca,'PlotBoxAspectRatio',[1 1 1])
%         axis off
%     end
% end

%% plot distribution - Day 1
f = figure;
f.Units = 'centimeters';
f.Position = [10,10,30,16];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(numel(groups),M);
t.Padding = 'compact';
t.TileSpacing = 'compact';

for g = 1:numel(tracks_centered_all)
    tracks = vertcat(tracks_centered_all{g}{:,1}); % first day
    behs = horzcat(wr_all{g}{:,1});
    for c = 1:M
        nexttile
        h = histcounts2(tracks(behs == c,1),tracks(behs == c,2),linspace(-500,500,100),linspace(-500,500,100),'Normalization','pdf');
        imagesc(h)
        cb = colorbar('FontSize',10);
        if c == max(M)
            ylabel(cb,'pdf','FontSize',12)
        end
        if c == 1
            ylabel(labels{g},'FontSize',12)
            set(gca,'xtick',[])
            set(gca,'ytick',[])
        else
            axis off
        end
        if g == 1
            title(MSortedLabels{c},'FontSize',12,'FontWeight','normal')
        end
        set(gca,'PlotBoxAspectRatio',[1 1 1])
    end
end

%% save the figure
fig_name = [fig_path 'Additional_Figures/spatial_distributions_by_behavior_and_group_day1'];
print(gcf,[fig_name '.pdf'],'-dpdf','-r0');
close(gcf)

%% plot distribution - Day 2
f = figure;
f.Units = 'centimeters';
f.Position = [10,10,30,16];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(numel(groups),M);
t.Padding = 'compact';
t.TileSpacing = 'compact';

for g = 1:numel(tracks_centered_all)
    tracks = vertcat(tracks_centered_all{g}{:,2}); % second day
    behs = horzcat(wr_all{g}{:,2});
    for c = 1:M
        nexttile
        h = histcounts2(tracks(behs == c,1),tracks(behs == c,2),linspace(-500,500,100),linspace(-500,500,100),'Normalization','pdf');
        imagesc(h)
        cb = colorbar('FontSize',10);
        if c == max(M)
            ylabel(cb,'pdf','FontSize',12)
        end
        if c == 1
            ylabel(labels{g},'FontSize',12)
            set(gca,'xtick',[])
            set(gca,'ytick',[])
        else
            axis off
        end
        if g == 1
            title(MSortedLabels{c},'FontSize',12,'FontWeight','normal')
        end
        set(gca,'PlotBoxAspectRatio',[1 1 1])
    end
end

%% save the figure
fig_name = [fig_path 'Additional_Figures/spatial_distributions_by_behavior_and_group_day2'];
print(gcf,[fig_name '.pdf'],'-dpdf','-r0');
close(gcf)

end