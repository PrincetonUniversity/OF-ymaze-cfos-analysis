function [] = compareVelocitiesBodyParts(groups,labels,fig_path,out_path,M,MSortedLabels,fps,pixel_size)
% COMPAREVELOCITIESBODYPARTS: plot velocity distributions of body parts for
% each behavior separately and all groups to compare
%
% Input:
% - groups: experimental groups of interest
% - labels: labels for groups
% - fig_path: path to save figure
% - out_path: path to processed data
% - M: number of behavioral classes
% - MSortedLabels: labels of behavioral classes
% - pixel_size: pixel size

%% get body part and behavior data

joints_all = cell(1,length(groups));
wr_all = cell(1,length(groups));
for g = 1:length(groups)
    MStatesfile = matfile([out_path num2str(M) 'states/' groups{g} '.mat']);
    wr_tmp = MStatesfile.('wr_by_day');
    wr_tmp = vertcat(wr_tmp{:})';
    wr_all{g} = wr_tmp;
    
    mfile = matfile([out_path 'k100/' groups{g} '.mat']);
    joints = mfile.('dataLEAPout');
    for i = 1:size(joints,1)
        for j = 1:size(joints,2)
            joints_tmp = [joints{i,j}([1 3:4],:,1:numel(wr_tmp{i,j}),:); ...
                mean(joints{i,j}([5,7],:,1:numel(wr_tmp{i,j}),:),1); mean(joints{i,j}([6,8],:,1:numel(wr_tmp{i,j}),:),1);...
                mean(joints{i,j}([12,14],:,1:numel(wr_tmp{i,j}),:),1); mean(joints{i,j}([13,15],:,1:numel(wr_tmp{i,j}),:),1);...
                joints{i,j}(16:18,:,1:numel(wr_tmp{i,j}),:)];
            joints{i,j} = joints_tmp;
        end
    end
    joints_all{g} = joints;
end

%% get velocities of body parts

velocities_all = cell(size(joints_all));
for g = 1:numel(groups)
    velocities_tmp = cell(size(joints_all{g}));
    for m = 1:size(joints_all{g},1)
        for d = 1:size(joints_all{g},2)
            velocities_tmp_mat = zeros([size(joints_all{g}{m,d},1) size(joints_all{g}{m,d},3)]);
            for bp = 1:size(joints_all{g}{m,d},1)
                velocities_tmp_mat(bp,:) = getVelocity(double(squeeze(joints_all{g}{m,d}(bp,:,:))'),5,fps,pixel_size);
            end
            velocities_tmp{m,d} = velocities_tmp_mat;
        end
    end
    velocities_all{g} = velocities_tmp;
end

%% plot velocity distributions
bparts = {'nose','left ear','right ear','LF paw','RF paw','LH paw','RH paw',...
    'tailbase','mid tail','tail tip'};

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,30,15];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

t = tiledlayout(M,numel(bparts));
t.Padding = 'compact';
t.TileSpacing = 'compact';

for c = 1:M
    for bp = 1:numel(bparts)
        nexttile
        data_sel_behavior = cell(numel(groups),1);
        for g = 1:numel(groups)
            data_sel_behavior_tmp = cell(size(velocities_all{g}));
            for m = 1:size(velocities_all{g},1)
                for d = 1:size(velocities_all{g},2)
                     data_sel_behavior_tmp{m,d} = velocities_all{g}{m,d}(bp,wr_all{g}{m,d} == c);
                end
            end
            data_sel_behavior{g} = horzcat(data_sel_behavior_tmp{:});
        end
        group_ids = arrayfun(@(x) repmat(x,1,numel(data_sel_behavior{x})),1:numel(data_sel_behavior),'UniformOutput',false);
        group_ids = horzcat(group_ids{:});
        data_sel_behavior = horzcat(data_sel_behavior{:});
        b = boxplot(data_sel_behavior,group_ids);
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
    
        ylim([0 1])
        if c == M
            xticks(1:numel(groups))
            xticklabels(labels)
        else
            set(gca,'xtick',[])
        end
        if bp == 1
            ylabel(MSortedLabels{c})
        end
        if c == 1
            title(bparts{bp})
        end
        prepfig()
    end
end


%% save the figure
fig_name = [fig_path 'Additional_Figures/bp_velocities_by_behavior_and_group'];
print(gcf,[fig_name '.pdf'],'-dpdf','-r0');
close(gcf)

end