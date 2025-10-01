function dataout = processabsorbance(data,options)
% <a href = "matlab:drEEMtoolbox.doc('processabsorbance')">dataout = processabsorbance(data,options) (click to access documentation)</a>
%
% <strong>Process CDOM absorbance measurements</strong>
%
% <strong>INPUTS - Required</strong>
% data (1,:) {mustBeA("drEEMdataset"),drEEMdataset.validate,drEEMdataset.sanityCheckAbsorbance}
%
% <strong>INPUTS - Optional</strong>
% correctBase           {mustBeNumericOrLogical} = true
% baseWave              {mustBeNumeric,mustBeGreaterThan(580),mustBeBetween(numel(baseWave),1,2)} = 595
% zero                  {mustBeNumericOrLogical} = false
% extrapolate           {mustBeNumericOrLogical} = true
% plot                  {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
%
% <strong>EXAMPLE(S)</strong>
%   1. correct CDOM baseline, extrapolate if EEM wavelength coverage is 
%   different from CDOM, and plot outcomes
%       samples = tbx.processabsorbance(samples);
%   3. Just carry out a baseline correction
%       samples = tbx.processabsorbance(samples,correctBase=true,extrapolate=false,zero=false);
%   4. Do something, but please don't show that final plot
%       samples = tbx.processabsorbance(samples,...,plot=false);
%
% <a href = "matlab:drEEMtoolbox.doc('processabsorbance')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    % Required
    data (1,:) {mustBeNonempty,mustBeA(data,"drEEMdataset"),...
        drEEMdataset.validate(data),drEEMdataset.sanityCheckAbsorbance(data),drEEMdataset.mustContainSamples(data)}

    % Optional
    options.correctBase (1,:)   {mustBeA(options.correctBase,'logical')} = true
    options.baseWave (1,:)      {mustBeNumeric,mustBeGreaterThan(options.baseWave,580),baseValidator(options.baseWave)} = 595
    options.zero (1,:)          {mustBeNumericOrLogical} = false
    options.extrapolate (1,:)   {mustBeNumericOrLogical} = true
    options.plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
end
mv=ver;
stool=any(contains({mv(:).Name},'Statistics and Machine Learning'));
if options.extrapolate&&not(stool)
    options.extrapolate=false;
    warning('Statistics and Machine Learning Toolbox not installed. CDOM spectra extrapolation disabled.')
end
% Check if the function has already been run
idx=drEEMhistory.searchhistory(data.history,'processabsorbance','first');
if not(isempty(idx))
    error(['"processabsorbance" has already been run before.' ...
        ' Please chose appropriate settings and only' ...
        ' run this function once to avoid ambiguity."'])
end

% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    if nargout>0
        nargoutchk(1,1)
    else
        disp('<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified).')
        options.plot=true;
    end
end

% If there are any strange imaginary numbers, fix it here by converting.
data.abs=real(data.abs);

% Assign the output variable
dataout=data;

% The function creates a result figure. The dataset setting determines if
% it's a uifigure (somewhat cleaner & simple) or figure (much faster)
if options.plot
    if data.toolboxOptions.uifig
        f=drEEMtoolbox.dreemuifig;
    else
        f=drEEMtoolbox.dreemfig;
    end
    f.Name='drEEM: processabsorbance.m';
    
    % Show the original data
    t=tiledlayout(f,"flow");
    ax=nexttile(t);
    plot(ax,data.absWave,data.abs,Color=[0 0 0 0.5])
    yline(ax,0,LineStyle="-",Color='b')
    xlabel(ax,'Wavelength (nm)')
    ylabel(ax,'Absorbance')
    title(ax,'Absorbance prior to any correction')
end
%% Scenario 1, no extrapolation needed
if max([dataout.Ex;dataout.Em])<max(dataout.absWave)
    %% Baseline correction (if possible and wanted)
    % It's only allowed if there's plenty of long-wl information though
    if max(dataout.absWave)>=580
        blcor_allowed=true;
    else
        warning('CDOM coverage does not allow baseline correction (needs to be > 580 nm). Option disabled.')
        blcor_allowed=false;
    end
    
    % Baseline possible, wanted, and no extrapolation necessary
    % Otherwise, the baseline subtraction is done later.
    if blcor_allowed&&options.correctBase
        i=dataout.absWave>=options.baseWave;
        if not(any(i))
            warning('Please double-check the baseline correction wavelength. Could not perform the baseline correction.')
        else
            bl=mean(dataout.abs(:,i),2,'omitmissing');
            dataout.abs=dataout.abs-bl;
        end
    end

%% Scenario 2: Stitch-on (extrapolation)
elseif max([dataout.Ex;dataout.Em])>max(dataout.absWave)
    disp('EEMs were measured at wavelengths longer than CDOM spectra.')
    % The extrapolation bit
    if options.extrapolate
        disp('Extrapolation of CDOM spectra will avoid the automatic deletion of EEM data during IFE correction.')
        abswave=dataout.absWave(drEEMtoolbox.mindist(dataout.absWave,300):end);
        absspec=dataout.abs(:,drEEMtoolbox.mindist(dataout.absWave,300):end)';

        % This bit sets options for a non-linear exponential CDOM spectra
        % fit and carries it out ( (c) Stedmon 2001)
        opts=statset;
        opts.MaxIter=2500;
        % Anonymous function to fit data to the model afteer parameters
        % were found
        afit=@(b1,b2,b3,lambda) b1*exp(b2/1000*(350-lambda))+b3;
        ewstep=round(mean(diff(dataout.absWave)));
        ex_start=dataout.absWave(end)+ewstep;
        options.extrapolation_start=ex_start;
        extrawave=(dataout.absWave(end)+ewstep:ewstep:ceil(max([dataout.Ex;dataout.Em])))';
        new=zeros(data.nSample,numel([abswave;extrawave]));
        beta=nan(data.nSample,3);
        % Carry out the non-linear fit to find the CDOM exponential slope
        % parameters
        warning off
        for n=1:size(absspec,2)
            try
                beta(n,:) = nlinfit(abswave,absspec(:,n),@CDOMexp_K,[mean(absspec(:,n)); 18; 0],opts);
                new(n,:)=afit(beta(n,1),beta(n,2),beta(n,3),[abswave;extrawave]);
            catch
                new(n,:)=0;
            end
        end
        warning on
        % if a350 is too small, set it to zero
        new(beta(:,2)<1,:)=0;
        new=new(:,size(abswave,1)+1:end);

        % find and eliminate offset between measured and modelled data
        off=data.abs(:,end)-new(:,1);
        new=new+off;
        
        % show intermediate results
        if options.plot
            ax=nexttile(t);
            plot(ax,data.absWave,data.abs,Color=[0 0 0 0.5])
            hold(ax,'on')
            plot(ax,extrawave,new,Color=[1 0 0 0.5])
            xlabel(ax,'Wavelength (nm)')
            ylabel(ax,'Absorbance')
            title(ax,'Given (black) and extrapl. data (red)')
            yline(ax,0,LineStyle="-",Color='b')
        end
        
        % Assign the extrapolated data to the output
        dataout.abs=horzcat(dataout.abs,new);
        dataout.absWave=vertcat(dataout.absWave,extrawave);
        
        % Now let's try the baseline correction again. Same code as above
        if max(extrawave)>580
            blcor_allowed=true;
        else
            blcor_allowed=false;
        end
        
        if blcor_allowed&&options.correctBase
            i=dataout.absWave>options.baseWave;
            bl=mean(dataout.abs(:,i),2,'omitnan');
            dataout.abs=dataout.abs-bl;
        end
        
    else
        %% Baseline correction (if possible and wanted)
        % It's only allowed if there's plenty of long-wl information though
        if max(dataout.absWave)>=580
            blcor_allowed=true;
        else
            warning('CDOM coverage does not allow baseline correction (needs to be > 580 nm). Option disabled.')
            blcor_allowed=false;
        end

        % Baseline possible, wanted, and no extrapolation necessary
        % Otherwise, the baseline subtraction is done later.
        if blcor_allowed&&options.correctBase
            if isscalar(options.baseWave)
                i = dataout.absWave>=options.baseWave;
            elseif numel(options.baseWave)==2
                i(1) =drEEMtoolbox.mindist(dataout.absWave,options.baseWave(1));
                i(2) = drEEMtoolbox.mindist(dataout.absWave,options.baseWave(2));
                i=i(1):i(2);
            end
            if not(any(i))
                warning('Please double-check the baseline correction wavelength. Could not perform the baseline correction.')
            else
                bl=mean(dataout.abs(:,i),2,'omitmissing');
                dataout.abs=dataout.abs-bl;
            end
        end
    end
end



%% <0 = 0 correction (if needed and wanted)
if any(dataout.abs(:)<0)&&options.zero
    dataout.abs(dataout.abs<0)=0;
end
% Show the final output
if options.plot
    ax=nexttile(t);
    plot(ax,dataout.absWave,dataout.abs,Color=[0 0 0 0.5])
    xlabel(ax,'Wavelength (nm)')
    ylabel(ax,'Absorbance')
    title(ax,'Final output')
    yline(ax,0,LineStyle="-",Color='b')
end

%% drEEMhistory entry
message=[...
    'baseWave = ',num2str(options.baseWave),...
    ', baseline offset corrected = ', char(string(options.correctBase)),...
    ', long-range absorbance extrapolated = ',char(string(options.extrapolate)),...
    ', zero negative values = ',char(string(options.zero))];
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,message,options,dataout);

if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',char(inputname(1)), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
else
    if nargout==0
        clearvars dataout
    end
end

end

function yhat = CDOMexp_K(beta,x)
%CDOM exponential abs model.
%   YHAT = CDOMexp(BETA,X) gives the predicted values of the
%   reaction rate, YHAT, as a function of the vector of 
%   parameters, BETA, and the matrix of data, X.
%   BETA must have ? elements and X must have three
%   columns.
%
%   y = a350*exp(S/1000*(350-lamda))+k
% (c) Colin Stedmon

b1 = beta(1); %a350
b2 = beta(2); %S
b3 = beta(3); %K

x = x(:,1); %lamda


yhat = b1*exp(b2/1000*(350-x))+b3;

end

function baseValidator(input)

nel=numel(input);

if nel<1|nel>2
    error('Input must be either be a scalar (e.g. 585) or a row vector of two elements (e.g. [585 600]')
end

end