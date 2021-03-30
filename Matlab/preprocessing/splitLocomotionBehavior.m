function [] = splitLocomotionBehavior(out_path,fps,pixel_size) 
% SPLITLOCOMOTIONBEHAVIOR: split the locomotion behavior into slow / medium / fast
%
% Input:
% - out_path: path to processed data
% - fps: frames per second
% - pixel_size: pixel size (in mm)

% groups of interest
groups = {'C57Bl','AcuteVehicleonly2D','AcuteCNOonly2D','AcuteCNOnLobVI1D','AcuteCNOnCrusIRT2D','AcuteCNOnCrusILT2D',...
    'AcuteCNOnCrusI2D','AcuteCNOnmcherry2D','L7-Cre-Tsc1'};

wrAll = cell(1,length(groups));
tracksAll = cell(1,length(groups));
for g = 1:length(groups)
    load([out_path '6states/' groups{g}],'wr_by_day')
    load([out_path 'k100/' groups{g}],'dataTracks')
    wrAll{g} = wr_by_day;
    tracksAll{g} = dataTracks;
end
wrAll = cellfun(@(x) vertcat(x{:})', wrAll,'UniformOutput', false);

%% Plot of distribution
vels_locoAll = []; 
for g = 1:length(groups)
    [n_mice,n_days] = size(wrAll{g});
    for j = 1:n_days
        for i = 1:n_mice
            wr = wrAll{g}{i,j};
            track = tracksAll{g}{i,j};
            track = track(1:length(wr),:); % cut the track to the same length as wr
            vels = getVelocity(track,8,fps,pixel_size); % get velocities in m/s 
            vels_loco = vels(wr == 6);
            vels_locoAll = [vels_locoAll;vels_loco];
        end
    end
end

figure('Position',[500,500,200,200])
histogram(vels_locoAll,200)
xlim([0 0.5])
box off
xlabel('Velocity (m/s)')
thres = prctile(vels_locoAll,[1/3*100,2/3*100]);
xline(thres(1),'LineWidth',1.5);
xline(thres(2),'LineWidth',1.5);

%%

vels_locoAll = [];
for g = 1:length(groups)
    [n_mice,n_days] = size(wrAll{g});
    wr_by_day_loco = cell(1,n_days);
    for j = 1:n_days
        wr_mice_tmp = cell(1,n_mice);
        for i = 1:n_mice
            wr = wrAll{g}{i,j};
            track = tracksAll{g}{i,j};
            track = track(1:length(wr),:); % cut the track to the same length as wr
            vels = getVelocity(track,8,fps,pixel_size); % get velocities in m/s 
            vels_loco = vels(wr == 6);
            clusters_loco = zeros(size(vels_loco));
            clusters_loco(vels_loco < 0.1252) = 6;
            clusters_loco(vels_loco >= 0.1252 & vels_loco < 0.1937) = 7;
            clusters_loco(vels_loco >= 0.1937) = 8;
            wr(wr == 6) = clusters_loco;
            wr_mice_tmp{i} = wr;
            vels_locoAll = [vels_locoAll;vels_loco];
        end
        wr_by_day_loco{j} = wr_mice_tmp;
    end
    % save new version of wr_by_day to mat files
    save([out_path '6states/' groups{g}],'wr_by_day_loco','-append')
end

end