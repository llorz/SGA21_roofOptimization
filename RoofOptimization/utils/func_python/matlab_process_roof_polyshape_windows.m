function [] = matlab_process_roof_polyshape_windows(mesh_dir, mesh_name, save_dir)
fid = fopen('blender_path_win.txt','r');
blender_path = sscanf(fgets(fid), '%s\n');
pyfunc_dir = sscanf(fgets(fid), '%s\n');
fclose(fid);

fprintf('Use blender to process the polygon mesh\n')
system( "blender  " + ...
    "-b -P "+...
    pyfunc_dir + "py_process_roof_polyshape.py -- " + ...
    "-s1 " + mesh_dir + " " + ...
    "-s2 " + mesh_name + " "+ ...
    "-s3 " + save_dir + " ");


fid = fopen([save_dir,mesh_name,'_roof.mtl'],'a');
fprintf(fid, ['map_Kd ', mesh_name,'.jpg']);
fclose(fid);
end
