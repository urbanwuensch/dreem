classdef drEEMtoolbox < handle
    % <a href = "matlab:drEEMtoolbox.doc('drEEM')">Documentation of the drEEM toolbox</a>
    %
    % <strong>EXAMPLE(S)</strong>
    %   1. Make a class instance to call methods (highly recommended)
    %       tbx = drEEMtoolbox;
    %   2. Call a method from the class directly
    %       samples=drEEMtoolbox.processabsorbance(samples);

    % Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
    % Chalmers University of Technology
    % Department of Architecture and Civil Engineering
    % Sven Hultins Gata 6
    % 41296 Gothenburg (Sweden)
    properties (Constant = true, Hidden = false)
        version = "2.25.12"
        url = "https://zenodo.org/records/17971456/files/drEEM-2.25.12.mltbx?download=1"
        requiredVersion = 'R2024b'
        rootfolder = drEEMtoolbox.tbxpath;
        options=drEEMtoolbox.defaultOptions;
    end

    % These are not meant for the general public, Origin Pro is required.
    methods (Hidden = true,Static = true)
        Xout = aqualogimport(workingpath,selector,deselector)
        dataout = sampleQimport(workingpath,data)
        [DS,DSb] = processHJYdata(Xin,opt)
    end


    methods (Hidden = true,Static = true)
        function tbx=drEEMtoolbox
            % Class constructor method

            % Check required versions of MATLAB and toolboxes
            drEEMtoolbox.versionRequires
            % Check if multiple versions installed (throws error!)
            drEEMtoolbox.countinstallations
            % Check for updates and updates if desired
            drEEMtoolbox.updatedreem

        end



    end

    % These are not really needed to be visible to the user
    methods (Hidden = true,Static=true)
        [ modelout,neworder] = reordercomponents( model,varargin )
        passed = silentvalidation(data,fac)

        function out=tbxpath
            out=fileparts(which('drEEMtoolbox.m'));
            out=erase(out,"@drEEMtoolbox");
        end

        function [idx,distance] = mindist(vec,value)
            if isscalar(value)
                [distance,idx]=min(abs(vec-value));
            else
                for j=1:numel(value)
                    [distance(j,1),idx(j,1)]=min(abs(vec-value(j)));
                end
            end

        end

        function out = isNearest(vec,value)
            if isscalar(value)
                [distance,idx]=min(abs(vec-value));
            else
                error('value must be scalar')
            end
            out=vec==vec(idx);

        end

        f=dreemfig(fighandlein)
        f=dreemuifig

    end

    % These are toolbox internal, would just be confusing if visible
    methods (Static = true, Hidden = true)
        function methodEnd(dataout,name)
            if drEEMtoolbox.OvrWrteUnless
                assignin("base",dataout,name)
            end
        end

        function scenario=outputscenario(n_in)

            if n_in ~= 0 && not(drEEMtoolbox.options.OvrWrteUnless)
                % User wants explicit assignments & toolbox agrees
                scenario=categorical({'explicitOut'});
            end
            if drEEMtoolbox.options.OvrWrteUnless && n_in==0
                % User wants workspace variable to be overwritten  & toolbox agrees
                scenario=categorical({'implicitOut'});
            end
            if drEEMtoolbox.options.OvrWrteUnless && n_in~=0
                % User wants explicit assignments but toolbox disagrees
                scenario=categorical({'explicitOut'});
            end
            if not(drEEMtoolbox.options.OvrWrteUnless) && n_in==0
                % Toolbox is set to make explicit assignments, but user didn't give output args
                scenario=categorical({'explicitOut'});
            end
        end
    end

    methods (Static = true , Access = public)

        %doc function
        doc(fname)


        data = importeems(filePattern,options)
        data = importabsorbance(filePattern,options)
        dataout = associatemetadata(data,pathtofile,metadatakey,datakey)
        dataout=upgradedataset(data,atypicalFieldnames)

        % Merging function
        data = mergedatasets(varargin)

        % Status-specific functions
        dataout=changestatus(data)

        % History-specific functions
        data = addcomment(data,comment)
        function validatedataset(data)
            drEEMdataset.validate(data)
        end

        function displayhistory(data)
            drEEMdataset.displayhistory(data)
        end

        % Benchmark the system performance
        [singlescore,multiscore]=benchmark

        % Data processing
        varargout = alignsamples(varargin)
        dataout = processabsorbance(data,options)
        [dataout,emout,exout] = ifecorrection(data)
        dataout = subtractblanks(samples,blanks)
        dataout = spectralcorrection(data,options)
        dataout = ramancalibration(samples,blanks,options)
        dataout = handlescatter(data,varargin)
        dataout = subdataset(data,options)
        dataout = zapnoise(data,sampleIdent,emRange,exRange)
        dataout = scalesamples(data,option)
        dataout = rmspikes(data,name_value)

        % Slopes, peaks, indicies
        dataout = fitslopes(data,options)
        dataout = pickpeaks( data,options)

        % PARAFAC
        dataout = fitparafac(data,options)
        dataout = splitdataset(data,options)
        viewsplitvalidation(data,fac)
        fmax = scores2fmax(data,f)
        dataout = projectmodel(data,file)
        murea(data)

        % Data export
        export2openfluor(data, f, filename)
        export2zip(data,filename)
        %export2netcdf(data,filename)
        exportresults(data,filename,f,name_value)
        %fhandle = reportresidualanalysis(data,ftarget,mdfield)

        % Visualization (incl. app workarounds)
        % import functions
        importwizard
        viewspectralvariance(data)
        vieweems(data) % mlapp with m-file
        viewmodels(data,startTab,f) % mlapp with m-file
        viewdmr(data,f) % mlapp with m-file
        viewcompcorr(data) % mlapp with m-file
        viewhistory(data) % mlapp with m-file
        %explorevariability(data) % not shipping yet.
        viewscatter(data)
        viewabsorbance(data)
        [summary,M]  =  viewopenfluormatches(filename)

    end

    % These are hidden only used for class constructor
    methods (Hidden = true,Static = true)
        function out=defaultOptions
            out.plotByDefault = true;
            out.OvrWrteUnless = false;
            out.uifig = true;
        end
        function versionRequires(debugging)
            arguments
                debugging (1,:) {mustBeA(debugging,'logical')} = false
            end
            lastcheck=getenv('drEEM ML version check');
            if datetime(lastcheck)<datetime('today')||isempty(lastcheck)
                if isMATLABReleaseOlderThan(drEEMtoolbox.requiredVersion)
                    error(['You need Matlab ',drEEMtoolbox.requiredVersion,' or newer to use this version of drEEM.'])
                end
                mallver=ver;
                tbs={'Statistics and Machine Learning Toolbox' 'Parallel Computing Toolbox'};
                isthere=zeros(1,numel(tbs));
                for n=1:numel(tbs)
                    isthere(n)=any(~cellfun(@isempty,strfind({mallver.Name},tbs{n})));
                end
                if all(isthere)
                    % No action or information needed.
                else
                    warning(['Missing toolbox(es):',tbs{~isthere},'. Some toolbox functionality will not be available.'])
                end
                setenv('drEEM ML version check',char(datetime("today"))),if debugging,disp('setenv executed (ML version check + addon tbxs)'),end
            else
                % All good, nothing to do.
            end


        end

        function countinstallations
            existing=ver;
            existing=existing(arrayfun(@(x) matches(x.Name,'drEEM Toolbox'),existing));
            if numel(existing)>1
                for j=1:numel(existing)
                    if str2double(existing(j).Version(1))==0
                        message=['\n Old versions of drEEM detected. Remove these from your' ...
                            ' path before continuing. Your options are:\n' ...
                            '  1) Use<strong> >> pathtool</strong> to solve the issue interactively.\n' ...
                            '  2) Use<strong> >> restoredefaultpath</strong> for a quick solution (but you loose all custom path settings)'];
                        throwAsCaller(MException("drEEM:versionConflict",message))
                    end
                end
                message=['\n Multiple versions of drEEM detected. Since this complicates things tremendously, please clean your path environment' ...
                    ' before continuing. Your options are:\n' ...
                    '  1) Use<strong> >> pathtool</strong> to solve the issue interactively.\n' ...
                    '  2) Use<strong> >> restoredefaultpath</strong> for a quick solution (but you loose all custom path settings)\n\n' ...
                    ' Afterwards, you should reinstall the latest version of drEEM via Matlab File Exchange (via the Add-Ons Explorer or your Web-browser.'];
                throwAsCaller(MException("drEEM:versionConflict",message))
            end
        end

        function updatedreem(directory,debugging,existingversion,onlineversion)
            arguments
                directory (1,:) {mustBeText} = 'https://gitlab.com/dreem/dreem-2/-/raw/main/toolbox/@drEEMtoolbox/versions.txt';
                debugging (1,:) {mustBeA(debugging,'logical')} = false
                existingversion (1,:) {mustBeNumeric} = [];
                onlineversion (1,:) {mustBeNumeric} = [];
            end

            % Has check already been done today? Trying to minimize delays
            lastcheck=getenv('drEEM update checked');
            if datetime(lastcheck)<datetime('today')||isempty(lastcheck)
                check=true;
                if debugging,disp('check = true'),end
            else
                check=false;
                if debugging,disp('check = false'),end
            end

            if not(check)&&not(debugging)
                return
            end

            try
                options = weboptions;
                options.Timeout=1;
                vhist=webread(directory,options);
            catch
                setenv('drEEM update checked',char(datetime("today")))
                if debugging,disp('version document download failed.'),end
                if debugging,disp('setenv=true'),end
                return
            end
            cellvhist=textscan(vhist,'%s%s','Delimiter',';');

            online=table;
            online.Version=cellvhist{1}{1};
            online.url=cellvhist{2}{1};
            clearvars cellvhist

            existing=ver;
            existing=existing(arrayfun(@(x) matches(x.Name,'drEEM Toolbox'),existing));
            existing=rmfield(existing,{'Date','Release','Name'});
            existing=struct2table(existing);


            % digest version numbers into parts
            online.Parts=cellfun(@(x) str2double(x),strsplit(online.Version,'.'));
            existing.Parts=cellfun(@(x) str2double(x),strsplit(existing.Version,'.'));

            if debugging
                existing.Parts=existingversion;
                online.Parts=onlineversion;
            end

            % What is the max number of version parts?
            maxPart=max([numel(online.Parts) numel(existing.Parts)]);
            % First part, check if number of elements differs between
            % the online vs. existing versioning. Replace with a 0 if
            % so (thinking that the other will be larger than that).
            for j=1:maxPart
                if j>numel(existing.Parts)
                    existing.Parts(j)=0;
                    if debugging,disp('existing version zero insertion'),end
                end
                if j>numel(online.Parts)
                    online.Parts(j)=0;
                    if debugging,disp('online version zero insertion'),end
                end
            end

            % Compare versions
            update = false; % Initialize update flag
            if debugging,disp(['online:   ',num2str(online.Parts)]),disp(['existing: ',num2str(existing.Parts)]),end
            for j=1:maxPart
                if online.Parts(j) > existing.Parts(j)
                    update = true;
                    if debugging,trigger={'major','year','month','day'};disp(['update = true | trigger = ',trigger{j}]),end
                    break
                elseif online.Parts(j) < existing.Parts(j)
                    if debugging,disp('update = false, implausible scenario'),end
                    disp(['online:   ',num2str(online.Parts)]),disp(['existing: ',num2str(existing.Parts)])
                    disp('<strong>Online version out of date?</strong> Either you are a developer, or something is wrong. Returning...')
                    return
                elseif online.Parts(j) == existing.Parts(j)
                    update = false;
                    if debugging,disp('update = false, plausible scenario'),end
                end
            end

            if update
                url=online.url;
            else
                url='';
            end

            clearvars -except url directory debugging

            if not(isempty(url))
                if debugging,disp('update execution'),end
                answer = questdlg('Your version of the drEEM toolbox is outdated. Would you like to update?' ...
                    ,'Update Notice','Update now','Open File exchange','No','Update now');
            else
                setenv('drEEM update checked',char(datetime("today")))
                disp('<strong>Using the latest version of the drEEM toolbox.</strong>')
                return
            end

            switch answer
                case 'Open File exchange'
                    web("https://se.mathworks.com/matlabcentral/fileexchange/162526-dreem-toolbox/")
                    setenv('drEEM update checked',char(datetime("today"))),if debugging,disp('setenv executed (update check)'),end
                case 'Update now'
                    % Kick off the ? parts of the URL
                    digested=strsplit(url,'?');
                    % Disect the URL and take the last bit (the file)
                    digested=strsplit(digested{1},'/');
                    if contains(digested{end},'.mltbx')
                        if debugging,disp('attempt install'),end
                        disp('<strong>Downloading...</strong> (approx 100MB, might take a while)')
                        try
                            websave(digested{end}, url);
                            disp('<strong>Installing...</strong>')
                            matlab.addons.toolbox.installToolbox(digested{end});
                            delete(digested{end})
                        catch
                            warning('Install failed, redirecting to File Exchange instead')
                            pause(2)
                            web("https://se.mathworks.com/matlabcentral/fileexchange/162526-dreem-toolbox/")
                        end
                    else
                        warning('No .mltbx file found online, redirecting to File Exchange instead')
                        pause(2)
                        web("https://se.mathworks.com/matlabcentral/fileexchange/162526-dreem-toolbox/")
                    end
                case 'No'
                    setenv('drEEM update checked',char(datetime("today"))),if debugging,disp('setenv executed (update check)'),end
                    disp('<strong>Update skipped</strong>. Will check again tomorrow...')
                otherwise
                    setenv('drEEM update checked',char(datetime("today"))),if debugging,disp('setenv executed (update check)'),end
                    disp('<strong>Update skipped</strong>. Will check again tomorrow...')
            end

        end

        function displaycitationinformation

            zenodoref='Wünsch, U., Murphy, K., Esmaeeli, A., & Bro, R. (2025). drEEM toolbox version 2. Zenodo. https://doi.org/10.5281/zenodo.17182160';
            amethoreg='Murphy, Kathleen R., et al. (2013). Fluorescence Spectroscopy and Multi-Way Techniques. PARAFAC. Analytical Methods, vol. 5, no. 23, Royal Society of Chemistry (RSC), p. 6557, https://doi.org/10.1039/c3ay41160e.';
            zenodoweb='https://doi.org/10.5281/zenodo.17182160';
            amethoweb='https://doi.org/10.1039/c3ay41160e';


            zenodocopy=['<a href = "matlab:clipboard(''copy'',''',zenodoref,''')">click to copy reference</a>'];
            amethocopy=['<a href = "matlab:clipboard(''copy'',''',amethoreg,''')">click to copy reference</a>'];

            zenodovisit=['<a href = "matlab:web(''',zenodoweb,''')">visit resource website</a>'];
            amethovisit=['<a href = "matlab:web(''',amethoweb,''')">visit resource website</a>'];

            message=['\n<strong>drEEM is free & open source.</strong> We ask that you cite these resources to indicate its use:' ...
                '\n    1. Toolbox: Zenodo entry (',zenodocopy,' | ',zenodovisit,')'...
                '\n    2. PARAFAC methodology: 2013 tutorial review (',amethocopy,' | ',amethovisit,')'...
                '\n\n    We also ask that you cite the appropriate primary references for peaks, slopes, and indicies.'];
            try
                disp(sprintf(message))
            catch
                % Nothing (the errors usually occur during the execution
                % which won't be caught by the try-catch statement
            end
        end
    end

end