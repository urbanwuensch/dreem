function dataout=subdataset(data,options)
% <a href = "matlab:drEEMtoolbox.doc('subdataset')">dataout=subdataset(data,options) (click to access documentation)</a>
%
% <strong>Delete samples or parts of EEMs</strong> from a drEEMdataset
%
% <strong>INPUTS - Required</strong>
% data (1,1) {mustBeA("drEEMdataset"),drEEMdataset.validate}
% 
% <strong>Inputs - Optional</strong>
% options.outSample (1,:)   {mustBeNumericOrLogical} = false
% options.outEm (1,:)       {mustBeA('logical')} = false
% options.outEx (1,:)       {mustBeA('logical')} = false
%
% <strong>EXAMPLE(S)</strong>
%   1. Delete sample based on name
%       samples = tbx.subdataset(samples,outSample=matches(samples.filelist,'LCEP23 (01)'));
%   2. Delete sample based identifier
%       samples = tbx.subdataset(samples,outSample=samples.i==2);
%   3. Delete emission ranges
%       samples = tbx.subdataset(samples,outEm=samples.Em<300|samples.Em>700);
%   4. Delete excitation ranges
%       samples = tbx.subdataset(samples,outEx=samples.Ex<240|samples.Ex>450);
%   5. Delete specific excitation
%       samples = tbx.subdataset(samples,outEx=samples.Ex==275);
%   6. drEEM ships with a <strong>nearest neighbor function</strong>: isNearest, use it if wavelengths have many decimals
%       samples = tbx.subdataset(samples,outEm=tbx.isNearest(samples.Em,349));
%   7. Delete every other emission wavelength
%       samples = tbx.subdataset(samples,outEm=ismember(samples.Em,samples.Em(1:2:end))) 
% <a href = "matlab:drEEMtoolbox.doc('subdataset')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
    options.outSample (1,:) {mustBeA(options.outSample,'logical'),outSampleVal(data,options.outSample)} = false
    options.outEm (1,:) {mustBeA(options.outEm,'logical'),outEmVal(data,options.outEm)} = false
    options.outEx (1,:) {mustBeA(options.outEx,'logical'),outExVal(data,options.outEx)} = false
end
% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    nargoutchk(1,1)
end
outSample=options.outSample;
outEm=options.outEm;
outEx=options.outEx;

% Find first unscaled dataset and subset it as well (otherwise, errors occur
% during scaling reversion)
idx=drEEMhistory.searchhistory(data.history,'scalesamples','first');
if not(isempty(idx))
    previouseem=data.history(idx).previous;
    previouseem=drEEMtoolbox.subdataset(previouseem,...
        outSample=outSample,outEm=outEm,outEx=outEx);
    data.history(idx).previous=previouseem;
end

% Assign output variable
dataout=data;
if not(isempty(dataout.split))
    splitChange=true;
else
    splitChange=false;
end
% Carry out the subsetting. We subset with separate methods in the three
% dimensions with class-specific methods to make it clear what happened.

% NOTE: Any call to one of these functions will delete all existing models.
% They will not be subset (one could do that) because the dataset behind the fit has changed
% and the model is no longer representing the dataset.

if any(outSample)
    dataout=drEEMdataset.rmsamples(dataout,outSample);
    if not(isempty(dataout.split))
        for j=1:numel(dataout.split)
            s_outSample=ismember(dataout.split(j).i,data.i(outSample));
            dataout.split(j)=drEEMdataset.rmsamples(dataout.split(j),s_outSample);
        end
    end
end
if any(outEm)
    dataout=drEEMdataset.rmemission(dataout,outEm);
    if not(isempty(dataout.split))
        for j=1:numel(dataout.split)
            dataout.split(j)=drEEMdataset.rmemission(dataout.split(j),outEm);
        end
    end
end
if any(outEx)
    dataout=drEEMdataset.rmexcitation(dataout,outEx);
    if not(isempty(dataout.split))
        for j=1:numel(dataout.split)
            dataout.split(j)=drEEMdataset.rmexcitation(dataout.split(j),outEx);
        end
    end
end

% Validate the end result to make sure things are good to go.
dataout.validate(dataout);
if splitChange
    % disp('subdataset operation was also applied to split datasets!')
end
% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',inputname(1), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
end

end

function outSampleVal(data,outSample)
if isscalar(outSample)&&not(outSample)
    return
end
if not(size(outSample,2)==data.nSample)
    message=['<strong>outSample must be specified as logical array of the size [', ...
        num2str(data.nSample),' x 1].</strong> Why? ' ...
        'subdataset works with results of comparisons. E.g. ' ...
        'outSample=matches(data.filelist,''sample01''), ' ...
        'outSample=contains(data.metadata.location,''siteA''), ' ...
        'or outSample=data.i==1. '];
    throwAsCaller(MException("drEEM:invalid",message))
end
end

function outEmVal(data,outEm)
if isscalar(outEm)&&not(outEm)
    return
end
if not(size(outEm,2)==data.nEm)
    message=['<strong>outEm must be specified as logical array of the size [', ...
        num2str(data.nEm),' x 1].</strong> Why? ' ...
        'subdataset works with results of comparisons. E.g. ' ...
        'outEm=data.Em<300, ' ...
        'outEm=data.Em<300|data.Em>700, ' ...
        'or outEm=tbx.isNearest(data.Em,350). '];
    throwAsCaller(MException("drEEM:invalid",message))
end
end

function outExVal(data,outEx)
if isscalar(outEx)&&not(outEx)
    return
end
if not(size(outEx,2)==data.nEx)
    message=['<strong>outEx must be specified as logical array of the size [', ...
        num2str(data.nEx),' x 1].</strong> Why? ' ...
        'subdataset works with results of comparisons. E.g. ' ...
        'outEx=data.Ex<240, ' ...
        'outEx=data.Ex<240|data.Ex>450, ' ...
        'or outEx=tbx.isNearest(data.Ex,255). '];
    throwAsCaller(MException("drEEM:invalid",message))
end
end