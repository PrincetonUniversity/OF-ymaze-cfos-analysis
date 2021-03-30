function [] = compareSpatialMetrics(groups,labels,colors,fig_path,out_path,pixel_size,fps,M)
% COMPARESPATIALMETRICS: plot total distance travelled as boxplots for
% different groups and example trajectories
%
% Input:
% - groups: experimental groups of interest
% - labels: labels for groups
% - colors: colors used for different groups
% - fig_path: path to save figure
% - out_path: path to processed data
% - pixel_size: pixel size (in mm)
% - fps: frames per second
% - M: number of behavioral classes

%% get the data

inner_time_All = cell(1,length(groups));
crossings_All = cell(1,length(groups));
total_distance_All = cell(1,length(groups));
vels_All = cell(1,length(groups));

for g = 1:length(groups)
    [~,~,vels,inner_time,~,~,crossings,total_distance] = getSpatialInfosOF(groups{g},out_path,pixel_size,fps,M);
    inner_time_All{g} = inner_time;
    crossings_All{g} = crossings;
    total_distance_All{g} = total_distance;
    vels_All{g} = vels;
end

inner_time_vec = vertcat(inner_time_All{:});
crossings_vec = vertcat(crossings_All{:});
total_distance_vec = vertcat(total_distance_All{:});

data_day1 = horzcat(inner_time_vec(:,1),crossings_vec(:,1),total_distance_vec(:,1));
data_day2 = horzcat(inner_time_vec(:,2),crossings_vec(:,2),total_distance_vec(:,2));
data = {data_day1,data_day2};

grouping = [];
ids = [];
for g = 1:length(groups)
    grouping = [grouping; repmat(g,size(inner_time_All{g},1),1)];
    ids = [ids; (1:size(inner_time_All{g},1))'];
end

titles = {'Fraction in inner region','Crossings (1/min)','Total distance traveled (m)'};

% get track data
tracks_all = cell(1,length(groups));
wr_all = cell(1,length(groups));
for g = 1:length(groups)
    mfile = matfile([out_path 'k100/' groups{g} '.mat']);
    tracks = mfile.('dataTracks');
    tracks_all{g} = tracks;
    
    MStatesfile = matfile([out_path num2str(M) 'states/' groups{g} '.mat']);
    wr_all{g} = MStatesfile.('wr_by_day');
end

%% export data for statistical analysis in R
data_exp = [[ones(size(grouping)),grouping,ids,data{1}];[2*ones(size(grouping)),grouping,ids,data{2}]];
data_exp = array2table(data_exp,'VariableNames',{'day','group','mouse','fraction_inner','crossings','tot_distance'});
writetable(data_exp,[out_path 'Classical_measures.txt'])

%% plot total distance travelled - part 1

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,10,5];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(1,2);

global point_size
global title_font_size
global axis_font_size
global legend_font_size

count = 1;
axes_all = cell(1,2);
for d = 1:2
    axes_all{count} = nexttile;
    data_tmp = data{d}(:,3); % total distance travelled
    
    b = boxplot(data_tmp,grouping);
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
    hold on
    
    if d == 1
        % save median total distance travelled to be used in the second
        % plot
        baseline = median(data_tmp(grouping == 1));
    else
        yline(baseline);
    end
    
    % add data as scatter plot
    groupids = unique(grouping);
    for g = 1:length(groupids)
        scatter(repmat(g,length(data_tmp(grouping == g)),1)+(rand(length(data_tmp(grouping == g)),1)-0.5)/2,...
            data_tmp(grouping == g),point_size,colors{g},'filled','MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5)
    end
    hold on
    
    ylims = [25 150];    
    ylim(ylims)
    
    xticks(groupids)
    xticklabels(labels)
    xtickangle(45)
    
    ax = gca;
    ax.FontSize = axis_font_size;
    prepfig()
    
    if d == 2
        title('Day 2','FontSize',11,'FontWeight','Normal')
    else
        title('Day 1','FontSize',11,'FontWeight','Normal')
    end
    count = count + 1;
    s = findobj(gca,'Type','scatter');
    uistack(s,'bottom')
end
linkaxes([axes_all{1} axes_all{2}],'xy')
ylabel(t,titles{3},'FontSize',title_font_size)

%% save the figure
if ~exist([fig_path 'Main_Figure/'],'dir')
    mkdir([fig_path 'Main_Figure/'])
end
fig_name = [fig_path 'Main_Figure/total_distance_travelled_boxplots.pdf'];
print(gcf,fig_name,'-dpdf','-r0');
close(gcf)

%% plot total distance travelled - part 2
f = figure;
f.Units = 'centimeters';
f.Position = [10,10,8,7.5];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(2,2);
t.Padding = 'compact';
t.TileSpacing = 'compact';

% get x and y limits for track plot
dat1 = tracks_all{1}{1,:};
dat2 = tracks_all{2}{6,:};
dat = [dat1;dat2];
xmin = min(dat(:,1));
xmax = max(dat(:,1));
ymin = min(dat(:,2));
ymax = max(dat(:,2));

fivemin_break = fps*5*60;

count = 1;
axes_all = cell(1,4);
for i = 1:2
    for d = 1:2
        axes_all{count} = nexttile;
        if i == 1 % plot example CNO only track on day d
            track = tracks_all{1}{1,d}; % first mouse
            plot(track(1:round(fivemin_break),1)*pixel_size,track(1:round(fivemin_break),2)*pixel_size,'Color','k') 
            xlim([xmin*pixel_size xmax*pixel_size])
            ylim([ymin*pixel_size ymax*pixel_size])
            hax = get(gca);
            set(gca,'xcolor','none')
            set(gca,'ycolor','none')
            hax.YAxis.Label.Color = [0 0 0];
            hax.YAxis.Label.Visible = 'on';
            axis equal 
            set(gca,'Color','w')
            set(gcf,'Color','w')
            if d == 1
                ylabel(labels{1},'Color',colors{1},'FontSize',legend_font_size)
            end
        else % plot example LobVI track on day d
            track = tracks_all{2}{6,d}; % 6th mouse
            plot(track(1:round(fivemin_break),1)*pixel_size,track(1:round(fivemin_break),2)*pixel_size,'Color','k') 
            xlim([xmin*pixel_size xmax*pixel_size])
            ylim([ymin*pixel_size ymax*pixel_size])
            hax = get(gca);
            set(gca,'xcolor','none')
            set(gca,'ycolor','none')
            hax.YAxis.Label.Color = [0 0 0];
            hax.YAxis.Label.Visible = 'on';
            axis equal 
            set(gca,'Color','w')
            set(gcf,'Color','w')
            if d == 1
                ylabel(labels{2},'Color',colors{2},'FontSize',legend_font_size)
            end
        end
        count = count + 1;
    end
end
linkaxes([axes_all{1} axes_all{2}],'xy')
linkaxes([axes_all{3} axes_all{4}],'xy')

%% save the figure
fig_name = [fig_path 'Main_Figure/total_distance_travelled_example_trajectories'];
print(gcf,[fig_name '.pdf'],'-dpdf','-r0');
close(gcf)

end