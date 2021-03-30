function [] = plotLimbCoordination(out_path,labels,vel_max,colors_paws,fig_path) 
% PLOTLIMBCOORDINATION: phase plots showing the entering of stance
% phase for different paws relative to one stride cycle of right front paw
%
% Input:
% - out_path: path to processed data
% - labels: labels for groups
% - vel_max: maximal centroid velocity considered
% - colors_paws: colors used for different paws
% - fig_path: path to save figure

load([out_path 'stride_measurements.mat'],'stride_data_RF')

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,13,9];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(2,3);
t.TileSpacing = 'compact';
t.Padding = 'compact';

nexttile

% get data for L7-Tsc1 (for comparison)
stride_data = stride_data_RF{6};
velsAll = {stride_data(:).vels};
velsAll = vertcat(velsAll{:});
phasesAll_RF = cell(size(stride_data,1),1);
phasesAll_LF = cell(size(stride_data,1),1);
phasesAll_RH = cell(size(stride_data,1),1);
phasesAll_LH = cell(size(stride_data,1),1);
for i = 1:size(stride_data,1)
    phasesAll_RF{i} = stride_data(i).phases(:,1);
    phasesAll_LF{i} = stride_data(i).phases(:,2);
    phasesAll_RH{i} = stride_data(i).phases(:,3);
    phasesAll_LH{i} = stride_data(i).phases(:,4);
end
phasesAll_RF = vertcat(phasesAll_RF{:});
phasesAll_LF = vertcat(phasesAll_LF{:});
phasesAll_RH = vertcat(phasesAll_RH{:});
phasesAll_LH = vertcat(phasesAll_LH{:});

% calculate mean phases for different velocity bins
[velsBinned_RF,phasesBinned_RF,nBinned_RF] = binDataPolarPlots(velsAll,phasesAll_RF,0:0.05:vel_max);
[velsBinned_LF,phasesBinned_LF,nBinned_LF] = binDataPolarPlots(velsAll,phasesAll_LF,0:0.05:vel_max);
[velsBinned_RH,phasesBinned_RH,nBinned_RH] = binDataPolarPlots(velsAll,phasesAll_RH,0:0.05:vel_max);
[velsBinned_LH,phasesBinned_LH,nBinned_LH] = binDataPolarPlots(velsAll,phasesAll_LH,0:0.05:vel_max);

phasesBinnedComp = {phasesBinned_RF,phasesBinned_LF,phasesBinned_RH,phasesBinned_LH};
nBinnedComp = {nBinned_RF,nBinned_LF,nBinned_RH,nBinned_LH};
velsBinnedComp = {velsBinned_RF,velsBinned_LF,velsBinned_RH,velsBinned_LH};

for g = 1:(length(stride_data_RF)-1)
    stride_data = stride_data_RF{g};
    velsAll = {stride_data(:).vels};
    velsAll = vertcat(velsAll{:});
    phasesAll_RF = cell(size(stride_data,1),1);
    phasesAll_LF = cell(size(stride_data,1),1);
    phasesAll_RH = cell(size(stride_data,1),1);
    phasesAll_LH = cell(size(stride_data,1),1);
    for i = 1:size(stride_data,1)
        phasesAll_RF{i} = stride_data(i).phases(:,1);
        phasesAll_LF{i} = stride_data(i).phases(:,2);
        phasesAll_RH{i} = stride_data(i).phases(:,3);
        phasesAll_LH{i} = stride_data(i).phases(:,4);
    end
    phasesAll_RF = vertcat(phasesAll_RF{:});
    phasesAll_LF = vertcat(phasesAll_LF{:});
    phasesAll_RH = vertcat(phasesAll_RH{:});
    phasesAll_LH = vertcat(phasesAll_LH{:});
    
    % calculate mean phases for different velocity bins
    [velsBinned_RF,phasesBinned_RF,nBinned_RF] = binDataPolarPlots(velsAll,phasesAll_RF,0:0.05:vel_max);
    [velsBinned_LF,phasesBinned_LF,nBinned_LF] = binDataPolarPlots(velsAll,phasesAll_LF,0:0.05:vel_max);
    [velsBinned_RH,phasesBinned_RH,nBinned_RH] = binDataPolarPlots(velsAll,phasesAll_RH,0:0.05:vel_max);
    [velsBinned_LH,phasesBinned_LH,nBinned_LH] = binDataPolarPlots(velsAll,phasesAll_LH,0:0.05:vel_max);
    
    phasesBinned = {phasesBinned_RF,phasesBinned_LF,phasesBinned_RH,phasesBinned_LH};
    nBinned = {nBinned_RF,nBinned_LF,nBinned_RH,nBinned_LH};
    velsBinned = {velsBinned_RF,velsBinned_LF,velsBinned_RH,velsBinned_LH};
    
    NMax = max(cellfun(@(x) sum(x,'omitnan'), nBinned));
    %disp(['Total number of strides N = ' num2str(sum(nBinned,'omitnan'))])
    
    % phase plot (binned means)
    nexttile
    for i = 1:4
        polarscatter(phasesBinned{i},velsBinned{i},nBinned{i}/NMax*50,colors_paws(i,:),'filled','MarkerFaceAlpha',0.8)
        hold on
    end
    if g == 1
        for i = 1:4
            polarscatter(phasesBinnedComp{i},velsBinnedComp{i},nBinnedComp{i}/NMax*50,[0.65 0.65 0.65],'filled','MarkerFaceAlpha',0.8)
            hold on
        end
    end
    thetaticks(0:90:270)
    thetaticklabels({'0','{\pi}/{2}','\pi','{3\pi}/{2}'})
    rticks([0 0.2 0.4])
    rticklabels({'0','0.2 m/s','0.4 m/s'})
    rlim([0 vel_max])
    title(labels{g},'FontWeight','normal')
end

print(f,[fig_path 'Figure_SI_1/polarplot'],'-dpdf','-r0')
close(f)

%%
f = figure;
f.Units = 'centimeters';
f.Position = [10,10,12,8.5];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

tiledlayout(2,3)

for g = 1:length(stride_data_RF)
    stride_data = stride_data_RF{g};
    velsAll = {stride_data(:).vels};
    velsAll = vertcat(velsAll{:});
    phasesAll_RF = cell(size(stride_data,1),1);
    phasesAll_LF = cell(size(stride_data,1),1);
    phasesAll_RH = cell(size(stride_data,1),1);
    phasesAll_LH = cell(size(stride_data,1),1);
    for i = 1:size(stride_data,1)
        phasesAll_RF{i} = stride_data(i).phases(:,1);
        phasesAll_LF{i} = stride_data(i).phases(:,2);
        phasesAll_RH{i} = stride_data(i).phases(:,3);
        phasesAll_LH{i} = stride_data(i).phases(:,4);
    end
    phasesAll_RF = vertcat(phasesAll_RF{:});
    phasesAll_LF = vertcat(phasesAll_LF{:});
    phasesAll_RH = vertcat(phasesAll_RH{:});
    phasesAll_LH = vertcat(phasesAll_LH{:});
    
    phasesAll = {phasesAll_RF,phasesAll_LF,phasesAll_RH,phasesAll_LH};
    
    % phase plot
    nexttile
    for i = 1:4
        polarscatter(phasesAll{i},velsAll,[],colors_paws(i,:),'filled','MarkerFaceAlpha',0.2)
        hold on
    end
    thetaticks(0:90:270)
    thetaticklabels({'0%','25%','50%','75%'})
    rticks(0:0.1:vel_max)
    rlim([0 vel_max])
    title(labels{g})
end

set(gcf,'Units','Inches');
pos = get(gcf,'Position');
set(gcf,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
print(gcf,[fig_path 'Figure_SI_1/polarplot_all'],'-dpdf','-r0')
close(gcf)

end