function [] = matlab_triangulate_mesh(mesh_dir, mesh_name, save_dir)
fid = fopen('blender_path.txt','r');
blender_path = sscanf(fgets(fid), '%s\n');
pyfunc_dir = sscanf(fgets(fid), '%s\n');
fclose(fid);

fprintf('Use blender to triangulate the polygon mesh\n')
system(blender_path + " " + ...
    "-b -P "+...
    pyfunc_dir + "py_triangulate_mesh.py -- " + ...
    "-s1 " + mesh_dir + " " + ...
    "-s2 " + mesh_name + " "+ ...
    "-s3 " + save_dir + " ");
end