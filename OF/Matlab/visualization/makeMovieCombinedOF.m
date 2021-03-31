function [] = makeMovieCombinedOF(group,day,mouse,fig_path,out_path,video_filename,...
    video_box_filename,MSortedLabels,M,fps,colors_behaviors)
% MAKEMOVIECOMBINEDOF: make movie with mouse in OF, zoomed in version with
% body parts (from LEAP) and ethogram
%
% Input:
% - group: experimental group of interest
% - day: day of interest
% - mouse: id of mouse of interest
% - fig_path: path to save figure
% - out_path: path to processed data
% - video_filename: path to h5 file with images of mouse in open field
% - video_box_filename: path to h5 file with images of mouse in open field
% (only a boxed region around the mouse is considered)
% - MSortedLabels: labels for M behavioral classes
% - M: number of behavioral classes
% - fps: frames per second
% - colors_behaviors: colors used for different behaviors

if ~exist(fig_path,'dir')
    mkdir(fig_path)
end

%% get the data for the mouse and day of interest

mfile = matfile([out_path 'k100/' group '.mat']);
load([out_path '6states/' group '.mat'],'wr_by_day_loco');

joints = mfile.('dataLEAPout')(mouse,day);
joints = joints{1};

wr = wr_by_day_loco{day}{mouse};

%% get the data from the raw mouse videos (both in OF and in a box)
mouse_video_data = ...
    h5read(video_filename,'/pg0');

mouse_video_data_box = ...
    h5read(video_box_filename,'/box');

fstart = 60085;
fend = 60385; 

%% plot the movie of the skeleton in the OF

% colors for body part labels
color = [221,28,119]./255; 

joints_new = reshape(joints,36,size(joints,3)); 

x_max = max(max(joints_new(1:18,fstart:fend)));
x_min = min(min(joints_new(1:18,fstart:fend)));
y_max = max(max(joints_new(19:end,fstart:fend)));
y_min = min(min(joints_new(19:end,fstart:fend)));

%%
cmap = flipud(gray(256));
idx_BPs = [1 2 5 6 7 8 12 13 14 15 16]; % body parts used for behavioral classification
global label_font_size
global title_font_size
range_val = 100;
box_xmin = 80;
box_xmax = 80 + 886;
box_ymin = 180;
box_ymax = 180 + 886;

if ~exist([fig_path group '_day' num2str(day) '_mouse' num2str(mouse)],'dir')
    mkdir([fig_path group '_day' num2str(day) '_mouse' num2str(mouse)])
end

c = 1;
for j = fstart:fend
    disp(j)
    
    h = figure;
    set(h,'Units','centimeters');
    h.Position = [10,10,16,4.5];
    pos = get(h,'Position');
    set(h,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+0.1, pos(4)+0.1])
    
    tiledlayout(1,3);
    
    % raw mouse video in OF
    nexttile
    
    mouse_image_OF = mouse_video_data(box_ymin:box_ymax,box_xmin:box_xmax,j-fstart+1);
    med_val = median(mouse_image_OF,'all');
    % mask the mouse and set all pixels away from the mouse to zero
    gfilt_image = imgaussfilt(mouse_image_OF);
    BW = false(size(mouse_image_OF));
    BW(gfilt_image > med_val+3) = true;
    mouse_image_OF = mouse_image_OF - med_val;
    % Fill holes
    BW = imfill(BW,'hole');
    % Extract area with largest intensities
    CC = bwconncomp(BW);
    [~,I] = max(gfilt_image,[],'all','linear');
    % find connected component with this pixel
    ind = -1;
    for k = 1:CC.NumObjects
        if ismember(I,CC.PixelIdxList{k})
            ind = k;
            break
        end
    end
    mask = false(size(BW));
    mask(CC.PixelIdxList{ind}) = true;    
    mouse_image_OF(~mask) = 0;
   
    imagesc(mouse_image_OF)
    hold on
    
    plot([0.5 box_xmax-box_xmin+0.5 box_xmax-box_xmin+0.5 0.5 0.5],...
    [0.5 0.5 box_ymax-box_ymin+0.5 box_ymax-box_ymin+0.5 0.5],'k','LineWidth',1)
    colormap(gca,cmap);
    axis equal off
    
    % pose tracking result
    nexttile
    imagesc(mouse_video_data_box(:,:,j-fstart+1))
    hold on
    colormap(gca,cmap);
    hold on
    scatter(joints_new(idx_BPs,j),joints_new(idx_BPs+18,j),1,'filled','MarkerEdgeColor',color,'MarkerFaceColor',color)
    ax = gca;
    ax.NextPlot = 'replaceChildren';
    axis equal off
    xlim([x_min-10 x_max+10])
    ylim([y_min y_max])
    title(MSortedLabels(wr(j)),'Color',colors_behaviors(wr(j),:),'FontSize',title_font_size)
    
    % ethogram
    nexttile
    mat = zeros(M,fend-fstart+1);
    wr_sel = wr(fstart:fend);
    for i = 1:M
        mat(i,wr_sel == i) = i;
    end
    % select range of interest
    curr_frame = j;
    frame_min = max(1,curr_frame-fstart+1-range_val);
    frame_max = min(fend-fstart+1,curr_frame-fstart+1+range_val);
    
    mymap = [1 1 1; colors_behaviors];
    imagesc([(frame_min-0.5)/fps (frame_max-0.5)/fps],[1 M],flip(mat(:,frame_min:frame_max),1))
    xlim([(curr_frame-fstart-range_val)/fps,(curr_frame-fstart+range_val)/fps])
    colormap(gca,mymap)
    caxis([-0.5,8.5])
    yticks(1:8)
    yticklabels(flip(MSortedLabels))
    xlabel('Time (s)','FontSize',label_font_size)
    xline((j-fstart)./fps);
    set(gca,'FontSize',6)
    set(gca,'TickDir','out') % draw the tick marks on the outside
    set(gca,'Color','w')
    set(gcf,'Color','w') % match figure background
    set(gca, 'ycolor', 'k') % black axis
    set(gca, 'xcolor', 'k')
    box off 
    xline((curr_frame-fstart+range_val)/fps,'k')
    yline(0.5)
    
    print(h,[fig_path group '_day' num2str(day) '_mouse' num2str(mouse) '/image' sprintf('%03d', c)],'-dpng','-r500')
    close(h)
    
    c = c + 1;
end

end
