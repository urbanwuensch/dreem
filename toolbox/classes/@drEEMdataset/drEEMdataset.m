classdef drEEMdataset
% <a href = "matlab:doc dreemdataset">Documentation of the drEEM toolbox</a>
%
% <strong>EXAMPLE(S)</strong>
%   1. Make a new, empty dataset (highly recommended)
%       samples = drEEMdataset.create;
%   2. Validate if your dataset is formatted correctly
%       drEEMdataset.validate(samples);

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
    properties
        % Handling metadata
        history (:,1) drEEMhistory                      % <-
        status (1,1) drEEMstatus                        % <-
        about (1,1) about                               % <-
        
        % Measurement data
        X (:,:,:) double {mustBeNumeric}                % <-
        XBlank (:,:,:) double {mustBeNumeric}           % <-
        abs (:,:) double {mustBeNumeric}                % <-
        absBlank (:,:) double {mustBeNumeric}           % <-
        suppSpectra (:,:) double {mustBeNumeric}
        
        % PARAFAC
        models (:,1) drEEMmodel
        
        % Measurement / optical axis information
        i (:,1) double {mustBeNumeric}                  % <-
        Ex (:,1) double {mustBeNumeric}                 % <-
        Em (:,1) double {mustBeNumeric}                 % <-
        nEx (1,1) double {mustBeNumeric}                
        nEm (1,1) double {mustBeNumeric}
        absWave (:,1) double {mustBeNumeric}            % <-
        suppSpectraAxis (:,1) double {mustBeNumeric}    
        nSample (1,1) double {mustBeNumeric}
        
        % Sample metadata
        filelist (:,1) cell                             % <-
        metadata  (:,:) table                           % <-
        opticalMetadata (:,:) table
        split drEEMdataset
        

        
        userdata % anything goes
        instrumentInfo struct % currently unused (placeholder)
        measurementInfo struct % currently unused (placeholder)
    end

    properties (Hidden = true,SetAccess = public)
        toolboxdata
        toolboxOptions=drEEMtoolbox.options;
    end

    properties (SetAccess = private, Hidden = true)
        Name
    end


    methods (Static=true)
        function data = create
            data=drEEMdataset;
            data.toolboxdata.version = drEEMtoolbox.version;

            % https://www.mathworks.com/matlabcentral/fileexchange/16450-get-computer-name-hostname
            [ret, name] = system('hostname');   
            if ret ~= 0
               if ispc
                  name = getenv('COMPUTERNAME');
               else      
                  name = getenv('HOSTNAME');      
               end
            end
            data.toolboxdata.host = strtrim(lower(name));
            data.toolboxdata.matlabVersion=version;
            data.toolboxdata.matlabToolboxes=ver;
            
            % data.metadata = table('Size', [0 3], ...
            %     'VariableTypes', {'double', 'string', 'datetime'}, ...
            %     'VariableNames', {'dilution_factor', 'pathlength', 'comment'});

            % CF conventions
            data.metadata=addprop(data.metadata,'standard_name','variable');
            data.metadata=addprop(data.metadata,'long_name','variable');
            data.metadata=addprop(data.metadata,'units','variable');
            data.metadata=addprop(data.metadata,'comment','variable');
            data.metadata=addprop(data.metadata,'coverage_content_type','variable');

            data.history=drEEMhistory;
            data.history(1).fname='drEEMdataset.create';
            data.history(1).fmessage='drEEMdataset created (empty)';
        end

        function validate(data)
            arguments
                data (1,1) {mustBeA(data,'drEEMdataset')}
            end
            
            cnt=1;
            if not(isempty(data.X))
                sz=size(data.X);
                if ndims(data.X)~=3
                    message=['EEMs field (',inputname(1),'.X) must have 3 dimensions. Validation function exited prematurely. Fix the issue and rerun the validation'];
                    throwAsCaller(MException("drEEM:Invalid",message))
                end

                if not(numel(unique(data.filelist))==numel(data.filelist))
                    e{cnt}='The sample identifiers ("filelist") are not unique. For your dataset to be FAIR-compliant and for the toolbox to work as expected, unique sample identfiers must be used.';
                    cnt=cnt+1;
                end
                if not(sz(1)==data.nSample)
                    e{cnt}='size of EEM dimension 1 not consistent with data.nSample';
                    cnt=cnt+1;
                end
                if not(sz(1)==numel(data.filelist))
                    e{cnt}='size of EEM dimension 1 not consistent with height of data.filelist';
                    cnt=cnt+1;
                end
                if not(sz(1)==height(data.metadata))
                    e{cnt}='size of EEM dimension 1 not consistent with height of metadata table';
                    cnt=cnt+1;
                end
                if not(sz(1)==numel(data.i))
                    e{cnt}='size of EEM dimension 1 not consistent with height of data.i';
                    cnt=cnt+1;
                end
                if not(sz(2)==numel(data.Em))
                    e{cnt}='size of EEM dimension 2 not consistent with data.Em';
                    cnt=cnt+1;
                end
                if not(sz(2)==data.nEm)
                    e{cnt}='size of EEM dimension 2 not consistent with data.nEm';
                    cnt=cnt+1;
                end
                if not(sz(3)==numel(data.Ex))
                    e{cnt}='size of EEM dimension 3 not consistent with data.Ex';
                    cnt=cnt+1;
                end
                if not(sz(3)==data.nEx)
                    e{cnt}='size of EEM dimension 3 not consistent with data.nEx';
                    cnt=cnt+1;
                end

                if any(all(all(isnan(data.X),2),3))
                    sidx=find(all(all(isnan(data.X),2),3))';
                    e{cnt}=['Some of the EEMs contain only missing numbers (sample(s): ',num2str(sidx),')'];
                    cnt=cnt+1;
                end

                if not(isempty(data.models))
                    f=find(arrayfun(@(x) not(isempty(x.loads{1})),data.models));
                    for j=1:(numel(f))
                        m=data.models(f(j));
                        if not(sz(1)==size(m.loads{1},1))
                            e{cnt}=['size of EEM dimension 1 not consistent with scores in the ',num2str(f(j)),'-component model'];
                            cnt=cnt+1;
                        end
                        if not(sz(2)==size(m.loads{2},1))
                            e{cnt}=['size of EEM dimension 2 not consistent with emission loadings in the ',num2str(f(j)),'-component model'];
                            cnt=cnt+1;
                        end
                        if not(sz(3)==size(m.loads{3},1))
                            e{cnt}=['size of EEM dimension 3 not consistent with excitation loadings in the ',num2str(f(j)),'-component model'];
                            cnt=cnt+1;
                        end
                        
                        if not(sz(1)==size(m.leverages{1},1))
                            e{cnt}=['size of EEM dimension 1 not consistent with leverages in the ',num2str(f(j)),'-component model'];
                            cnt=cnt+1;
                        end
                        if not(sz(2)==size(m.leverages{2},1))
                            e{cnt}=['size of EEM dimension 2 not consistent with leverages in the ',num2str(f(j)),'-component model'];
                            cnt=cnt+1;
                        end
                        if not(sz(3)==size(m.leverages{3},1))
                            e{cnt}=['size of EEM dimension 3 not consistent with leverages in the ',num2str(f(j)),'-component model'];
                            cnt=cnt+1;
                        end

                        if not(sz(1)==size(m.sse{1},1))
                            e{cnt}=['size of EEM dimension 1 not consistent with SSE in the ',num2str(f(j)),'-component model'];
                            cnt=cnt+1;
                        end
                        if not(sz(2)==size(m.sse{2},1))
                            e{cnt}=['size of EEM dimension 2 not consistent with SSE in the ',num2str(f(j)),'-component model'];
                            cnt=cnt+1;
                        end
                        if not(sz(3)==size(m.sse{3},1))
                            e{cnt}=['size of EEM dimension 3 not consistent with SSE in the ',num2str(f(j)),'-component model'];
                            cnt=cnt+1;
                        end

                    end
                end
            end
            
            if not(isempty(data.abs))
                sz=size(data.abs);
                if not(ismatrix(data.abs))
                    message=['Absorbance field (',inputname(1),'.abs) must have 2 dimensions. Validation function exited prematurely. Fix the issue and rerun the validation'];
                    throwAsCaller(MException("drEEM:Invalid",message))
                end
                if not(sz(1)==data.nSample)
                    e{cnt}='size of absorbance dimension 1 not consistent with data.nSample';
                    cnt=cnt+1;
                end
                if not(sz(1)==numel(data.filelist))
                    e{cnt}='size of absorbance dimension 1 not consistent with height of data.filelist';
                    cnt=cnt+1;
                end
                if not(sz(1)==height(data.metadata))
                    e{cnt}='size of absorbance dimension 1 not consistent with height of metadata table';
                    cnt=cnt+1;
                end
                if not(sz(2)==numel(data.absWave))
                    e{cnt}='size of absorbance dimension 2 not consistent with data.absWave';
                    cnt=cnt+1;
                end
                if any(all(isnan(data.abs),2))
                    sidx=find(all(isnan(data.abs),2))';
                    e{cnt}=['Some of the CDOM absorbance spectra contain only missing numbers (sample(s): ',num2str(sidx),')'];
                    cnt=cnt+1;
                end
            end
            
            % if not(isreal(data.abs))
            %     e{cnt}='Some of the CDOM absorbance spectra contain complex numbers';
            %     cnt=cnt+1;
            % end

            if not(isreal(data.X))
                e{cnt}='Some of the EEMs contain complex numbers';
                cnt=cnt+1;
            end

            if cnt>1
                varname = inputname(1);
                if not(isempty(varname))
                    varname=[' ("',varname,'")'];
                end
                message=[' \n <strong>Your dataset',varname,' did not pass the validation for one or several reasons: </strong> \n'];
                for j=1:numel(e)
                    message=[message,'\n ',num2str(j),':  ',e{j}];
                end
                message=[message,'\n Type "doc drEEM" or "doc drEEMdataset" to learn more'];
                throwAsCaller(MException("drEEM:datasetInvalid",message))
            end

            stack=dbstack;
            % Only spit out the message if the drEEMtoolbox version was
            % involved (user-facing function). Internally, we use
            % drEEMdataset.validate to do the job.
            if matches(stack(end).name,{'drEEMtoolbox.validatedataset','drEEMdataset.validate'})
                disp('<strong> drEEMdataset validation successful.</strong> Your dataset passed all checks.')
            end
        end

        function mustBeMetadataColumn(data,colname)
            if isempty(colname)
                return
            end
            if not(ismember(colname,data.metadata.Properties.VariableNames))
                message=['\n\n<strong>"',char(colname),'"</strong> is not a column in data.metadata. Your options are:\n'];
                flds=data.metadata.Properties.VariableNames;
                for j=1:numel(flds)
                    message=[' ',message,num2str(j),': ',flds{j},', '];
                end
                 throwAsCaller(MException("drEEM:IncorrectInput",message))
            end

        end

        function mustBeInRangeEm(data,emwave)
            if isempty(emwave)
                return
            end
            for j=1:numel(emwave)
                if data.Em(end)<emwave(j)||data.Em(1)>emwave(j)
                    message=['Emission wavelength out of range for data. Range: ',num2str(data.Em(1)),' - ',num2str(data.Em(end)),' nm'];
                    throwAsCaller(MException("drEEM:IncorrectInput",message))
                end
            end
        end

        function mustBeInRangeEx(data,exwave)
            if isempty(exwave)
                return
            end
            for j=1:numel(exwave)
                if data.Ex(end)<exwave(j)||data.Ex(1)>exwave(j)
                    message=['Excitation wavelength out of range for data. Range: ',num2str(data.Ex(1)),' - ',num2str(data.Ex(end)),' nm'];
                    throwAsCaller(MException("drEEM:IncorrectInput",message))
                end
            end
        end

        function mustBeInRangeSamplei(data,i)
            for j=1:numel(i)
                if not(ismember(i,data.i))
                    message='sample identifier is not valid (not a member): ';
                    throwAsCaller(MException("drEEM:IncorrectInput",message))
                end
            end
        end

        function f=modelsWithContent(data)
            f=find(arrayfun(@(x) not(isempty(x.loads{1})),data.models));
        end

        function f=validatableModels(data)
            f=find(arrayfun(@(x) not(isempty(x.loads{1})),data.models));
            for j=1:numel(data.split)
                fs{j,1}=find(arrayfun(@(x) not(isempty(x.loads{1})),data.split(j).models));
            end
            fs=unique(vertcat(fs{:}));
            f=intersect(f,fs);
        end
        
        function mustBeModel(data,fac)
            arguments
                data (1,1) {mustBeA(data,'drEEMdataset')}
                fac (1,1) {mustBeNumeric}
            end
            vec=@(x) x(:);
            fac=vec(fac);
            f{1}=vec(find(arrayfun(@(x) not(isempty(x.loads{1})),data.models)));
            
            for j=1:numel(data.split)
                f{j+1}=vec(find(arrayfun(@(x) not(isempty(x.loads{1})),data.split(j).models)));
            end
            message='';
            for j=1:numel(f)
                if any(not(ismember(fac,f{j})))
                    % Skip if fac is a nan input
                    if isscalar(fac)&&isnan(fac)
                        continue
                    end
                    if j==1
                        message=[message,num2str(fac),'-component model not present in the main dataset. \n'];
                    else
                        message=[message,num2str(fac),'-component model not present in the split #',num2str(j-1),'\n'];
                    end
                end
            end
            if not(isempty(message))
                throwAsCaller(MException("drEEM:IncorrectInput",message))
            end
        end

        function mustContainSamples(data)
            varname = inputname(1);
            if not(isempty(varname))
                varname=['"',varname,'"',': '];
            end
            message='';
            if data.nSample==0
               
               message=[message,'\n<strong>',varname,'Dataset contains no samples.\n</strong>' ...
                    ' \n'];
                throwAsCaller(MException("drEEM:NoSamples",message))
            end
        end


        

        function VariableNames=returnVariableNames(data)
            
            VariableNames=data.metadata.Properties.VariableNames;
            if not(isempty(VariableNames))
                VariableNames=cellfun(@(x) string(x),VariableNames);
            end

        end

        function sanityCheckAbsorbance(data)
            message=[];
            varname = inputname(1);
            if not(isempty(varname))
                varname=[varname,': '];
            end

            if isempty(data.abs)||all(isnan(data.abs(:)))
                message=[message,'\n<strong>',varname,'Absorbance data does not exist or consists only of missing numbers.\n</strong>' ...
                    ' \n'];
            end

            if any(all(isnan(data.abs),2))
                sample=find(all(isnan(data.abs),2));
                if not(isrow(sample))
                    sample=sample';
                end
                message=[message,'\n<strong>',varname,'Some absorbance spectra contain only missing numbers.\n</strong>' ...
                    ' sample(s): ',num2str(sample)];
            end

            if not(isempty(message))
                throwAsCaller(MException("drEEM:Insane",message))
            end
        end

        function sanityCheckIFE(data)
            message=[];
            varname = inputname(1);
            if not(isempty(varname))
                varname=[varname,': '];
            end
            if contains(data.status.IFEcorrection,{'applied by'})
                message=[message,'\n<strong>',varname,'Inner filter effects have already been corrected.\n</strong>' ...
                    ' If IFEs have already been corrected, another call to a correction is not allowed.\n'];
            end

            if isempty(data.abs)||all(isnan(data.abs(:)))
                message=[message,'\n<strong>',varname,'Absorbance data does not exist or consists only of missing numbers.\n</strong>' ...
                    ' In drEEM, IFEs are corrected with the absorbance-based approach; absorbance data is thus required.\n'];
            end

            if any(all(isnan(data.abs),2))
                sample=find(all(isnan(data.abs),2));
                if not(isrow(sample))
                    sample=sample';
                end
                message=[message,'\n<strong>',varname,'Some absorbance spectra contain only missing numbers.\n</strong>' ...
                    ' In drEEM, IFEs are corrected with the absorbance-based approach; absorbance data are thus required.\n' ...
                    ' sample(s): ',num2str(sample)];
            end

            if not(isempty(message))
                throwAsCaller(MException("drEEM:Insane",message))
            end
        end
        
        function sanityCheckScatter(data)
            message=[];
            varname = inputname(1);
            if not(isempty(varname))
                varname=[varname,': '];
            end
            if matches(data.status.blankSubtraction,{'unknown'})
                message=[message,'\n<strong>',varname,'State of blank subtraction unknown.</strong>' ...
                    ' It is recommended to subtract blanks in order to minimize scatter extent.' ...
                    ' Either use "subtractblanks.m" or manually change the state of "blankSubtraction"' ...
                    ' if blanks were subtracted elsewhere (e.g. instrument software).\n'];
            end
            if not(isempty(message))
                warning(sprintf(message),mode='verbose')
            end
        end
        
        function sanityCheckBlankSubtraction(data)
            message=[];
            varname = inputname(1);
            if not(isempty(varname))
                varname=[varname,': '];
            end
            if contains(data.status.blankSubtraction,{'applied by'})
                message=[message,' <strong>',varname,'Blank EEMs already subtracted.</strong>' ...
                    ' \n A repeated blank subtraction would lead to undesired results.\n'];
            end
            if not(isempty(message))
                throwAsCaller(MException("drEEM:Insane",message))
            end
        end

        function sanityCheckPARAFAC(data)
            message=[];
            varname = inputname(1);
            if not(isempty(varname))
                varname=[varname,': '];
            end
            if matches(data.status.scatterTreatment,{'unknown'})
                message=[message,'\n<strong>',varname,'State of scatter treatment is unknown.</strong>' ...
                    ' Either remove physical scatter (handlescatter.m) or manually' ...
                    ' overwrite the status of "data.scatterTreatment"' ...
                    ' if scatter was cut elsewhere (e.g. instrument software).\n'];
            end
            if matches(data.status.IFEcorrection,{'unknown'})
                message=[message,'\n<strong>',varname,'State of inner filter effect correction is unknown.</strong>' ...
                    ' You must account for inner filter effects either here (ifecorrection.m)',...
                    ' or in the instrument software. Alternatively, manually' ...
                    ' set the status of "data.IFEcorrection" to "deemed unnecessary"' ...
                    ' if absorbance was negligible (< 0.05 per cm at most).\n'];
            end
            if not(isempty(message))
                throwAsCaller(MException("drEEM:Insane",message))
            end
        end

        function sanityCheckSignalCalibration(data)
            varname = inputname(1);
            if not(isempty(varname))
                varname=[varname,': '];
            end
            message=[];
            if contains(data.status.signalCalibration,{'applied by'})
                message=[message,'\n<strong>',varname,'Signals in the dataset are already calibrated.</strong>\n' ...
                    ' A signal calibration to e.g. Raman units should be performed on uncalibrated data.\n'];
            end
            if not(isempty(message))
                throwAsCaller(MException("drEEM:Insane",message))
            end
        end

        function sanityCheckSpectralCorrection(data)
            varname = inputname(1);
            if not(isempty(varname))
                varname=[varname,': '];
            end
            message=[];
            if not(matches(data.status.spectralCorrection,"not applied"))
                message=[message,'\n<strong>',varname,'Spectral correction  is only possible if dataset status is "not applied".</strong>\n' ...
                    'Status is "',char(data.status.spectralCorrection),'"\n'];
            end
            if not(isempty(message))
                throwAsCaller(MException("drEEM:Insane",message))
            end
        end

        function simi=calculateSampleSimilarities(data)
            tens2mat=@(x,sz1,sz2,sz3) reshape(x,sz1,sz2*sz3);
            tcc=@(l1,l2) l1'*l2/(sqrt(l1'*l1)*sqrt(l2'*l2)); % Tucker's congruence coefficient


            combs=nchoosek(1:data.nSample,2);

            Xunf = tens2mat(data.X,data.nSample,data.nEm,data.nEx);
            simi=nan(data.nSample,data.nSample);
            for j=1:size(combs,1)
                X1=Xunf(combs(j,1),:);
                X2=Xunf(combs(j,2),:);

                nanout=isnan(X1)|isnan(X2);

                X1=X1(not(nanout));
                X2=X2(not(nanout));

                simi(combs(j,1),combs(j,2))=tcc(X1',X2');

            end
        end
        

        data =  rmsamples(data,index)
        data =  rmemission(data,index)
        data =  rmexcitation(data,index)
        results = fitpca(data)
        data = restore(data,whichone)
        data = undo(data)
        displayhistory(data)
    end

    methods
        function savedata = saveobj(data)
            savedata=data;
        end
    end

    

end