function [] = compareChangeInFractionsSI(groups,labels,fig_path,out_path,MSortedLabels,M,colors)
% COMPARECHANGEINFRACTIONSSI: compare change in the fractions of time spent in behaviors on day 2 vs
% day 1
%
% Input:
% - groups: experimental groups of interest
% - labels: labels for groups
% - fig_path: path to save figure
% - out_path: path to processed data
% - MSortedLabels: labels for M behaviors
% - M: number of behavioral classes
% - colors: colors used for different groups

if ~exist(fig_path,'dir')
    mkdir(fig_path)
end

%% load data for the groups

wr = cell(1,length(groups));

for g = 1:length(groups)
    % load data from M-states-info-file
    MStatesPath = [out_path num2str(6) 'states/' groups{g} '.mat'];
    load(MStatesPath,'wr_by_day_loco');
    wr_by_day = wr_by_day_loco;
    
    % reshape data set
    wr{g} = cellfun(@(x) vertcat(x{:}), wr_by_day,'UniformOutput', false);
    clear wr_by_day 
end

wr = vertcat(wr{:});

ndays = 2;
nframes = size(wr{1,1},2);

% calculate average ratio of fractions of being in a behavior for each mouse
prob_ratio_between_days = cell(length(groups),ndays-1);
prob_ratio_within_days = cell(length(groups),ndays);

for g = 1:length(groups)
    for i = 1:ndays
        n_mice = size(wr{g,i},1);
        
        N_array = zeros(n_mice,M);
        N_array_beginning = zeros(n_mice,M);
        N_array_end = zeros(n_mice,M);
        for m = 1:n_mice % for all mice
            N_array(m,:) = histcounts(wr{g,i}(m,:),'BinMethod','integers','Normalization','probability','BinLimits',[1,M]);
            N_array_beginning(m,:) = histcounts(wr{g,i}(m,1:round(nframes/2)),'BinMethod','integers','Normalization','probability','BinLimits',[1,M]);
            N_array_end(m,:) = histcounts(wr{g,i}(m,round(nframes/2)+1:end),'BinMethod','integers','Normalization','probability','BinLimits',[1,M]);
        end
        if i == 1 % save the data for later use
            N_array_day1 = N_array;
        else
            prob_ratio_between_days{g,i-1} = log(N_array./N_array_day1); % log fold change day 2 vs day 1
        end
        prob_ratio_within_days{g,i} = log(N_array_end./N_array_beginning);
    end
end

%% between day comparison
data = vertcat(prob_ratio_between_days{:,1}); 
grouping = [];
for g = 1:length(groups)
    grouping = [grouping; repmat(g,size(prob_ratio_between_days{g,1},1),1)];
end

%% export data for statistical analysis in R
data_exp = zeros(length(grouping)*M,4);
count = 1;
for g = 1:length(groups)
    for m = 1:size(prob_ratio_between_days{g},1)
        for i = 1:size(prob_ratio_between_days{g},2)
            data_exp(count,:) = [g,m,i,prob_ratio_between_days{g}(m,i)];
            count = count + 1;
        end
    end
end
data_exp = array2table(data_exp,'VariableNames',{'group','mouse','behavior','logratio'});
writetable(data_exp,[out_path 'Logratio_fraction_in_behavior_controls.txt'])

%% SI plot (all behaviors)

global title_font_size
global axis_font_size
global point_size
global label_font_size

h = figure;
set(h,'Units','centimeters');
h.Position = [10,10,16,4.5]; 
pos = get(h,'Position');
set(h,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+0.1, pos(4)+0.1])

t = tiledlayout(1,M);
t.Padding = 'compact';
t.TileSpacing = 'compact';

for i = M:-1:1
    nexttile
    
    data_tmp = data(:,i);
    
    b1 = boxplot(data_tmp,grouping);
    b2 = findobj(b1,'tag','Outliers');
    delete(b2)
    set(findobj(gcf,'LineStyle','--'),'LineStyle','-')
    
    % Change the boxplot color to black
    a = get(get(gca,'children'),'children');
    set(a, 'Color', 'k');
    hold on
    
    % delete horizontal line at end of whiskers
    wend = findobj(gcf,'tag','Lower Adjacent Value');
    delete(wend)
    wend = findobj(gcf,'tag','Upper Adjacent Value');
    delete(wend)
    
    % add data as scatter plot
    groupids = unique(grouping);
    for g = 1:length(groupids)
        scatter(repmat(g,length(data_tmp(grouping == g)),1)+(rand(length(data_tmp(grouping == g)),1)-0.5)/2,...
            data_tmp(grouping == g),point_size/2,colors{g},'filled','MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5)
    end
    hold on
    
    % add horizontal line at 0
    yline(0);
    
    ylims = [-2,2.5];

    ylim(ylims)
    xticks(groupids)
    xticklabels(labels)
    xtickangle(45)
    ax = gca;
    ax.FontSize = axis_font_size;
    prepfig()
    
    if i == M
        ylabel('ln(Day 2/ Day 1)','FontSize', label_font_size)
    end
    
    title(MSortedLabels{i},'FontSize',title_font_size,'FontWeight','Normal')
    box off
end

%% save the figure
fig_name = [fig_path 'Between_days_comparison_all_behaviors'];
print(h,[fig_name '.pdf'],'-dpdf','-r0');
close(h)
end
