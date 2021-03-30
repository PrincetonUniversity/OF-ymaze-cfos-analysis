function [] = exampleImageMousePaws(group,day,mouse,frame,colors_paws,fig_path,out_path,video_box_filename)
% EXAMPLEIMAGEMOUSEPAWS: plot example image of mouse with different colors
% for paw labels
%
% Input:
% - group: experimental group of interest
% - day: day of interest
% - mouse: id of mouse of interest
% - frame: frame of interest
% - colors_paws: colors used for labeling the different paws
% - fig_path: path to save figure
% - out_path: path to processed data
% - video_box_filename: path to h5 file with images of mouse in open field
% (only a boxed region around the mouse is considered)

if ~exist(fig_path,'dir')
    mkdir(fig_path)
end

%% get the data for the mouse and day of interest
mfile = matfile([out_path 'k100/' group '.mat']);

joints = mfile.('dataLEAPout')(mouse,day);
joints = joints{1};
joints = reshape(joints,36,size(joints,3));

%% get the data from the raw mouse videos (in a box)
mouse_video_data_box = h5read(video_box_filename,'/box',[1 1 1 frame],[400 400 1 frame]);

%% plot 

x_max = max(max(joints(1:18,frame)));
x_min = min(min(joints(1:18,frame)));
y_max = max(max(joints(19:end,frame)));
y_min = min(min(joints(19:end,frame)));

global axis_font_size

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,8,10];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+1, pos(4)+1])

set(gcf,'color','w')
imagesc(mouse_video_data_box(:,:,1,1))
hold on 
cmap = flipud(gray(256));
colormap(gca,cmap);
hold on 
scatter(joints(7,frame),joints(7+18,frame),70,colors_paws(2,:),'filled')
hold on
scatter(joints(8,frame),joints(8+18,frame),70,colors_paws(1,:),'filled')
hold on 
scatter(joints(14,frame),joints(14+18,frame),70,colors_paws(4,:),'filled')
hold on 
scatter(joints(15,frame),joints(15+18,frame),70,colors_paws(3,:),'filled')
ax = gca;
ax.FontSize = axis_font_size;
axis equal off
xlim([x_min x_max])
ylim([y_min y_max])

fig_name = [fig_path 'example_image_paws_labelled'];
print(gcf,[fig_name '.pdf'],'-dpdf','-r0');
close(gcf)

end
