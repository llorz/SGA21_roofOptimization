clc; clf; clear;
addpath(genpath('..\RoofOptimization/utils/'))
addpath('func_local\')
dt_dir = '.\';
all_files = dir([dt_dir, 'res_roof_graph/*.verts']);

ifile = 1000;

file_name = all_files(ifile).name(1:end-6);
I = imread([dt_dir, 'dt_roof_image\', file_name, '.jpg']);
[V, F] = read_roof_graph([dt_dir, 'res_roof_graph\'], file_name);

M1 = my_read_polygon_shapes([dt_dir, 'res_building\'], file_name);

err = err_planarity(M1.verts, M1.faces);

obj = RoofGraph(V, F);
obj.IfPlotShowLabel = false;

figure(1); clf;
subplot(1,2,1);
imshow(I); hold on;
plot(obj);

subplot(1,2,2); cla;
plot_building(M1.verts, M1.faces); hold on;
imshow(I); hold on;
view([-30,60]); title(['planarity err = ',num2str(err, '%.6f')])
%%
roof_height = 60;
body_height = 150;

X1 = construct_3D_roof_from_valid_roof_graph(obj.V, obj.F, obj.vid_roof, roof_height);
M2 = construct_building(X1, obj.F, body_height);


figure(2); clf;
subplot(1,2,1); cla;
plot_building(M1.verts, M1.faces); hold on;
imshow(I); hold on;
view([-30,60]); title('old')


subplot(1,2,2); cla;
plot_building(M2.verts, M2.faces); hold on;
imshow(I); hold on;
view([-30,60]); title('change roof/body height')
