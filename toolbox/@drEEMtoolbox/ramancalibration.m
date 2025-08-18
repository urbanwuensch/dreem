function dataout = ramancalibration(samples,blanks,options)
% <a href = "matlab:drEEMtoolbox.doc('ramancalibration')">dataout = ramancalibration(samples,blanks,options) (click to access documentation)</a>
%
% <strong>Calibrate fluorescence signals</strong> and convert from arbitrary to Raman Units
%
% <strong>INPUTS - Required</strong>
% samples (1,1) {mustBeA(,"drEEMdataset"),drEEMdataset.validate,...
%     drEEMdataset.sanityCheckSignalCalibration}
% blanks  (1,1) {mustBeA("drEEMdataset"),drEEMdataset.validate,...
%     drEEMdataset.sanityCheckSignalCalibration}
% 
% <strong>INPUTS - Optional</strong>
% ExWave (1,1) {mustBeNumeric} = 350
% iStart (1,1) {mustBeNumeric} = 378
% iEnd   (1,1) {mustBeNumeric} = 424
% plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
%
% <strong>EXAMPLE(S)</strong>
%   1. Trust us, but verify(!)
%       samples = tbx.ramancalibration(samples,blanks);
%   2. Trust us, and fly blind (only recommended if you have verified defaults!)
%       samples = tbx.ramancalibration(samples,blanks,plot=false);
%   3. Longer integration times, wider peak
%       samples = tbx.ramancalibration(samples,blanks,iStart=375,iEnd=430);
%   4. Different Raman peak (you decide start and end wavelength of peaks visually please)
%       samples = tbx.ramancalibration(samples,blanks,ExWave=275,iStart=...,iEnd=...);
%
% <a href = "matlab:drEEMtoolbox.doc('ramancalibration')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    % Required
    samples (1,1) {mustBeA(samples,"drEEMdataset"),drEEMdataset.validate(samples),...
        drEEMdataset.sanityCheckSignalCalibration(samples),drEEMdataset.mustContainSamples(samples)}
    blanks (1,1) {mustBeA(blanks,"drEEMdataset"),drEEMdataset.validate(blanks),...
        drEEMdataset.sanityCheckSignalCalibration(blanks),drEEMdataset.mustContainSamples(blanks)}

    % Optional (but important)
    options.ExWave (1,1) {mustBeNumeric} = 350
    options.iStart (1,1) {mustBeNumeric} = 378
    options.iEnd   (1,1) {mustBeNumeric} = 424
    options.doAlignmentcheck (1,1) {mustBeNumericOrLogical} = false
    options.plot (1,1) {mustBeNumericOrLogical} = samples.toolboxOptions.plotByDefault;
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
% assign output variable
dataout=samples;

%% Extract scans (either direct or through interpolation)
% if options.exWave is measured, extract, otherwise interpolate
Xblank=blanks.X;
if ismember(options.ExWave,blanks.Ex) % Simple extraction
    disp(['Raman normalization wavelength (',num2str(options.ExWave),') found in EEM data.'])
    Exraman=blanks.Ex;
    Rmat=Xblank;
else % first interpolate, then extract
    disp(['Raman normalization wavelength (',num2str(options.ExWave),') not found in EEM data. Interpolating...'])
    for n=1:size(Xblank,1)
        mat=squeeze(Xblank(n,:,:));
        Exraman=(blanks.Ex(1):blanks.Ex(end))';
        Rmat(n,:,:)=interp2(blanks.Ex,blanks.Em',mat,Exraman,blanks.Em');
    end
end    

% Find the index for extraction, then extract the 2D scans
idx=Exraman==options.ExWave;
Rscan=squeeze(Rmat(:,:,idx));



%% Execute the calibration
RamanIntRange= [options.iStart,options.iEnd]; % This is only for 350nm
[RA,BaseArea]=RamanAreaI([rcvec(blanks.Em,'row');Rscan],RamanIntRange(1),RamanIntRange(2));
% Raman area = Raman Peak area - baseline area (can be about 20% for
% AquaLogs at 1-8s integration time!)
RA=RA-BaseArea;

% This bit saves some info about the calibration for tracibility during
% export much later in the process.
SignalCalibration=struct;
SignalCalibration.ExWave=options.ExWave;
SignalCalibration.iStart=options.iStart;
SignalCalibration.iEnd=options.iEnd;
SignalCalibration.area=RA;
SignalCalibration.BaseArea=BaseArea;
SignalCalibration.BaseAreaPerc=BaseArea./RA*100;

% Attempt to extract SNB (signal-to-background ratio)
signal=max(Rscan(:,blanks.Em>options.iStart&blanks.Em<options.iEnd),[],2,"omitmissing");
background=median(Rscan(:,blanks.Em>options.iEnd&blanks.Em>options.iEnd+50),2,"omitmissing");

SignalCalibration.SNB=round(signal./background);
% Change dataset status
dataout.status=...
    drEEMstatus.change(dataout.status,"signalCalibration","applied by toolbox (RU)");

% Carry out signal calibration
dataout.X=dataout.X./RA;


% Carry out an alignment check based on Raman peaks (if desired)
if options.doAlignmentcheck
    warning('This is an undocumented, experimental feature. Don''t assume it will work.')
    dataout.toolboxOptions.alginmentcheck=alignmentcheck(blanks);
end

% drEEMhistory entry
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'Raman Units',SignalCalibration,dataout);

% validate the dataset (should not be a problem, but best be sure)
dataout.validate(dataout);
if options.plot
    % final plots
    if samples.toolboxOptions.uifig
        f=drEEMtoolbox.dreemuifig;
    else
        f=drEEMtoolbox.dreemfig;
    end
    f.Name='drEEM toolbox: Raman calibration overview';
    movegui(f,'center')
    t=tiledlayout(f,"flow");
    
    ax=nexttile(t);
    plot(ax,blanks.Em,Rscan,'k',LineWidth=1.5)
    title(ax,"Raman emission scans")
    ylabel(ax,'Signal intensity'),xlabel(ax,'Wavelength (nm)')
    
    xline(ax,options.iStart,'r',LineWidth=2)
    xline(ax,options.iEnd,'r',LineWidth=2)
    iData=Rscan(:,blanks.Em>options.iStart&blanks.Em<options.iEnd);
    iData=iData(:);
    ylim(ax,[0 max(iData)*2])
    xlim(ax,[options.iStart-20 options.iEnd+20])
    
    ax=nexttile(t);
    plot(ax,dataout.i,SignalCalibration.area,'ko')
    title(ax,'Raman area across dataset')
    xlabel(ax,"sample #")
    ylabel(ax,'Raman area')
    axis(ax,'padded')
    
    ax=nexttile(t);
    plot(ax,dataout.i,SignalCalibration.BaseAreaPerc,'ko')
    title(ax,'Baseline area rel. to Raman area across dataset')
    axis(ax,'padded')
    xlabel(ax,"sample #")
    ylabel(ax,' Baseline / Raman area * 100 (%)')
    
    ax=nexttile(t);
    plot(ax,dataout.i,SignalCalibration.SNB,'ko')
    title(ax,'Raman peak max / background signal (SNB)')
    ylabel(ax,'Signal to baseline ratio')
    xlabel(ax,"sample #")
end

% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',inputname(1), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
else
    if nargout==0
        clearvars dataout
    end
end


end

function [vout] = rcvec(v,rc)
% Make row or column vector
% v: vector
% rc: either 'row' ([1:5])or 'column' ([1:5]')
sz=size(v);
if ~any(sz==1)
    error('Input is not a vector')
end

switch rc
    case 'row'
        if ~(sz(1)<sz(2))
            vout=v';
        else
            vout=v;
        end
    case 'column'
        if ~(sz(1)>sz(2))
            vout=v';
        else
            vout=v;
        end
    otherwise
            error('Input ''rc'' not recognized. Options are: ''row'' and ''column''.')
end

end

function [Y,BaseArea]=RamanAreaI(M,EmMin,EmMax)
% [Y,EmMin,EmMax]=RamanAreaI(M,EmMin,EmMax)
% Find the area under the curves in M between wavelengths EmMin and EmMax, 
% data are interpolated to 0.5 nm intervals

%interpolate to 0.5 nm intervals
waveint=0.5; %nm
waves=(EmMin:waveint:EmMax)';
Mpt5 = FastLinearInterp(M(1,:)', M(2:end,:)', waves)'; %faster linear interp
%figure, plot(Mpt5)
%Mpt5 = interp1(M(1,:)', M(2:end,:)', waves,'spline')'; %built in alternative

%integrate
RAsum=trapz(waves,Mpt5,2);%;
BaseArea=(EmMax-EmMin)*(Mpt5(:,1)+0.5*(Mpt5(:,end)-Mpt5(:,1)));

%RAsum=trapz(waves,Mpt5,2)*waveint;%;
%BaseArea=(EmMax-EmMin)*(Mpt5(:,1)+0.5*(Mpt5(:,end)-Mpt5(:,1)))*waveint;
% disp([RAsum BaseArea BaseArea./RAsum]);
Y = RAsum;% - BaseArea;
end

function Yi = FastLinearInterp(X, Y, Xi)
%by Jan Simon
% X and Xi are column vectros, Y a matrix with data along the columns
[dummy, Bin] = histc(Xi, X);  %#ok<HISTC,ASGLU>
H            = diff(X);       % Original step size
% Extra treatment if last element is on the boundary:
sizeY = size(Y);
if Bin(length(Bin)) >= sizeY(1)
    Bin(length(Bin)) = sizeY(1) - 1;
end
Xj = Bin + (Xi - X(Bin)) ./ H(Bin);
% Yi = ScaleTime(Y, Xj);  % FASTER MEX CALL HERE
% return;
% Interpolation parameters:
Sj = Xj - floor(Xj);
Xj = floor(Xj);
% Shift frames on boundary:
edge     = (Xj == sizeY(1));
Xj(edge) = Xj(edge) - 1;
Sj(edge) = 1;           % Was: Sj(d) + 1;
% Now interpolate:
if sizeY(2) > 1
    Sj = Sj(:, ones(1, sizeY(2)));  % Expand Sj
end
Yi = Y(Xj, :) .* (1 - Sj) + Y(Xj + 1, :) .* Sj;
end


function results = alignmentcheck(data)


sign=@(x,y) minus(x,y);
for n=1:data.nEx
    em(n,:) = sign(data.Em,(1e7*((1e7)/(data.Ex(n))-3382)^-1));
end

minmax=[-12 12];
dem=rcvec(minmax(1):mean(diff(data.Em)):minmax(2),'column');
dem_i=dem(1):0.2:dem(end);

Xn=nan(data.nSample,numel(dem),data.nEx);
results=struct;
results.peakposition=nan(data.nSample,data.nEx);
results.Ex=data.Ex;
for n=1:data.nSample
    for i=1:data.nEx
        Xn=interp1(em(i,:),squeeze(data.X(n,:,i)),dem);
        f=fit(dem,Xn,'gauss1');
        Xn_f=feval(f,dem_i);
        results.peakposition(n,i)=dem_i(maxi(Xn_f));
    end
end



dataout=data;
dataout.Em=dem;
dataout.nEm=numel(dem);
% dataout.Xorg=data.X;
dataout.X=Xn;
% eemreview(dataout,'hold',true)

end

function [idx] = maxi(y)
[~,idx]=max(y);
end
