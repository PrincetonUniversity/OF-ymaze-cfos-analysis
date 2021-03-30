function [] = plotTMs(groups,labels,fig_path,out_path,MSortedLabels,M)
% PLOTTMS: plot transition matrices (transition probabilities between
% behavioral states)
% 
% Input:
% - groups: experimental groups of interest
% - labels: labels for groups
% - fig_path: path to save figure
% - out_path: path to processed data
% - MSortedLabels: labels for M behavioral classes
% - M: number of behavioral classes

% create fig_path if not existent
if ~exist(fig_path,'dir')
    mkdir(fig_path)
end

%% load the data

% transition matrix for each day, averaged over all mice when weighting
% p_ij by the probability of mouse m to be in state i
TMs = cell(2,length(groups)); 

for g = 1:length(groups)
    MStatesPath = [out_path num2str(M) 'states/' groups{g} '.mat'];
    
    load(MStatesPath,'T_by_day');
    
    TMs{1,g} = T_by_day{1}; % transition matrices averaged over all mice
    TMs{2,g} = T_by_day{2};
end

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

global title_font_size

%% plot the differences of the TMs from day 2 and day 1

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,18,4];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(1,length(groups));
t.Padding = 'compact';
t.TileSpacing = 'compact'; 

p = cell(1,length(groups));
c = 1;
for g = 1:length(groups)
    p{c} = nexttile;
    c = c + 1;
    % plot the TM
    imagesc(flipud(TMs{2,g}-TMs{1,g}),[-0.1,0.1])
    if g == 1
        set(gca,'xtick',(1:M),'xticklabel',MSortedLabels)
        set(gca,'ytick',(1:M),'yticklabel',flip(MSortedLabels))
    else
        set(gca,'xtick',(1:M),'xticklabel',MSortedLabels)
        set(gca,'ytick',[],'yticklabel',[])
    end
    colormap(gca,customCMap)
    if g == 5
        colorbar
    end
    axis equal
    xtickangle(45)
    title(labels{g},'FontSize',title_font_size,'FontWeight','Normal')
    axis(gca, 'tight');
    prepfig()
    ax = gca;
    ax.FontSize = 7;
    xline(6.5,'k')
    yline(0.5,'k')
end
linkaxes([p{:}],'xy')

%% save the figure
fig_name = [fig_path '/Figure_SI_1/transition_matrices_diffs_between_days'];
print(f,[fig_name '.pdf'],'-dpdf','-r0');
close(f)

%% plot the differences of the TMs from day 2 and day 1 for CNO only and lobule VI

global label_font_size
f = figure;
f.Units = 'centimeters';
f.Position = [10,10,6,6.5];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(2,1);
t.Padding = 'compact';
t.TileSpacing = 'compact'; 

p = cell(1,2);
c = 1;
for g = 1:2
    p{c} = nexttile;
    c = c + 1;
    % plot the TM
    imagesc(flipud(TMs{2,g}-TMs{1,g}),[-0.1,0.1])
    if g == 1
        set(gca,'xtick',(1:M),'xticklabel',[])
        set(gca,'ytick',(1:M),'yticklabel',flip(MSortedLabels))
    else
        set(gca,'xtick',(1:M),'xticklabel',MSortedLabels)
        xtickangle(45)
        set(gca,'ytick',(1:M),'yticklabel',flip(MSortedLabels))
    end
    colormap(gca,customCMap)
    if g == 2
        colorbar
    end
    axis equal
    ylabel([labels{g} newline 'initial behavior'],'FontSize',label_font_size)
    axis(gca, 'tight');
    prepfig()
    ax = gca;
    ax.FontSize = 7;
    xline(6.5,'k')
    yline(0.5,'k')
end
linkaxes([p{:}],'xy')

%% save the figure
fig_name = [fig_path 'Main_Figure/transition_matrices_diffs_between_days_LobuleVI_vs_Control'];
print(f,[fig_name '.pdf'],'-dpdf','-r0');
close(f)

end

