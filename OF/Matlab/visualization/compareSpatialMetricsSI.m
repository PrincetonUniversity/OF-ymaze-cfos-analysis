function [] = compareSpatialMetricsSI(groups,labels,colors,fig_path,out_path,pixel_size,fps,M)
% COMPARESPATIALMETRICSSI: plot fraction of time spent in inner region of
% open field arena as boxplot for different groups
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
for g = 1:length(groups)
    grouping = [grouping; repmat(g,size(inner_time_All{g},1),1)];
end

titles = {'Fraction in inner region'};

% get track data
wr_all = cell(1,length(groups));
for g = 1:length(groups)
    MStatesfile = matfile([out_path num2str(M) 'states/' groups{g} '.mat']);
    wr_all{g} = MStatesfile.('wr_by_day');
end

n_plots = length(titles);

%% plot fraction of time in inner region

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,7,4.5];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(n_plots,2);
t.Padding = 'compact';
t.TileSpacing = 'compact'; 

global point_size
global label_font_size
global title_font_size
global axis_font_size

for d = 1:2
    for i = 1:n_plots
        nexttile
        data_tmp = data{d}(:,i);
        
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
        
        % add data as scatter plot
        groupids = unique(grouping);
        for g = 1:length(groupids)
            scatter(repmat(g,length(data_tmp(grouping == g)),1)+(rand(length(data_tmp(grouping == g)),1)-0.5)/2,...
                data_tmp(grouping == g),point_size,colors{g},'filled','MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5)
        end
        hold on
        
        if i == 1
            ylims = [0 0.28];
        elseif i == 2
            ylims = [0 12];
        else 
            ylims = [30 150];
        end
        
        ylim(ylims)
        xticks(groupids)
        
        if d == 2
            xticklabels(labels)
            xtickangle(45)
            if i == 1
                title({'Day 2',''},'FontSize',label_font_size,'FontWeight','Normal')
            end
        else
            xticklabels(labels)
            xtickangle(45)
            if i == 1
                title({'Day 1',''},'FontSize',label_font_size,'FontWeight','Normal')
            end
            ylabel({titles{i},''},'FontSize',title_font_size,'FontWeight','Normal')
        end
        ax = gca;
        ax.FontSize = axis_font_size;
        prepfig()
        
        box off
        
        s = findobj(gca,'Type','scatter');
        uistack(s,'bottom')
    end
end

%% save the figure
if ~exist([fig_path 'Figure_SI_1/'],'dir')
    mkdir([fig_path 'Figure_SI_1/'])
end
fig_name = [fig_path 'Figure_SI_1/traditional_OF_metrics'];
print(gcf,[fig_name '.pdf'],'-dpdf','-r0');
close(gcf)

end