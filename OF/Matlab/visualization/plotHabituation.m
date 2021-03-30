function [] = plotHabituation(groups,labels,colors,fig_path,out_path,MSortedLabels,fps,M)
% PLOTHABITUATION: plot fraction to be in a behavior over time 
%
% Input:
% - groups: experimental groups of interest
% - labels: labels for groups
% - colors: colors used for different groups
% - fig_path: path to save figure
% - out_path: path to processed data
% - MSortedLabels: labels for M behavioral classes
% - fps: frames per second
% - M: number of behavioral classes

if ~exist(fig_path,'dir')
    mkdir(fig_path)
end

%% load data for the groups

wrAll = cell(1,length(groups));
for g = 1:length(groups)
    % load data from M-states-info-file
    MStatesPath = [out_path num2str(6) 'states/' groups{g} '.mat'];
    load(MStatesPath,'wr_by_day_loco');
    wr_by_day = wr_by_day_loco;
    
    % reshape data set
    wrAll{g} = cellfun(@(x) vertcat(x{:}), wr_by_day,'UniformOutput', false);
    clear wr_by_day
end

% number of days of the experiment
ndays = 2; 

%% calculate fractions of time spent in behavior for an interval for each animal

prob_per_ints_mean_All = cell(1,length(groups));
%prob_per_ints_CI_lower_All = cell(1,4);
%prob_per_ints_CI_upper_All = cell(1,4);
prob_per_ints_SE_All = cell(1,length(groups));
prob_per_ints_STD_All = cell(1,length(groups));

for g = 1:length(groups)
    wr = wrAll{g};
    
    % calculate average fractions of being in a behavior for each mouse at
    % equally spaced time points (using a sliding window)
    prob_per_ints_mean = cell(1,ndays);
    prob_per_ints_SE = cell(1,ndays);
    prob_per_ints_STD = cell(1,ndays);
    n_mice_all = cell(1,ndays);
    for i = 1:ndays
        n_mice = size(wr{i},1);
        prob_per_ints_mean_tmp = zeros(M,length(1:1000:size(wr{i},2)));
        prob_per_ints_SE_tmp = zeros(M,length(1:1000:size(wr{i},2)));
        prob_per_ints_STD_tmp = zeros(M,length(1:1000:size(wr{i},2)));
        c = 1;
        for j = 1:1000:size(wr{i},2) % for some time points
            wr_tmp = wr{i}(:,max([j-10000,1]):min([j+10000,size(wr{i},2)]));
            N_array = zeros(n_mice,M);
            for m = 1:n_mice % for all mice
                N_array(m,:) = histcounts(wr_tmp(m,:),'BinMethod','integers','Normalization','probability','BinLimits',[1,M]);
            end
            prob_per_ints_mean_tmp(:,c) = mean(N_array,1)';
            prob_per_ints_SE_tmp(:,c) = std(N_array,0,1)'/sqrt(n_mice);
            prob_per_ints_STD_tmp(:,c) = std(N_array,0,1)';
            c = c+1;
        end
        n_mice_all{i} = n_mice;
        prob_per_ints_mean{i} = prob_per_ints_mean_tmp;
        prob_per_ints_SE{i} = prob_per_ints_SE_tmp;
        prob_per_ints_STD{i} = prob_per_ints_STD_tmp;
    end
    prob_per_ints_mean_All{g} = prob_per_ints_mean;
    prob_per_ints_SE_All{g} = prob_per_ints_SE;
    prob_per_ints_STD_All{g} = prob_per_ints_STD;
end

%% plot all behaviors

clusters = 1:8;

global title_font_size
global axis_font_size
global label_font_size

groups_sets = {[1 2],[1 3],[1 4],[1 5]}; % all groups compared to CNO only

for gs = 1:length(groups_sets)
    h = figure;
    set(h,'Units','centimeters');
    h.Position = [10,10,18,7];
    pos = get(h,'Position');
    set(h,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3), pos(4)])
    
    t = tiledlayout(2,4);
    t.Padding = 'compact';
    t.TileSpacing = 'compact';
    
    for i = 1:length(clusters)
        nexttile
        cluster = clusters(i);
        for g = groups_sets{gs}
            for d = 1:ndays
                mean_val = prob_per_ints_mean_All{g}{d}(cluster,:)';
                SE_val = prob_per_ints_SE_All{g}{d}(cluster,:)';
                
                xplot = ((1:1000:size(wr{d},2))/fps/60)'; % time points for plotting (in minutes)
                if d == 1
                    plot(xplot,mean_val,':','color',colors{g},'MarkerSize',10,'LineWidth',0.5);
                else
                    plot(xplot,mean_val,'color',colors{g},'MarkerSize',10,'LineWidth',1);
                end
                hold on
                shade = fill([xplot;flipud(xplot)],[(mean_val - SE_val); flipud((mean_val + SE_val))],colors{g},'linestyle','none');
                if d == 1
                    set(shade,'facealpha',0.2)
                else
                    set(shade,'facealpha',0.4)
                end
                hold on
            end
        end
        xlim([min(xplot) max(xplot)])
        ylim([0.02 0.31])
        set(gca,'FontSize',axis_font_size)
        title(MSortedLabels{cluster},'FontSize',title_font_size,'FontWeight','Normal')
        xlabel('Time (min)','Fontsize',label_font_size)
        prepfig()
    end
    ylabel(t,'fraction of time in behavior','Fontsize',label_font_size)
    fig_name = [fig_path 'Habituation_' labels{groups_sets{gs}(1)} '_vs_' labels{groups_sets{gs}(2)} '.pdf'];
    print(h,fig_name,'-dpdf','-r0');
    close(h)
end

%% Plot selected behaviors

h = figure;
set(h,'Units','centimeters');
h.Position = [10,10,5,6];
pos = get(h,'Position');
set(h,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3), pos(4)])

t = tiledlayout(2,1);
t.Padding = 'compact';
t.TileSpacing = 'compact';

cluster = 8; 
for g = [1 2] % CNO only and Lobule VI
    nexttile
    for d = 1:ndays
        mean_val = prob_per_ints_mean_All{g}{d}(cluster,:)';
        error_val = prob_per_ints_STD_All{g}{d}(cluster,:)';
        
        xplot = ((1:1000:size(wr{d},2))/fps/60)'; % time points for plotting (in minutes)
        if d == 1
            plot(xplot,mean_val,':','color',colors{1},'MarkerSize',10,'LineWidth',0.5);
        else
            plot(xplot,mean_val,'color',colors{1},'MarkerSize',10,'LineWidth',1);
        end
        hold on
        shade = fill([xplot;flipud(xplot)],[(mean_val - error_val); flipud((mean_val + error_val))],colors{1},'linestyle','none');
        if d == 1
            set(shade,'facealpha',0.2)
        else
            set(shade,'facealpha',0.4)
        end
        hold on
    end
    xlim([min(xplot) max(xplot)])
    ylim([0.02 0.45])
    set(gca,'FontSize',axis_font_size)
    prepfig()
    if g == 2
        xlabel('Time (min)','Fontsize',label_font_size)
    end
end
ylabel(t,'Probability to be in fast locomotion','Fontsize',label_font_size)

%%
fig_name = [fig_path 'Figure_change_of_fast_locomotion_over_time.pdf'];
exportgraphics(h,fig_name)
close(h)

end
