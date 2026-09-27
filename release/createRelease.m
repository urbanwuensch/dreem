% Close project if open
disp('<strong> Initializing the release session...</strong>')
clearvars
initSession()
cd(drEEMtoolbox.rootfolder)
cd ..
initSession("vanilla")
disp('<strong> Opening the drEEM project...</strong>')

p=openProject("matlab.toml");
cd(p.RootFolder)
disp('<strong> Defining the toolbox options for packing...</strong>')
OutputFile=string([char(p.RootFolder),filesep,'release',filesep,'drEEM-',char(drEEMtoolbox.version),'.mltbx']);
if isfile(OutputFile)
    delete(OutputFile)
    disp('deleted existing mltbx file')
end
releaseMax="";
disp('<strong> Defining options...</strong>')
% Get old, make new opts
opts = matlab.addons.toolbox.ToolboxOptions([pwd,filesep,'matlab.toml'],'dreem');
optsNew=matlab.addons.toolbox.ToolboxOptions(drEEMtoolbox.rootfolder,drEEMtoolbox.uuid);
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
optsNew.ToolboxVersion=char(drEEMtoolbox.version);
optsNew.MaximumMatlabRelease=releaseMax;
disp('<strong> Packing...</strong>')
matlab.addons.toolbox.packageToolbox(optsNew)
disp(['<strong> Done packing... (',OutputFile,')</strong>'])
close(p);
filebrowser
initSession(force=true)
