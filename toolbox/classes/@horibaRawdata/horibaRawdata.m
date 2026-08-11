classdef horibaRawdata
    % Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
    % Chalmers University of Technology
    % Department of Architecture and Civil Engineering
    % Sven Hultins Gata 6
    % 41296 Gothenburg (Sweden)
    properties
        AbsI1darkSample
        Abs_horiba
        AbsI1Sample
        Abs_wave
        AbsI1darkBlank
        AbsI1Blank
        Ex
        Em
        S1Blank
        S1DarkBlank
        MCorrect
        R1Blank
        AbsR1Blank
        R1DarkBlank
        AbsR1darkBlank
        XCorrect
        AbsXCorrect
        S1Sample
        S1DarkSample
        R1Sample
        AbsR1Sample
        R1DarkSample
        AbsR1darkSample
        integrationtime
        Em_parkpos
        Em_PixelBin
        CCD_gain
        filelist (:,1) cell
        opjfile
        nSample
        history (:,1) drEEMhistory
        date_measured
    end
    methods (Static,Access=public,Hidden=true)
        varargout = importNetCDF(file,version)
        varargout = importAqualogOPJ(folder,version)
    end
    methods (Access=public,Static)
        
        

        function dataout = deletesamples(data,options)
            arguments
                data {mustBeA(data,'horibaRawdata')}
                options.outSample (1,:) {mustBeA(options.outSample,'logical')} = false
            end
            dataout=data;
            if not(size(options.outSample,2)==data.nSample)
                message=['<strong>outSample must be specified as logical array of the size [', ...
                    num2str(data.nSample),' x 1].</strong> Why? ' ...
                    'subdataset works with results of comparisons. E.g. ' ...
                    'outSample=matches(data.filelist,''sample01''), ' ...
                    'outSample=contains(data.metadata.location,''siteA''), ' ...
                    'or outSample=data.i==1. '];
                throwAsCaller(MException("drEEM:invalid",message))
            end

            props=properties(horibaRawdata);

            for j=1:numel(props)
                if size(dataout.(props{j}),1)==dataout.nSample
                    switch ndims(dataout.(props{j}))
                        case 2
                            dataout.(props{j})(options.outSample,:)=[];
                        case 3
                            dataout.(props{j})(options.outSample,:,:)=[];
                    end
                end
            end
            dataout.nSample=numel(dataout.filelist);
            % drEEMhistory entry
            st = dbstack;
            fullName = st(1).name;
            idx=height(dataout.history)+1;
            dataout.history(idx,1)=...
                drEEMhistory.addEntry(fullName,['deleted samples ',num2str(find(options.outSample))],[],drEEMdataset.create);



        end

        function dataout = fixfilename(data,wrong,corrected,mode)
            arguments
                data {mustBeA(data,'horibaRawdata')}
                wrong (1,:) {mustBeText}
                corrected (1,:) {mustBeText}
                mode {mustBeText(mode),mustBeMember(mode,["matches","contains"])} = "matches";
            end

            switch mode
                case "matches"
                    wrong_i=matches(data.filelist,char(wrong));
                case "contains"
                    wrong_i=contains(data.filelist,char(wrong));
            end
            if isempty(wrong_i)
                error('Your input to "wrong" yielded no results. Check the string...')
            elseif sum(wrong_i)>2
                error('Your input to "wrong" yielded multiple results. Check the string or change the "mode" option...')
            end
            data.filelist(wrong_i)={char(corrected)};

            dataout=data;
            message=['Replaced filelist entry "',char(wrong),'" with "',char(corrected),'"'];
            disp(message)
            % drEEMhistory entry
            st = dbstack;
            fullName = st(1).name;
            idx=height(dataout.history)+1;
            dataout.history(idx,1)=...
                drEEMhistory.addEntry(fullName,message,[],drEEMdataset.create);


        end

        function dataout = replaceXMcorrect(data,pathtofile,options)
            arguments
                data (1,1) {mustBeA(data,'horibaRawdata')}
                pathtofile {mustBeFile}
                options.plot (1,1) {mustBeA(options.plot,'logical')} = true
            end

            dataout=data;

            load(pathtofile,"x")
            % interpolate the reference Mcorrect to the new wavelengths. Xcor was not changed (after reverting the Dennis issue).
            mci=interp1(x.Em,x.Mcorrect,dataout.Em)';
            xci=interp1(x.Ex,x.Xcorrect,dataout.Ex)';

            % Check if even needed
            %fitlm(diff(dataout.MCorrect(1,:)),diff(mci)).plot
            % plot(x.Em,x.Mcorrect),hold on,plot(dataout.Em,dataout.MCorrect(1,:))
            % plot(x.Ex,x.Xcorrect),hold on,plot(dataout.Ex,dataout.XCorrect(1,:))
            %pause
            Mcor_SSE=sum((dataout.MCorrect(1,:)-mci).^2,"omitmissing");
            Xcor_SSE=sum((dataout.XCorrect(1,:)-xci).^2,"omitmissing");

            rSSE_m=Mcor_SSE./sum(mci.^2,"omitmissing")*100;
            rSSE_x=Xcor_SSE./sum(xci.^2,"omitmissing")*100;

            if rSSE_m>1e-3||rSSE_x>1e-3
                disp(['Found [',num2str(rSSE_m),',',num2str(rSSE_x),']% error in Mcor and XCor (respectively) relative to provided "reference" correction factors. Replacing both...'])
            else
                st = dbstack;
                fullName = st(1).name;
                disp([fullName,' called, but no difference between reference and dataset found.'])
                return
            end

            dataout.MCorrect=repmat(mci,dataout.nSample,1);
            dataout.XCorrect=repmat(xci,dataout.nSample,1);

            if options.plot
                if drEEMtoolbox.options.uifig
                    f=drEEMtoolbox.dreemuifig;
                else
                    f=drEEMtoolbox.dreemfig;
                end
                f.Name='horibaRawdata.replaceXMcorrect';
                t=tiledlayout(f,"flow",TileSpacing="compact");
                ax=nexttile(t);
                plot(ax,data.Ex,data.XCorrect(1,:),'k',DisplayName='before')
                hold(ax,"on")
                plot(ax,dataout.Ex,dataout.XCorrect(1,:),'r',DisplayName='after')
                title(ax,'Excitation')
                xlabel(ax,'Excitation (nm)')
                ylabel(ax,'Correction factor')
                ax=nexttile(t);
                plot(ax,data.Em,data.MCorrect(1,:),'k',DisplayName='before')
                hold(ax,"on")
                plot(ax,dataout.Em,dataout.MCorrect(1,:),'r',DisplayName='after')
                title(ax,'Emission')
                xlabel(ax,'Emission (nm)')
                ylabel(ax,'Correction factor')
                legend(ax)

            end


            % drEEMhistory entry
            st = dbstack;
            fullName = st(1).name;
            idx=height(dataout.history)+1;
            dataout.history(idx,1)=...
                drEEMhistory.addEntry(fullName,'Replaced Xcorrect and Mcorrect spectra',[],drEEMdataset.create);

        end

        function dataout = changeparkposition(data,offset)
            arguments
                data (1,1) {mustBeA(data,'horibaRawdata')}
                offset (1,1) {mustBeNumeric}
            end

            dataout=data;

            st = dbstack;
            fullName = st(1).name;
            if offset==0
                disp([fullName,' called, but no offset was found.'])
                return
            else
                disp(['<strong>Added</strong> an emission offset of ',num2str(offset),' nm. (Emission + Emission Parkposition)'])
            end
            dataout.Em=dataout.Em+offset;
            dataout.Em_parkpos=dataout.Em_parkpos+offset;

            % drEEMhistory entry
            idx=height(dataout.history)+1;
            dataout.history(idx,1)=...
                drEEMhistory.addEntry(fullName,['Changed Park position of emission detector (incl. emission axis!) by adding ',num2str(offset),' nm'],[],drEEMdataset.create);
        end

        function dataout = autofixS1DarkSpectra(data,options)
            arguments
                data (1,1) {mustBeA(data,'horibaRawdata')}
                options.thresholdFactor (1,1) {mustBeNumeric(options.thresholdFactor)} = 2
                options.plot (1,1) {mustBeA(options.plot,'logical')} = true
            end
            dataout=data;


            %% Replace lit up dark spectra
            % Find the Excitation of the Park position (Rayleigh will be
            % there if the scan wasn't dark)
            monopark=dataout.Ex(end);
            monopark=drEEMtoolbox.mindist(dataout.Em,monopark);

            % Extract sample and blank spectra for the purpose of flagging
            checkspectra=[dataout.S1DarkSample;dataout.S1DarkBlank];
            % Center and square the spectra (to avoid negative medians)
            checkspectra=(checkspectra-median(checkspectra,2,"omitmissing"));
            
            % Extract the median across all spectra. The trigger will
            % involve only the mono-park position, but the median does
            % involve the whole spectrum of all spectra. I think that's
            % more stable.
            medianDark=median(trapz(checkspectra,2));

            % The replacement part...
            % Threshold factor... I set this myself, no user option.
            % For now, that seems to work just fine
            % times higher than the median will get flagged
            thresholdFactor=5; 
            


            if any(checkspectra(:,monopark)>(thresholdFactor*medianDark))
                % option to make the plots a new figure
                newfig=false;
                if options.plot
                    if drEEMtoolbox.options.uifig
                        f=drEEMtoolbox.dreemuifig;
                    else
                        f=drEEMtoolbox.dreemfig;
                    end
                    f.Name='horibaRawdata.autofixS1DarkSpectra';
                    t=tiledlayout(f,"flow",TileSpacing="compact");
                    ax=nexttile(t);
                end
                % Extract the indices of lit up spectra
                replacethese=checkspectra(:,monopark)>(thresholdFactor*medianDark);
                if options.plot
                    yax=[dataout.S1DarkSample;dataout.S1DarkBlank];
                    p1=plot(ax,dataout.Em,yax,'k');
                    hold(ax,'on')
                    p2=plot(ax,dataout.Em,yax(replacethese,:),'r');
                    legend([p1(1) p2(1)],{'All dark (samples + blanks)','flagged as lit-up'})
                    title(ax,'Original dark spectra, including lit-up ones (red)')
                    xlabel(ax,'Emission (nm)')
                    ylabel(ax,'S1Dark Sample / Blank intensity')
                end
                % Then split by samples and blanks
                replacethese1=replacethese(1:dataout.nSample);
                replacethese2=replacethese(dataout.nSample+1:end);

                % Make sure to NaN and replace separately for different
                % integration times (spectra differ)
                itimes=unique(dataout.integrationtime);
                for j=1:numel(itimes)
                    %Samples
                    spec=dataout.S1DarkSample(dataout.integrationtime==itimes(j),:);
                    replacehere=replacethese1(dataout.integrationtime==itimes(j));

                    spec(replacehere,:)=nan;
                    if all(isnan(spec(:)))
                        error('Cannot replace the lit-up dark spectrum/spectra. Investigate manually...')
                    end
                    spec=fillmissing(spec,"nearest",1);
                    dataout.S1DarkSample(dataout.integrationtime==itimes(j),:)=spec;

                    %Blanks
                    spec=dataout.S1DarkBlank(dataout.integrationtime==itimes(j),:);
                    replacehere=replacethese2(dataout.integrationtime==itimes(j));
                    spec(replacehere,:)=nan;
                    if all(isnan(spec(:)))
                        error('Cannot replace the lit-up dark spectrum/spectra. Investigate manually...')
                    end
                    spec=fillmissing(spec,"nearest",1);
                    dataout.S1DarkBlank(dataout.integrationtime==itimes(j),:)=spec;

                end

                if options.plot
                    ax=nexttile(t);
                    yax=[dataout.S1DarkSample;dataout.S1DarkBlank];
                    p1=plot(ax,dataout.Em,yax,'k');
                    hold(ax,'on')
                    p2=plot(ax,dataout.Em,yax(replacethese,:),'r');
                    legend([p1(1) p2(1)],{'All dark (samples + blanks)','replacements'})
                    title(ax,'Fixed dark spectra, including lit-up ones (red)')
                    xlabel(ax,'Emission (nm)')
                    ylabel(ax,'S1Dark Sample / Blank intensity')
                end

                % drEEMhistory entry
                replaced=find(replacethese1|replacethese2);
                message=['Found one or more lit up S1 dark spectrum (sample or blank) and replaced it with the nearest dark neighbor. Sample(s): [',num2str(replaced(:)'),']'];
                disp(message)
                st = dbstack;
                fullName = st(1).name;
                idx=height(dataout.history)+1;
                dataout.history(idx,1)=...
                    drEEMhistory.addEntry(fullName,message ...
                    ,[],drEEMdataset.create);
            else
                newfig=true;
                disp('Good news, all your dark spectra (S1DarkSample + S1DarkBlank appear to be dark.')
            end


            %% Fix noisy S1Dark spectra (noisy pixels), main purpose of the function
            % Extract S1Dark spectra (samples + blanks)
            spectra=dataout.S1DarkSample;
            blankspectra=dataout.S1DarkBlank;
            % Subtract the median of each spectrum
            spectra=spectra-median(spectra,2);
            blankspectra=blankspectra-median(blankspectra,2);

            % Square the spectra
            spectra=spectra.^2;
            blankspectra=blankspectra.^2;

            % Concatenate these guys to analyze them in one go
            allspectra=cat(1,spectra,blankspectra);

            % Calculate the median of every squared pixel
            medspectrum=median(allspectra,1);


            if options.plot
                if newfig
                    if drEEMtoolbox.options.uifig
                        f=drEEMtoolbox.dreemuifig;
                    else
                        f=drEEMtoolbox.dreemfig;
                    end
                    f.Name='horibaRawdata.autofixS1DarkSpectra';
                    t=tiledlayout(f,"flow",TileSpacing="compact");
                end
                ax=nexttile(t);
                h1=plot(ax,dataout.Em,dataout.S1DarkSample,'k',DisplayName='before samples');
                hold(ax,'on')
                h2=plot(ax,dataout.Em,dataout.S1DarkBlank,'r',DisplayName='before blanks');
                legend([h1(1) h2(1)])
                title(ax,'Dark spectra (before fixing)')
            end

            % Count deviation threshold for tagging of bad ones
            bad=allspectra>(medspectrum*options.thresholdFactor);
            if any(bad(:))
                % drEEMhistory entry
                st = dbstack;
                fullName = st(1).name;
                idx=height(dataout.history)+1;
                dataout.history(idx,1)=...
                    drEEMhistory.addEntry(fullName, ...
                    'Found noisy S1Dark measurements and replaced them with valid neighboring samples', ...
                    [],drEEMdataset.create);
            else
                disp('No noisy S1DarkSample or S1DarkBlank found')
                return
            end

            % Now untangle samples and blanks
            badsample=bad(1:dataout.nSample,:);
            badblank=bad(dataout.nSample+1:end,:);

            % NaN the bad ones
            dataout.S1DarkSample(badsample)=nan;
            dataout.S1DarkBlank(badblank)=nan;

            % Replace missing with the next SAMPLE in time (NOT emission neighbor)
            % But we need to prevent picking a neighbor with a
            % different integration time
            itimes=unique(dataout.integrationtime);
            for j=1:numel(itimes)
                %Samples
                spec=dataout.S1DarkSample(dataout.integrationtime==itimes(j),:);
                spec=fillmissing(spec,"nearest",1);

                % If any are missing, fill with the nearest non-missing pixel
                % (instead of sample)
                if any(ismissing(spec(:)))
                    spec=fillmissing(spec,"nearest",2);
                end
                if any(ismissing(spec))
                    error("Urban, go take a look!!!")
                end
                dataout.S1DarkSample(dataout.integrationtime==itimes(j),:)=spec;
                %Blanks
                spec=dataout.S1DarkBlank(dataout.integrationtime==itimes(j),:);
                spec=fillmissing(spec,"nearest",1);
                % If any are missing, fill with the nearest non-missing pixel
                % (instead of sample)
                if any(ismissing(spec(:)))
                    spec=fillmissing(spec,"nearest",2);
                end
                if any(ismissing(spec))
                    error("Urban, go take a look!!!")
                end
                dataout.S1DarkBlank(dataout.integrationtime==itimes(j),:)=spec;
            end

            if options.plot


                ax=nexttile(t);
                h1=plot(ax,dataout.Em,dataout.S1DarkSample,'k',DisplayName='after samples');
                hold(ax,'on')
                h2=plot(ax,dataout.Em,dataout.S1DarkBlank,'r',DisplayName='after blanks');
                legend([h1(1) h2(1)])
                title(ax,'Dark spectra (after fixing)')
            end


        end


        function dataout = autofixR1Dark(data,options)
            arguments
                data (1,1) {mustBeA(data,'horibaRawdata')}
                options.thresholdFactor (1,1) {mustBeNumeric(options.thresholdFactor)} = 2
                options.plot (1,1) {mustBeA(options.plot,'logical')} = true
            end
            dataout=data;

            allR=[dataout.R1DarkSample;dataout.R1DarkBlank];
            med=median(allR);
            out=allR>(options.thresholdFactor*med);

            if not(any(out))
                return
            end
            if options.plot
                if drEEMtoolbox.options.uifig
                    f=drEEMtoolbox.dreemuifig;
                else
                    f=drEEMtoolbox.dreemfig;
                end
                f.Name='horibaRawdata.autofixS1DarkSpectra';
                t=tiledlayout(f,"flow",TileSpacing="compact");
                ax=nexttile(t);

                plot(ax,allR,'DisplayName','R1Dark (samples + blanks)')
                yline(ax,med,'DisplayName','Median R1Dark')
                yline(ax,options.thresholdFactor*med,'DisplayName','Threshold value')
                legend(ax)
                xlabel(ax,'Sample (1/2 samples + 1/2 blanks)')
                ylabel(ax,'R1Dark')
                title(ax,'R1Dark values before replacements')
            end

            allR(out)=nan;
            allR=fillmissing(allR,"nearest");
            if options.plot
                hold(ax,'on')
                plot(ax,find(out),allR(out),'rx',DisplayName='replacements')
                set(ax,YScale='log')
            end

            dataout.R1DarkSample=allR(1:dataout.nSample);
            dataout.R1DarkBlank=allR(dataout.nSample+1:end);

            st = dbstack;
            fullName = st(1).name;
            idx=height(dataout.history)+1;
            dataout.history(idx,1)=...
                drEEMhistory.addEntry(fullName, ...
                'Found noisy R1Dark measurements and replaced them with valid neighboring samples', ...
                [],drEEMdataset.create);

        end
    end
end