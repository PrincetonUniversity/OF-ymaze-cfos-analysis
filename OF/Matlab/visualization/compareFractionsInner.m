function [] = compareFractionsInner(groups,labels,fig_path,out_path,M,MSortedLabels)
% COMPAREFRACTIONSINNER: plot fraction of time spent
% in inner part of OF arena for different experimental groups and behaviors
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

%% get fractions of time in inner part of the arena for each behavior

fractions_all = cell(size(tracks_centered_all));
for g = 1:numel(tracks_centered_all)
    fractions_all{g} = cell(size(tracks_centered_all{g}));
    for m = 1:size(tracks_centered_all{g},1)
        for d = 1:size(tracks_centered_all{g},2)
            track = tracks_centered_all{g}{m,d};
            wr = wr_all{g}{m,d};
            fractions = zeros(1,M);
            for b = 1:M
                track_sel = track(wr == b,:);
                % inner part of the arena is defined as square of 500 x 500
                % pixels in the middle of the arena (we use the maximal /
                % minimal values in track data to get estimate for open
                % field arena)
                inner = track_sel(:,1) > -250 & track_sel(:,1) < 250 & ...
                    track_sel(:,2) > -250 & track_sel(:,2) < 250;
                fractions(b) = sum(inner)/numel(inner);
            end
            fractions_all{g}{m,d} = fractions;
        end
    end
end

fractions_day1 = cellfun(@(x) x(:,1),fractions_all,'UniformOutput',false);
fractions_day2 = cellfun(@(x) x(:,2),fractions_all,'UniformOutput',false);

% get group ids
group_ids = arrayfun(@(x) x*ones(1,numel(fractions_day1{x})),1:numel(fractions_day1),...
    'UniformOutput',false);
group_ids = horzcat(group_ids{:});

fractions_day1_combined = vertcat(fractions_day1{:});
fractions_day1_combined = vertcat(fractions_day1_combined{:});

fractions_day2_combined = vertcat(fractions_day2{:});
fractions_day2_combined = vertcat(fractions_day2_combined{:});

%% plot fractions - Day 1
global point_size

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,20,5];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(1,M);
t.Padding = 'compact';
t.TileSpacing = 'compact';

for b = 1:M
    nexttile
    bp = boxplot(fractions_day1_combined(:,b),group_ids);
    % do not show outliers
    h = findobj(bp,'tag','Outliers');
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
    
    hold on
    
    % add data as scatter plot
    for g = 1:numel(groups)
        scatter(repmat(g,length(fractions_day1_combined(group_ids == g,b)),1)+...
            (rand(length(fractions_day1_combined(group_ids == g)),1)-0.5)/2,...
            fractions_day1_combined(group_ids == g,b),point_size,'k','filled','MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5)
        hold on 
    end

    ylim([0 0.4])
    title(MSortedLabels{b},'FontWeight','normal')
    if b == 1
        ylabel('Fraction in inner region')
    end
    xticks(1:numel(groups))
    xticklabels(labels)
    xtickangle(45)
    prepfig()
end

%% save the figure
fig_name = [fig_path 'Additional_Figures/fractions_inner_by_behavior_and_group_day1'];
print(gcf,[fig_name '.pdf'],'-dpdf','-r0');
close(gcf)

%% plot distribution - Day 2
f = figure;
f.Units = 'centimeters';
f.Position = [10,10,20,5];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(1,M);
t.Padding = 'compact';
t.TileSpacing = 'compact';

for b = 1:M
    nexttile
    bp = boxplot(fractions_day2_combined(:,b),group_ids);
    % do not show outliers
    h = findobj(bp,'tag','Outliers');
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
    
    hold on
    
    % add data as scatter plot
    for g = 1:numel(groups)
        scatter(repmat(g,length(fractions_day2_combined(group_ids == g,b)),1)+...
            (rand(length(fractions_day2_combined(group_ids == g)),1)-0.5)/2,...
            fractions_day2_combined(group_ids == g,b),point_size,'k','filled','MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5)
        hold on 
    end

    ylim([0 0.4])
    title(MSortedLabels{b},'FontWeight','normal')
    if b == 1
        ylabel('Fraction in inner region')
    end
    xticks(1:numel(groups))
    xticklabels(labels)
    xtickangle(45)
    prepfig()
end

%% save the figure
fig_name = [fig_path 'Additional_Figures/fractions_inner_by_behavior_and_group_day2'];
print(gcf,[fig_name '.pdf'],'-dpdf','-r0');
close(gcf)

end