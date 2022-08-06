function [] = compareSpatialMetricsBeeSwarm(groups,labels,colors,fig_path,out_path,pixel_size,fps,M)
% COMPARESPATIALMETRICSBEESWARM: plot total distance travelled as boxplots for
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

%% plot total distance travelled on day 1 and day 2 as scatter plot
f = figure;
f.Units = 'centimeters';
f.Position = [10,10,15,10];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

gs = gscatter(data{1}(:,3),data{2}(:,3),grouping);
line(linspace(40,150,100),linspace(40,150,100),'Color','k')
axis equal
xlabel('Total distance traveled on day 1 (m)')
ylabel('Total distance traveled on day 2 (m)')
ylim([40,110])
legend(gs,labels,'Location','eastoutside')

fig_name = [fig_path 'Main_Figure/total_distance_travelled_scatter_plot.pdf'];
print(gcf,fig_name,'-dpdf','-r0');
close(gcf)

%% boxplot with both days next to each other and lines for each animal

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,10,6];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

data_tmp_day1 = data{1}(:,3); % total distance travelled day 1
data_tmp_day2 = data{2}(:,3); % total distance travelled day 2
grouping_day1 = grouping*2-1;
grouping_day2 = grouping*2;
data_tmp = [data_tmp_day1;data_tmp_day2];
grouping = [grouping_day1;grouping_day2];

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

baseline = median(data_tmp(grouping == 1));
yline(baseline);

% add data
groupids = unique(grouping);
data_beeswarm = cell(1,length(groupids));
for g = 1:(length(groupids)/2)
    c1 = g*2-1;
    c2 = g*2;
    data_beeswarm{c1} = data_tmp(grouping == c1);
    data_beeswarm{c2} = data_tmp(grouping == c2);
end
hold on 
[~,PS] = plotSpread(data_beeswarm,'distributionColors','k','SpreadWidth',3);
for g = 1:(length(groupids)/2)
    c1 = g*2-1;
    c2 = g*2;
    data1 = PS(PS(:,1) > (c1-0.5) & PS(:,1) < (c1+0.5),:);
    data2 = PS(PS(:,1) > (c2-0.5) & PS(:,1) < (c2+0.5),:);
    for i = 1:size(data1,1)
        plot([data1(i,1),data2(i,1)],[data1(i,2),data2(i,2)],'Color',[0,0,0,0.2])
    end
    hold on
end

xlim([0.5,10.5])
ylims = [25 150];
ylim(ylims)

xticks(groupids)
labels_new = vertcat(strcat(labels,' - day 1'),strcat(labels,' - day 2'));
xticklabels(vertcat(labels_new(:,1),labels_new(:,2),labels_new(:,3),labels_new(:,4),labels_new(:,5)))
xtickangle(45)

ax = gca;
ax.FontSize = axis_font_size;
prepfig()

ylabel(titles{3},'FontSize',title_font_size)

%% save the figure
if ~exist([fig_path 'Main_Figure/'],'dir')
    mkdir([fig_path 'Main_Figure/'])
end
fig_name = [fig_path 'Main_Figure/total_distance_travelled_boxplots_with_lines.pdf'];
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