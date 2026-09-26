% Close project if open
initSession(force=true)
cd(drEEMtoolbox.rootfolder)
cd ..
initSession("vanilla",force=true)
p=openProject("matlab.toml");

disp('<strong> starting to pack...</strong>')
% Never change this unless you want this to be treated as a seperate toolbox
uuid=drEEMtoolbox.uuid;
% Change these for the release!!!
drEEMversion=char(drEEMtoolbox.version);
OutputFile=string([char(p.RootFolder),filesep,'release',filesep,'drEEM-',drEEMversion,'.mltbx']);
if isfile(OutputFile),delete(OutputFile),disp('deleted existing mltbx file'),end
releaseMax="";

% Get old, make new opts
opts = matlab.addons.toolbox.ToolboxOptions('matlab.toml');
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
optsNew.ToolboxVersion=drEEMversion;
optsNew.MaximumMatlabRelease=releaseMax;

matlab.addons.toolbox.packageToolbox(optsNew)
disp('<strong> done...</strong>')
initSession(force=true)
% Close project