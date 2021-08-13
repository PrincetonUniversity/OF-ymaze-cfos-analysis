function [] = compareBehaviorsStackedBoxPlot2(groups,labels,fig_path,out_path,MSortedLabels,M,fps)
% COMPAREBEHAVIORSSTACKEDBOXPLOT2: plot change in fractions between
% day 1 and day 2 for first 5 minutes and rest of recording in OF
%
% Input:
% - groups: experimental groups of interest
% - labels: labels for groups
% - fig_path: path to save figure
% - out_path: path to processed data
% - MSortedLabels: labels for M behaviors
% - M: number of behavioral classes
% - fps: frame rate

%% get the data

% get fractions of time spent in behaviors for first 5 min
probs_all_first5 = cell(1,length(groups));

for g = 1:length(groups)
    MStatesfile = matfile([out_path num2str(6) 'states/' groups{g} '.mat']);
    wrAll = MStatesfile.('wr_by_day_loco');
    
    n_days = size(wrAll,2);
    n_mice = size(wrAll{1},2);
    
    probs = cell(n_mice,n_days); % vector with fractions the mouse spents in slow / medium / fast locomotion
    
    for i = 1:n_mice
        for j= 1:n_days
            wr = wrAll{j}{i}(1:(5*60*fps));
            % one group for slow / fast explore / grooming
            wr(wr == 2) = 1;
            wr(wr == 3) = 1;
            wr(wr == 4) = 2;
            wr(wr == 5) = 3;
            wr(wr == 6) = 4;
            wr(wr == 7) = 5;
            wr(wr == 8) = 6;
            % get fractions in behaviors
            probs_tmp = histcounts(wr,'BinLimits',[1,M-2],'Normalization','probability','BinMethod','integer');
            probs{i,j} = probs_tmp;
        end
    end  
    probs_all_first5{g} = probs;
end

% get fractions of time spent in behaviors from 5 min on
probs_all_rest = cell(1,length(groups));

for g = 1:length(groups)
    MStatesfile = matfile([out_path num2str(6) 'states/' groups{g} '.mat']);
    wrAll = MStatesfile.('wr_by_day_loco');
    
    n_days = size(wrAll,2);
    n_mice = size(wrAll{1},2);
    
    probs = cell(n_mice,n_days); % vector with fractions the mouse spents in slow / medium / fast locomotion
    
    for i = 1:n_mice
        for j= 1:n_days
            wr = wrAll{j}{i}(5*60*fps+1:end);
            % one group for slow / fast explore / grooming
            wr(wr == 2) = 1;
            wr(wr == 3) = 1;
            wr(wr == 4) = 2;
            wr(wr == 5) = 3;
            wr(wr == 6) = 4;
            wr(wr == 7) = 5;
            wr(wr == 8) = 6;
            % get fractions in behaviors
            probs_tmp = histcounts(wr,'BinLimits',[1,M-2],'Normalization','probability','BinMethod','integer');
            probs{i,j} = probs_tmp;
        end
    end  
    probs_all_rest{g} = probs;
end

%% calculate compositional means
comp_means_first5 = cell(length(groups),2);
geo_means_first5 = cell(length(groups),2);
for g = 1:length(groups)
    for d = 1:2
        probs = probs_all_first5{g}(:,d);
        probs = vertcat(probs{:});
        geo_mean = geomean(probs);
        comp_mean = geo_mean./sum(geo_mean);
        geo_means_first5{g,d} = geo_mean;
        comp_means_first5{g,d} = comp_mean;
    end
end

comp_means_rest = cell(length(groups),2);
geo_means_rest = cell(length(groups),2);
for g = 1:length(groups)
    for d = 1:2
        probs = probs_all_rest{g}(:,d);
        probs = vertcat(probs{:});
        geo_mean = geomean(probs);
        comp_mean = geo_mean./sum(geo_mean);
        geo_means_rest{g,d} = geo_mean;
        comp_means_rest{g,d} = comp_mean;
    end
end

%% calculate change in behaviors from day 1 to 2
log_change_first5 = zeros(M-2,g);
change_all_first5 = zeros(M-2,g);
for g = 1:length(groups)
    change = geo_means_first5{g,2}./geo_means_first5{g,1};
    change_all_first5(:,g) = change';
    log_change_first5(:,g) = log(change)';
end

log_change_rest = zeros(M-2,g);
change_all_rest = zeros(M-2,g);
for g = 1:length(groups)
    change = geo_means_rest{g,2}./geo_means_rest{g,1};
    change_all_rest(:,g) = change';
    log_change_rest(:,g) = log(change)';
end

%% Plot change in behavior between day 1 and day 2
MSortedLabels = MSortedLabels([1 4:end]);
MSortedLabels{1} = 'explore / grooming';

global title_font_size

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
imagesc(flip(change_all_first5),[1/exp(1),exp(1)]); 
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
print(h,[fig_path 'Main_Figure/comparison_6_behaviors_between_days_first_5min.pdf'],'-dpdf','-r0');
close(h)

%% Plot change in behavior between day 1 and day 2 (rest)

h = figure;
set(h,'Units','centimeters');
h.Position = [10,10,7,6];
pos = get(h,'Position');
set(h,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)])

%imagesc(flip(log_change),[-1,1]); 
imagesc(flip(change_all_rest),[1/exp(1),exp(1)]); 
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
print(h,[fig_path 'Main_Figure/comparison_6_behaviors_between_days_rest.pdf'],'-dpdf','-r0');
close(h)

end