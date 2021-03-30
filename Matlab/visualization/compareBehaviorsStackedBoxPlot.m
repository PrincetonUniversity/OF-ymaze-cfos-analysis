function [] = compareBehaviorsStackedBoxPlot(groups,labels,fig_path,out_path,MSortedLabels,M,colors_behaviors)
% COMPAREBEHAVIORSSTACKEDBOXPLOT: plot compositional mean fractions to be
% in each behavior for day 1 and day 2; plot change in fractions between
% day 1 and day 2
%
% Input:
% - groups: experimental groups of interest
% - labels: labels for groups
% - fig_path: path to save figure
% - out_path: path to processed data
% - MSortedLabels: labels for M behaviors
% - M: number of behavioral classes
% - colors_behaviors: colors used for different behaviors

%% get the data

% get fractions of time spent in behaviors
probs_all = cell(1,length(groups));

for g = 1:length(groups)
    MStatesfile = matfile([out_path num2str(6) 'states/' groups{g} '.mat']);
    wrAll = MStatesfile.('wr_by_day_loco');
    
    n_days = size(wrAll,2);
    n_mice = size(wrAll{1},2);
    
    probs = cell(n_mice,n_days); % vector with fractions the mouse spents in slow / medium / fast locomotion
    
    for i = 1:n_mice
        for j= 1:n_days
            wr = wrAll{j}{i};
            % get fractions in behaviors
            probs_tmp = histcounts(wr,'BinLimits',[1,M],'Normalization','probability','BinMethod','integer');
            probs{i,j} = probs_tmp;
        end
    end  
    probs_all{g} = probs;
end

%% calculate compositional means
comp_means = cell(length(groups),2);
geo_means = cell(length(groups),2);
for g = 1:length(groups)
    for d = 1:2
        probs = probs_all{g}(:,d);
        probs = vertcat(probs{:});
        geo_mean = geomean(probs);
        comp_mean = geo_mean./sum(geo_mean);
        geo_means{g,d} = geo_mean;
        comp_means{g,d} = comp_mean;
    end
end

%% calculate change in behaviors from day 1 to 2
log_change = zeros(M,g);
change_all = zeros(M,g);
for g = 1:length(groups)
    change = geo_means{g,2}./geo_means{g,1};
    change_all(:,g) = change';
    log_change(:,g) = log(change)';
end

%% Plot compositional means for day 1 and day 2
h = figure;
set(h,'Units','centimeters');
h.Position = [10,10,5,6];
pos = get(h,'Position');
set(h,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3), pos(4)])

t = tiledlayout(1,2);
t.Padding = 'compact';
t.TileSpacing = 'compact'; 

global label_font_size
global title_font_size

data_day1 = comp_means(:,1); 
data_day1 = vertcat(data_day1{:});
data_day2 = comp_means(:,2); 
data_day2 = vertcat(data_day2{:});

nexttile
b = bar(data_day1,'stacked');
for i = 1:M
    b(i).FaceColor = colors_behaviors(i,:);
end
xticklabels(labels)
xtickangle(45)
ylabel('Fraction of time in behavior','FontSize',label_font_size)
ylim([0 1])
xlim([0.5,length(groups) + 0.5])
title('Day 1','FontSize',title_font_size,'FontWeight','Normal','FontName','Arial')
prepfig()

nexttile
b = bar(data_day2,'stacked');
for i = 1:M
    b(i).FaceColor = colors_behaviors(i,:);
end
xticklabels(labels)
xtickangle(45)
ylim([0 1])
xlim([0.5,length(groups) + 0.5])
title('Day 2','FontSize',title_font_size,'FontWeight','Normal')
prepfig()

%%
print(h,[fig_path 'Figure_SI_1/comparison_8_behaviors.pdf'],'-dpdf','-r0');
close(h)

%% Plot change in behavior between day 1 and day 2
h = figure;
set(h,'Units','centimeters');
h.Position = [10,10,7,6];
pos = get(h,'Position');
set(h,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)])

% own colormap
topColor = [0,136,55]/255;
indexColor = [1 1 1];
bottomcolor = [123,50,148]/255;
customCMap1 = [linspace(bottomcolor(1),indexColor(1),100)',...
            linspace(bottomcolor(2),indexColor(2),100)',...
            linspace(bottomcolor(3),indexColor(3),100)'];
customCMap2 = [linspace(indexColor(1),topColor(1),100)',...
            linspace(indexColor(2),topColor(2),100)',...
            linspace(indexColor(3),topColor(3),100)'];
customCMap = [customCMap1;customCMap2]; 

%imagesc(flip(log_change),[-1,1]); 
imagesc(flip(change_all),[1/exp(1),exp(1)]); 
set(gca,'ColorScale','log')
colormap(gca,customCMap)
xticklabels(labels)
xtickangle(45)
yticks(1:M)
yticklabels(flip(MSortedLabels))
title('Day 2 / Day 1','FontSize',title_font_size,'FontWeight','Normal')
%title('ln(Day 2 / Day 1)','FontSize',title_font_size,'FontWeight','Normal')
cb = colorbar('location','eastoutside','Ticks',[0.5 1 2]);
set(cb,'Ticklabels',num2str(get(cb,'Ticks')','%.1f'))

prepfig()
% add lines at upper and right side of box
xline(5.5,'k-','Alpha',1)
yline(0.5,'k-','Alpha',1)

%%
print(h,[fig_path 'Main_Figure/comparison_8_behaviors_between_days.pdf'],'-dpdf','-r0');
close(h)

end