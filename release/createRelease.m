cd(fileparts(matlab.desktop.editor.getActiveFilename))
initSession("vanilla",force=true)
cd ..
p=openProject("dreem-2.prj");
cd(fileparts(matlab.desktop.editor.getActiveFilename))

disp('<strong> starting to pack...</strong>')
% Change these for the release!!!
uuid="186c884d-4f97-4318-9f12-cbf90a332379";
version='2.26.01';
OutputFile=string(['/Users/wuensch/git repros/dreem-2/release/drEEM-',version,'.mltbx']);
if isfile(OutputFile),delete(OutputFile),disp('deleted existing mltbx file'),end
releaseMax=matlabRelease.Release;

% Get old, make new opts
opts = matlab.addons.toolbox.ToolboxOptions(which("dreem-2.prj"));
optsNew=matlab.addons.toolbox.ToolboxOptions("/Users/wuensch/git repros/dreem-2/toolbox",uuid);
fnames=fieldnames(opts);
for j=1:numel(fnames)
    if matches(fnames{j},{'Identifier','ToolboxFolder'})
        continue
    else
        optsNew.(fnames{j})=opts.(fnames{j});
    end
end

% Overwrite some incorrect values that needed change compared to prj-file.
optsNew.OutputFile=OutputFile;
optsNew.ToolboxVersion=version;
optsNew.MaximumMatlabRelease=releaseMax;

matlab.addons.toolbox.packageToolbox(optsNew)
disp('<strong> done...</strong>')
initSession(force=true)