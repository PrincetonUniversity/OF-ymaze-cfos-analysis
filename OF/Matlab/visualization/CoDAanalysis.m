function [] = CoDAanalysis(groups,labels,fig_path,out_path,MSortedLabels,M)
% CODAANALYSIS: compositional data analysis of fractions of time spent in
% behaviors; log ratio difference between groups and control group
%
% Input:
% - groups: experimental groups of interest
% - labels: labels for groups
% - fig_path: path to save figure
% - out_path: path to processed data
% - MSortedLabels: labels for M behavioral classes
% - M: number of behavioral classes

% if fig_path does not exist, create new folder
if ~exist(fig_path,'dir')
    mkdir(fig_path)
end

%% load the data

probs = cell(length(groups),2);

for g = 1:length(groups)
    MStatesPath = [out_path num2str(6) 'states/' groups{g} '.mat'];
    load(MStatesPath,'wr_by_day_loco');
    wr_by_day = wr_by_day_loco;
    
    for d = 1:2
        % calculate probabilities for each mouse on specific day
        wr = wr_by_day{d};
        wrShn = cellfun(@(x) histcounts(x,'BinLimits',[1,M],'Normalization','probability','BinMethod','integer'), wr,'UniformOutput',false);
        n_mice = length(wr); % number of mice
        
        probs_tmp = mat2cell(cell2mat(wrShn(:)), n_mice, ones(1,M));
        
        % reshape probs to n_mice x M:
        probs{g,d} = horzcat(probs_tmp{:});
    end
end

%% reshape the data
group_lengths = cellfun(@(x) length(x),probs);
group_id = [];
for i = 1:length(group_lengths)
    group_id = [group_id; repmat(i,group_lengths(i,1),1)];
end
probs_day1 = vertcat(probs{:,1});
probs_day2 = vertcat(probs{:,2});

tab_day1 = [array2table(group_id),array2table(probs_day1)];
tab_day2 = [array2table(group_id),array2table(probs_day2)];

% log ratio of group data vs. CNO only data
idx = cellfun(@(x) strcmp(x,'AcuteCNOonly2D'),groups);
labels_CNOonly = labels(~idx);

%% bootstrapping to get estimate of variability
nBoot = 5000;

bootstat_day1 = cell(1,length(groups));
bootstat_day2 = cell(1,length(groups));
for g = 1:length(groups)
    mat_day1 = table2array(tab_day1(tab_day1.group_id == g,2:end));
    bootstat_day1{g} = bootstrp(nBoot,@geomean,mat_day1);
    
    mat_day2 = table2array(tab_day2(tab_day2.group_id == g,2:end));
    bootstat_day2{g} = bootstrp(nBoot,@geomean,mat_day2);
end

groups_of_interest = find(~idx); % all groups except CNO only (since we compare to CNO only)

CIs_lower_bootstrap_day1 = cell(1,length(groups_of_interest));
CIs_lower_bootstrap_day2 = cell(1,length(groups_of_interest));
CIs_upper_bootstrap_day1 = cell(1,length(groups_of_interest));
CIs_upper_bootstrap_day2 = cell(1,length(groups_of_interest));
means_bootstrap_day1 = cell(1,length(groups_of_interest));
means_bootstrap_day2 = cell(1,length(groups_of_interest));
for g = 1:length(groups_of_interest) % for all groups except CNO only
    data1 = bootstat_day1{groups_of_interest(g)};
    data2 = bootstat_day1{idx};
    logratio_tmp = bsxfun(@rdivide,data1,data2); % same as data1./data2
    logratio_tmp = log(logratio_tmp);
    % histfit(logratio_tmp(:,7)) % the distribution for medium locomotion
    % is a bit skewed
    means_bootstrap_day1{g} = mean(logratio_tmp);
    CIs_lower_bootstrap_day1{g} = prctile(logratio_tmp,2.5);
    CIs_upper_bootstrap_day1{g} = prctile(logratio_tmp,97.5);
    
    data1 = bootstat_day2{groups_of_interest(g)};
    data2 = bootstat_day2{idx};
    logratio_tmp = bsxfun(@rdivide,data1,data2);
    logratio_tmp = log(logratio_tmp);
    means_bootstrap_day2{g} = mean(logratio_tmp);
    CIs_lower_bootstrap_day2{g} = prctile(logratio_tmp,2.5);
    CIs_upper_bootstrap_day2{g} = prctile(logratio_tmp,97.5);
end
means_bootstrap_day1 = vertcat(means_bootstrap_day1{:});
means_bootstrap_day2 = vertcat(means_bootstrap_day2{:});
CIs_lower_bootstrap_day1 = vertcat(CIs_lower_bootstrap_day1{:});
CIs_upper_bootstrap_day1 = vertcat(CIs_upper_bootstrap_day1{:});
CIs_lower_bootstrap_day2 = vertcat(CIs_lower_bootstrap_day2{:});
CIs_upper_bootstrap_day2 = vertcat(CIs_upper_bootstrap_day2{:});

disp('day 1')
disp('------')
for i = 1:M
    for g = 1:(length(groups)-1)
        disp([labels_CNOonly{g} ', ' MSortedLabels{i} ': [' num2str(CIs_lower_bootstrap_day1(g,i)) ...
            ' ' num2str(CIs_upper_bootstrap_day1(g,i)) ']'])
    end
end

disp('day 2')
disp('------')
for i = 1:M
    for g = 1:(length(groups)-1)
        disp([labels_CNOonly{g} ', ' MSortedLabels{i} ': [' num2str(CIs_lower_bootstrap_day2(g,i)) ...
            ' ' num2str(CIs_upper_bootstrap_day2(g,i)) ']'])
    end
end

%% plot

global axis_font_size
global label_font_size

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,12,6];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3), pos(4)+1])

t = tiledlayout(2,1);
t.Padding = 'compact';
t.TileSpacing = 'compact'; 

ymin = min([min(min(CIs_lower_bootstrap_day2(:,1:end))) min(min(CIs_lower_bootstrap_day1(:,1:end)))]);
ymax = max([max(max(CIs_upper_bootstrap_day2(:,1:end))) max(max(CIs_upper_bootstrap_day1(:,1:end)))]);

nexttile
hb = bar(flip(means_bootstrap_day1(:,1:end)'),0.6,'EdgeColor','k','FaceColor','w');
hold on
xDataAll = cell(1,numel(hb));
labelAll = cell(1,numel(hb));
for i = 1:numel(hb)
    xData = hb(i).XData+hb(i).XOffset;
    line([xData;xData],[flip(CIs_lower_bootstrap_day1(i,:));flip(CIs_upper_bootstrap_day1(i,:))],'Color','k');
    xDataAll{i} = xData;
    labelAll{i} = arrayfun(@(x) labels_CNOonly{i},1:length(xData),'UniformOutput',false);
end
for i = 1:M
    text(i,ymax,MSortedLabels{M-i+1},'HorizontalAlignment','center','FontSize',6)
end
ylim([ymin ymax])
set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'XColor','none')
box off
ax = gca;
ax.FontSize = axis_font_size;
ylabel('Day 1','Fontsize',label_font_size)
prepfig()
set(gca,'XColor','none')

nexttile
hb = bar(flip(means_bootstrap_day2(:,:)'),0.6,'EdgeColor','k','FaceColor','w');
hold on
xDataAll = cell(1,numel(hb));
labelAll = cell(1,numel(hb));
for i = 1:numel(hb)
    xData = hb(i).XData+hb(i).XOffset;
    line([xData;xData],[flip(CIs_lower_bootstrap_day2(i,:));flip(CIs_upper_bootstrap_day2(i,:))],'Color','k');
    xDataAll{i} = xData;
    labelAll{i} = arrayfun(@(x) labels_CNOonly{i},1:length(xData),'UniformOutput',false);
end
ylim([ymin ymax])
box off
xtickpositions = horzcat(xDataAll{:});
xticklbls = horzcat(labelAll{:});
[SP,I] = sort(xtickpositions);
SL = xticklbls(I);
xticks(SP)
xticklabels(SL)
xtickangle(45)
ax = gca;
ax.FontSize = axis_font_size;
ylabel('Day 2','Fontsize',label_font_size)
prepfig()

ylabel(t,'ln(Region / Control)','Fontsize',label_font_size)

%% save the figure
print(gcf,[fig_path 'fraction_log_ratio_resp_CNOonly_all_behaviors.pdf'],'-dpdf','-r0');
close(gcf)

end
