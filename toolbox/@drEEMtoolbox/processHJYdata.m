function [DS,DSb] = processHJYdata(Xin,opt)
% This function is part of undocumented drEEM and not intended for general use

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
if strcmp(Xin,'options')
    opt=defaultopts;
    if strcmp(Xin,'options')
        DS=opt;
        return
    end
end

if isstruct(Xin)&&nargin==1
    opt=defaultopts;
    disp(' ')
    warning(sprintf(['No options were provided, the defaults were assumed.\n'...
        '     Please inspect the result and see if adjustments are necessary.\n'...
        '     Options can be obtained by calling ''processHJYdata(''options'')'''])) %#ok<SPWRN>
    disp(' ')
end


DS=drEEMdataset.create;
DS.Ex=(Xin.Ex);
DS.Em=Xin.Em;
DS.nEx=numel(DS.Ex);
DS.nEm=numel(DS.Em);
DS.nSample=size(Xin.S1Blank,1);
DS.i=(1:DS.nSample)';
DS.X=nan(DS.nSample,DS.nEm,DS.nEx);
DS.absWave=Xin.Abs_wave;


flds=fieldnames(Xin);
flds(contains(flds,{'AbsI1Sample','AbsI1darkSample','Abs_horiba','AbsI1darkBlank','AbsR1darkBlank','AbsR1darkSample','AbsI1Blank','S1Blank','S1DarkBlank','MCorrect','R1Blank', ...
'R1DarkBlank','XCorrect','S1Sample','S1DarkSample','R1Sample', ...
'R1DarkSample'}))=[];
fldsnew=flds;
fldsnew=replace(fldsnew,'Abs_wave','absWave');

for j=1:numel(flds)
    if size(Xin.(flds{j}),1)==DS.nEm||size(Xin.(flds{j}),1)==DS.nEx
        DS.(fldsnew{j})=Xin.(flds{j});
    end
end

DS.filelist=Xin.filelist;
for j=1:numel(flds)
    if size(Xin.(flds{j}),1)==DS.nSample
        DS.metadata.(flds{j})=Xin.(flds{j});
    end
end

% if opt.blanksubtract
%     DS.blankSubtraction="applied by instrument software";
% else
%     DS.blankSubtraction="applied by instrument software";
% end

% Xin=ccdpixeltagger(Xin);
% DS.pixelvariance=Xin.pixelvariance;
% DS.pixeltagged=Xin.pixeltagged;
if opt.doublebinning
    temp=doublebinning(Xin);
    
    

    Xin=temp;
    DS.Em=Xin.Em;
    DS.nEm=numel(DS.Em);
    DS.X=nan(DS.nSample,DS.nEm,DS.nEx);
    DS.pixelvariance=Xin.pixelvariance;
    DS.pixeltagged=Xin.pixeltagged;
end


Xblank=nan(DS.nSample,DS.nEm,DS.nEx);
if opt.visualize
    fig=drEEMtoolbox.dreemfig;
end
for j=1:DS.nSample
    
    % Fluorescence
    S1_s=squeeze(Xin.S1Sample(j,:,:));
    S1_b=squeeze(Xin.S1Blank(j,:,:));
    if opt.nanoversat
        nanmat=(S1_s>65000)|(S1_b>65000);
    else
        nanmat=false(size(S1_s));
    end
    
    S1dark_s=repmat(Xin.S1DarkSample(j,:),DS.nEx,1)';
    S1dark_b=repmat(Xin.S1DarkBlank(j,:),DS.nEx,1)';
    
    S1c_s=(S1_s-S1dark_s).*repmat(Xin.MCorrect(j,:)',1,numel(Xin.Ex));
    S1c_b=(S1_b-S1dark_b).*repmat(Xin.MCorrect(j,:)',1,numel(Xin.Ex));
    
    R1_s=Xin.R1Sample(j,:);
    R1_b=Xin.R1Blank(j,:);
    
    R1dark_s=Xin.R1DarkSample(j);
    R1dark_b=Xin.R1DarkBlank(j);

    R1c_s=(R1_s-R1dark_s).*Xin.XCorrect(j,:);
    R1c_b=(R1_b-R1dark_b).*Xin.XCorrect(j,:);
    
    S1c_R1c_s=S1c_s./repmat(R1c_s,numel(Xin.Em),1);
    S1c_R1c_b=S1c_b./repmat(R1c_b,numel(Xin.Em),1);
        
    Xblank(j,:,:)=S1c_R1c_b;
    

    S1c_R1c_s(nanmat)=nan;

    DS.X(j,:,:)=S1c_R1c_s;
    DS.metadata.R1integral(j,1)=sum(R1c_s);
    DS.metadata.R1_350(j,1)=R1c_s(drEEMtoolbox.mindist(DS.Ex,350));

    % Absorbance
    I1_s=Xin.AbsI1Sample(j,:);
    
    I1dark_s=Xin.AbsI1darkSample(j,1);
    I1dark_b=Xin.AbsI1darkBlank(j,1);
    I1_b=Xin.AbsI1Blank(j,:);
    
    I1c_s=(I1_s-I1dark_s).*Xin.AbsXCorrect(j,:);
    I1c_b=(I1_b-I1dark_b).*Xin.AbsXCorrect(j,:);
    
    R1_s=Xin.AbsR1Sample(j,:);
    R1_b=Xin.AbsR1Blank(j,:);
    
    R1dark_s=Xin.AbsR1darkSample(j);
    R1dark_b=Xin.AbsR1darkBlank(j);

    R1c_s=(R1_s-R1dark_s).*Xin.AbsXCorrect(j,:);
    R1c_b=(R1_b-R1dark_b).*Xin.AbsXCorrect(j,:);

    I1c_R1c_s=I1c_s./R1c_s;
    I1c_R1c_b=I1c_b./R1c_b;

    abso=-log10(I1c_R1c_s./I1c_R1c_b);
    DS.abs(j,:)=abso;

    if opt.visualize
        
        
        imin=[drEEMtoolbox.mindist(DS.Em,260) drEEMtoolbox.mindist(DS.Ex,400)];
        
        t=tiledlayout('flow');
        
        nexttile
        eemcontour(DS.Ex,DS.Em,S1_s)
        clim(eemlims(DS.Ex,DS.Em,S1_s))
        zlim(eemlims(DS.Ex,DS.Em,S1_s))
        title('S1 Sample')
        
        nexttile
        eemcontour(DS.Ex,DS.Em,S1_b)
        clim(eemlims(DS.Ex,DS.Em,S1_b))
        zlim(eemlims(DS.Ex,DS.Em,S1_b))
        title('S1 Blank')
        
        nexttile
        plot(S1dark_s(:,1),DS.Em,'DisplayName','Sample')
        hold on
        plot(S1dark_b(:,1),DS.Em,'DisplayName','Blank')
        title('S1 Dark'),legend
        
        
        nexttile
        plot(DS.Ex,R1c_s,'DisplayName','Sample')
        hold on
        plot(DS.Ex,R1c_b,'DisplayName','Blank')
        title('R1 Dark (corrected)'),legend
        
        nexttile
        eemcontour(DS.Ex,DS.Em,S1c_s)
        try
        clim(eemlims(DS.Ex,DS.Em,S1c_s))
        zlim(eemlims(DS.Ex,DS.Em,S1c_s))
        end
        title('S1c Sample')
        
        nexttile
        eemcontour(DS.Ex,DS.Em,S1c_b)
        try
        clim(eemlims(DS.Ex,DS.Em,S1c_b))
        zlim(eemlims(DS.Ex,DS.Em,S1c_b))
        end
        title('S1c Blank')
        
        
        
        nexttile
        eemcontour(DS.Ex,DS.Em,S1c_R1c_s)
        try
        clim(eemlims(DS.Ex,DS.Em,S1c_R1c_s))
        zlim(eemlims(DS.Ex,DS.Em,S1c_R1c_s))
        end
        title('S1c/R1c Sample')
        
        nexttile
        eemcontour(DS.Ex,DS.Em,S1c_R1c_b)
        try
        clim(eemlims(DS.Ex,DS.Em,S1c_R1c_b))
        zlim(eemlims(DS.Ex,DS.Em,S1c_R1c_b))
        end
        title('S1c/R1c Blank')
        
        nexttile
        m=S1c_R1c_s-S1c_R1c_b;
        eemcontour(DS.Ex,DS.Em,m)
        try
        clim(eemlims(DS.Ex,DS.Em,m))
        zlim(eemlims(DS.Ex,DS.Em,m))
        end
        title('S1c/R1c Sample-Blank')
        colormap(turbo)
        
        
        colormap(turbo)        
        title(t,[num2str(j),': ',DS.filelist{j}])
        pause
    end
end
DSb=DS;
DSb.X=Xblank;

idx=1;
DS.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'created dataset',[],DS);


idx=1;
DSb.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'created dataset',[],DSb);

stat=drEEMstatus;
stat=drEEMstatus.change(stat,"spectralCorrection","applied by instrument software");
stat=drEEMstatus.change(stat,"IFEcorrection","not applied");
stat=drEEMstatus.change(stat,"blankSubtraction","not applied");
stat=drEEMstatus.change(stat,"signalCalibration","not applied");
stat=drEEMstatus.change(stat,"scatterTreatment","not applied");
stat=drEEMstatus.change(stat,"signalScaling","not applied");
stat=drEEMstatus.change(stat,"absorbanceUnit","absorbance per cm");

DS.status=stat;
DSb.status=stat;
end
% %% Blank modification
% [~,ia,ic] = unique(Xin.S1DarkBlank,'rows','stable');
% xc=drEEMdataset.create;
% xc.Ex=DS.Ex;
% xc.Em=DS.Em;
% xc.nEx=numel(xc.Ex);
% xc.nEm=numel(xc.Em);
% xc.X=Xblank(ia,:,:);
% xc.nSample=size(xc.X,1);
% xc.i=(1:xc.nSample)';
% xc.filelist=DS.filelist(ia);
% xc.metadata.i=xc.i;
% 
% opti=handlescatter('options');
% opti.interpolate=[0 0 0 0];
% opti.ray1 = [60 30];
% opti.ram1 = [25 25];
% opti.ray2 = [30 30];
% opti.ram2 = [15 15];
% opti.d2zero = 500;
% opti.plot = 'off';
% opti.cutout = [1 1 1 1];
% opti.samples=xc.i;
% opti.negativetozero='off';
% 
% xcut=handlescatter(xc,opti);
% idx=repmat(not(all(isnan(xcut.X))),xc.nSample,1);
% xcutmed=repmat(median(xcut.X),xc.nSample,1);
% 
% xc.X(idx)=xcutmed(idx);
% 
% Xblank_mod=xc.X(ic,:,:);
% 
% if opt.blanksubtract
%     [~,~,DS.metadata.blanknumber] = unique(Xin.S1DarkBlank,'rows','stable');
%     if opt.blankmedian
%         DS.X=DS.X-Xblank_mod;
%     else
%         DS.X=DS.X-Xblank;
%     end
% else
% 
% end
% 
% 
% 
% 
% %% RAMAN CALIBRATION
% tens2mat=@(x,sz1,sz2,sz3) reshape(x,size(x,1),size(x,2)*size(x,3));
% if opt.ramannormalize
%     % Identify blanks based on their (hopefully) unique S1Blank-S1DarkBlank scans
%     % I think this is highly likely since it involves two measurements with
%     % random noise being subtracted from one another. This should be quite safe
% 
%     [~,ia,ic] = unique(tens2mat(Xin.S1Blank-Xin.S1DarkBlank),'rows','stable');
% 
%     % ic is the common index
%     % ia is the first mention of the unique sample
% 
%     % Extract the first mention of the unique blanks (save time)
%     Bls=Xblank(ia,:,:);
%     R1bs=Xin.R1Blank(ia,:);
%     if not(isfield(Xin,'RamNorm'))
%         %disp('Did not find existing Raman Normalization scans. Calculating...')
%         % Initialize
%         options.Exwave=350;
%         ramanwave=options.Exwave;
% 
% 
%         % Extract scans (either direct or through interpolation)
% 
%         if ismember(ramanwave,DS.Ex)
%             disp(['Raman normalization wavelength (',num2str(ramanwave),') found in EEM data.'])
%             Exraman=DS.Ex;
%             Rmat=Bls;
%         else
%             disp(['Raman normalization wavelength (',num2str(ramanwave),') not found in EEM data. Interpolating...'])
%             for n=1:size(Bls,1)
%                 mat=squeeze(Bls(n,:,:));
%                 Exraman=(DS.Ex(1):DS.Ex(end))';
%                 Rmat(n,:,:)=interp2(DS.Ex,DS.Em',mat,Exraman,DS.Em');
%             end
%         end    
% 
%         idx=Exraman==ramanwave;
%         Rscan=squeeze(Rmat(:,:,idx));
%         R1bs=R1bs(:,idx);
% 
% 
%         % Execute the calibration
%         % [IR IRmed IRdiff] = ramanintegrationrange([DS.Em';Rscan],(1:DS.nSample)',ramanwave,[],6,[],[]); %check the integration range
%         RamanIntRange= [378,424]; % This is only for 350nm
%         [RA,BaseArea]=RamanAreaI([rcvec(DS.Em,'row');Rscan],RamanIntRange(1),RamanIntRange(2));
%         bp=BaseArea./RA.*100;
%         RAbackup=RA;
%         RA=RA-BaseArea;
% 
%         if any(isnan(RA))
%             error('Some Raman areas are NaN. Inspect raw data for issues before continuing')
%         end
% 
%         % Use the common indicies to replicate the unique scans as they
%         % occured in the original dataset.
%         Rscan=Rscan(ic,:);
%         RA=RA(ic,:);
%         R1bs=R1bs(ic);
% 
%         DS.RamNorm.wave=ramanwave;
%         DS.RamNorm.Em=DS.Em;
%         DS.RamNorm.intRange=RamanIntRange;
%         DS.RamNorm.area=RA;
%         DS.RamNorm.scan=Rscan;
%         DS.RamNorm.RAplusBaseline=RAbackup(ic,:);
%         %DS.RamNorm.Baseline=BaseArea(ic,:);
%         DS.RamNorm.BaselinePercent=bp(ic,:);
%         DS.RamNorm.R1read=R1bs;
%         DS.RamNorm.comment=...
%             ['wave: Ex-wave at which the Raman area was extracted,' ...
%             ' IntRange: Emission integration range,' ...
%             ' area: Raman area (multiply X with these numbers to reverse calibration),' ...
%             'Baseline subtracted'];
% 
%     else
%         disp('Found existing Raman Normalization scans. Applying...')
%         DS.RamNorm=Xin.RamNorm;
%     end
% 
%     DS.X=DS.X./DS.RamNorm.area;
%     DS.Xunit='Raman Units (R.U.)';
% end
% 
% 
% 
% end


% function [vout] = rcvec(v,rc)
% Make row or column vector
% v: vector
% rc: either 'row' ([1:5])or 'column' ([1:5]')
% sz=size(v);
% if ~any(sz==1)
%     error('Input is not a vector')
% end
% 
% switch rc
%     case 'row'
%         if ~(sz(1)<sz(2))
%             vout=v';
%         else
%             vout=v;
%         end
%     case 'column'
%         if ~(sz(1)>sz(2))
%             vout=v';
%         else
%             vout=v;
%         end
%     otherwise
%             error('Input ''rc'' not recognized. Options are: ''row'' and ''column''.')
% end
% 
% end

% function [Y,BaseArea]=RamanAreaI(M,EmMin,EmMax)
% % [Y,EmMin,EmMax]=RamanAreaI(M,EmMin,EmMax)
% % Find the area under the curves in M between wavelengths EmMin and EmMax, 
% % data are interpolated to 0.5 nm intervals
% 
% %interpolate to 0.5 nm intervals
% waveint=0.5; %nm
% waves=(EmMin:waveint:EmMax)';
% Mpt5 = FastLinearInterp(M(1,:)', M(2:end,:)', waves)'; %faster linear interp
% %figure, plot(Mpt5)
% %Mpt5 = interp1(M(1,:)', M(2:end,:)', waves,'spline')'; %built in alternative
% 
% %integrate
% RAsum=trapz(waves,Mpt5,2);
% % BaseArea=trapz([waves(1) waves(end)]',[Mpt5(:,1) Mpt5(:,end)]')';
% BaseArea=(EmMax-EmMin)*(Mpt5(:,1)+0.5*(Mpt5(:,end)-Mpt5(:,1)));
% 
% % RAsumfit=trapz(waves,feval(fit(waves,Mpt5',"gauss1"),waves));
% 
% % Old formula from Kate, equal to trapezoidal integration
% % BaseArea=(EmMax-EmMin)*(Mpt5(:,1)+0.5*(Mpt5(:,end)-Mpt5(:,1)));
% 
% 
% % plot(waves,Mpt5),hold on,plot([waves(1) waves(end)],[Mpt5(1) Mpt5(end)])
% % plot(waves,feval(fit(waves,Mpt5',"gauss1"),waves))
% 
% 
% %RAsum=trapz(waves,Mpt5,2)*waveint;%;
% %BaseArea=(EmMax-EmMin)*(Mpt5(:,1)+0.5*(Mpt5(:,end)-Mpt5(:,1)))*waveint;
% % disp([RAsum BaseArea BaseArea./RAsum]);
% Y = RAsum;% - BaseArea;
% end
% 
% function Yi = FastLinearInterp(X, Y, Xi)
% %by Jan Simon
% % X and Xi are column vectros, Y a matrix with data along the columns
% [dummy, Bin] = histc(Xi, X);  %#ok<HISTC,ASGLU>
% H            = diff(X);       % Original step size
% % Extra treatment if last element is on the boundary:
% sizeY = size(Y);
% if Bin(length(Bin)) >= sizeY(1)
%     Bin(length(Bin)) = sizeY(1) - 1;
% end
% Xj = Bin + (Xi - X(Bin)) ./ H(Bin);
% % Yi = ScaleTime(Y, Xj);  % FASTER MEX CALL HERE
% % return;
% % Interpolation parameters:
% Sj = Xj - floor(Xj);
% Xj = floor(Xj);
% % Shift frames on boundary:
% edge     = (Xj == sizeY(1));
% Xj(edge) = Xj(edge) - 1;
% Sj(edge) = 1;           % Was: Sj(d) + 1;
% % Now interpolate:
% if sizeY(2) > 1
%     Sj = Sj(:, ones(1, sizeY(2)));  % Expand Sj
% end
% Yi = Y(Xj, :) .* (1 - Sj) + Y(Xj + 1, :) .* Sj;
% end


function opt = defaultopts
opt.blanksubtract=false;
opt.blankmedian=false;
opt.visualize=false;
opt.doublebinning=false;
opt.ramannormalize=false;
opt.nanoversat=true;
end


function eemcontour(x,y,mat)
        sc = surfc(x,y,mat,'EdgeColor','none');
        view(0,90)
        sc(2).ZLocation = 'zmax';
        sc(2).LineColor='k';
        sc(2).LineWidth = 0.5;
        sc(2).LevelList=linspace(min(mat(~isnan(mat))),max(mat(~isnan(mat))),15);
        zlim([min(mat(~isnan(mat))),max(mat(~isnan(mat)))])

        CLim=[min(mat(~isnan(mat))) max(mat(~isnan(mat)))];
        clim(CLim)
end

function vals=eemlims(ex,em,eem)
mindist=@(vec,val) find(ismember(abs(vec-val),min(abs(vec-val))));

exfind=[240 260 275 320 360];
emfind=[310 350 280 420 450];
val=nan(numel(exfind)*numel(emfind),1);
cnt=1;
for j=1:numel(exfind)
    for k=j:numel(emfind)
        val(cnt)=eem(mindist(em,emfind(k)),mindist(ex,exfind(j)));
        cnt=cnt+1;
    end
end

val(isnan(val))=[];
maxval=max(val);

minval=eem(mindist(em,260),mindist(ex,400));

if maxval<=minval
    minval=maxval-0.2*maxval;
end
vals=[minval-0.2*minval maxval+0.2*maxval];
end




function [dataout] = extractscatter(data)
% modified handlescatter to inversely tag scatter for blank subtraction
%
options.cutout=[1 1 1 1];         % Cut scatter?  [Ray1 Ram1 Ray2 Ram2]
options.ray1=[50 50 8];           % Rayleigh 1st: [below above narrowing]
options.ram1=[50 50 8];           % Raman 1st:    [below above narrowing]
options.ray2=[50 50 0];           % Rayleigh 2nd: [below above narrowing]
options.ram2=[30 30 0];           % Raman 2nd:    [below above narrowing]
%% Preparation of matricies that will determine treatment
% Missing-number matrix (will be used to NaN the EEMs)
nanmat=false(data.nEm,data.nEx);
types={'ray1';'ram1';'ray2';'ram2'};
for n=1:numel(types)
    nanmat = labeler(nanmat,data.Ex,data.Em,types{n},options.(types{n})(1),options.(types{n})(2),options.cutout(n),options.(types{n})(3));
end
clearvars types

%% Data treatment
X=data.X;  %X  -> raw data
Xc=X;      %Xc -> X (cut)
% (1) NaN the scatter diagonals
% Xempty=nan(data.nEm,data.nEx);
% Xempty(not(nanmat))=Xc(1,not(nanmat));
Xc(1,not(nanmat))=0;
% mesh(squeeze(Xc))

%% Output variable definition
dataout=data;
dataout.X=Xc;

end
%% Internal functions used above

%%
function nanout =labeler(nanin,x,y,type,below,above,cutswitch,nrrowrate)
nanout=nanin;
syncx=nan(numel(x),numel(y));
% switch-case for different types (d2zero immediately returns)

switch type
    case 'ray1'
        below = linspace(below,below-((x(end)-x(1))/50)*nrrowrate,numel(y));
        above = linspace(above,above-((x(end)-x(1))/50)*nrrowrate,numel(y));

        for n=1:numel(x)
            syncx(n,:) = y-x(n);
        end
    case 'ray2'
        below = linspace(below,below-((x(end)-x(1))/50)*nrrowrate,numel(y));
        above = linspace(above,above-((x(end)-x(1))/50)*nrrowrate,numel(y));

        for n=1:numel(x)
            syncx(n,:) = y-2*x(n);
        end
    case 'ram1'
        below = linspace(below,below-((x(end)-x(1))/50)*nrrowrate,numel(y));
        above = linspace(above,above-((x(end)-x(1))/50)*nrrowrate,numel(y));

        for n=1:numel(x)
            syncx(n,:)= y -(1e7*((1e7)/(x(n))-3382)^-1);
        end

    case 'ram2'
        below = linspace(below,below-((x(end)-x(1))/50)*nrrowrate,numel(y));
        above = linspace(above,above-((x(end)-x(1))/50)*nrrowrate,numel(y));

        for n=1:numel(x)
            syncx(n,:) = y - ((1e7*((1e7)/(x(n))-3382)^-1)*2);
        end
    case 'd2zero'
        for n=1:numel(x)
            syncx=y-x(n);
            nanout(syncx<=-below,n)=true;
        end
        return
    otherwise
        error('Input to ''type'' must be one of these: ray1 ray2 ram1 ram2 d2zero')
end

for n=1:numel(x)
    if cutswitch
        nanout(syncx(n,:)>=-below&syncx(n,:)<=above,n)=true;
    else
        nanout(syncx(n,:)>=-below&syncx(n,:)<=above,n)=false;
    end
end

end

function xout = doublebinning(x)
% Assign new wavelengths
cnt=1;
Em_new=nan(numel(1:2:numel(x.Em)),1);
for j = 1:2:numel(x.Em)
    Em_new(cnt,1) = (mean(x.Em(j:j+1)));
    cnt = cnt + 1;
end

% Interpolate Mcorrect
mcor_new=interp1(x.Em,unique(x.MCorrect,'rows'),Em_new,'linear');


% Modify the data
flds={'S1Blank','S1DarkBlank','S1Sample','S1DarkSample'};

xnew=struct;
xnew.S1Blank=zeros(size(x.S1DarkSample,1),numel(Em_new),numel(x.Ex));
xnew.S1Sample=zeros(size(x.S1DarkSample,1),numel(Em_new),numel(x.Ex));
xnew.S1DarkBlank=zeros(size(x.S1DarkSample,1),numel(Em_new));
xnew.S1DarkSample=zeros(size(x.S1DarkSample,1),numel(Em_new));

for j=1:size(x.S1DarkSample,1)
    for k=1:numel(flds)
        if ndims(x.(flds{k}))==3
            
            dat=x.(flds{k})(j,:,:);
            cnt=1;
            for l = 1:2:numel(x.Em)
                xnew.(flds{k})(j,cnt,:)=sum(dat(1,l:l+1,:),2)./2;
                cnt=cnt+1;
            end
        elseif ndims(x.(flds{k}))==2
            dat=x.(flds{k})(j,:);
            cnt=1;
            for l = 1:2:numel(x.Em)
                %xnew.(flds{k})(j,cnt)=sum(dat(1,l:l+1),2)./2;
                xnew.(flds{k})(j,cnt)=sqrt(sum(dat(1,l:l+1).^2.087,2))./2; 
                % ^2.087 was determined experimentally by checking that the blank scans center around zero
                % /2 is so the signals are not above 50000 by accident
                cnt=cnt+1;
            end
            %figure,plot(x.Em,dat),hold on,plot(Em_new,xnew.(flds{k})(j,:))
        end
    end
end

xold=x;


% Do some performance checks
darkratio=median(x.S1DarkSample(:),'omitnan')./median(xnew.S1DarkSample(:),'omitnan');
Sratio=median(x.S1Blank(:),'omitnan')./median(xnew.S1Blank(:),'omitnan');

if darkratio>1.01||darkratio<0.99
    error('Pixel binning introduced a significant difference in the level of S1DarkSample signals')
else
    %disp(['Ratio S1DarkSample before/S1DarkSample after ',num2str(darkratio)])
end
if Sratio>1.01||Sratio<0.99
    error('Pixel binning introduced a significant difference in S1Sample signal levels')
else
    %disp(['Ratio S1Sample before/S1Sample after         ',num2str(Sratio)])
end

for j=1:size(x.S1DarkSample,1)
    old=squeeze(xold.S1Sample(j,:,:))-repmat(xold.S1DarkSample(j,:)',1,size(xold.Ex,1));
    new=squeeze(xnew.S1Sample(j,:,:))-repmat(xnew.S1DarkSample(j,:)',1,size(xold.Ex,1));
    samplediff(j,:)=prctile(old(:),30)-prctile(new(:),30);

    old=squeeze(xold.S1Blank(j,:,:))-repmat(xold.S1DarkBlank(j,:)',1,size(xold.Ex,1));
    new=squeeze(xnew.S1Blank(j,:,:))-repmat(xnew.S1DarkBlank(j,:)',1,size(xold.Ex,1));

    blankdiff(j,:)=prctile(old(:),30)-prctile(new(:),30);
end

if abs(max(samplediff))>10
    error('Difference of >10 in binned sample fluorescence counts (samples)')
end
if abs(max(blankdiff))>10
    error('Difference of >10 in binned sample fluorescence counts (samples)')
end

% Overwrite old fields
xout=x;
xout.Em=Em_new;
for j=1:numel(flds)
    xout.(flds{j})=xnew.(flds{j});
end
xout.MCorrect=repmat(mcor_new',size(xout.S1DarkSample,1),1);
xout.Em_PixelBin=repmat(unique(xout.Em_PixelBin)*2,size(xout.S1DarkSample,1),1);


xout=ccdpixeltagger(xout);

end

function dataout = ccdpixeltagger(data)
dataout=data;
itimes=unique(data.integrationtime);
if numel(itimes)>1
    for j=1:numel(itimes)
        idx=data.integrationtime==itimes(j);
        if sum(idx)>1
            pixelvar_temp(j,:)=std(data.S1DarkSample(idx,:))./median(data.S1DarkSample(idx,:));
        else
            pixelvar_temp(j,:)=nan(1,size(data.S1DarkSample,2));
        end
    end
    pixelvar=mean(pixelvar_temp,'omitnan');
else
    pixelvar=std(data.S1DarkSample)./median(data.S1DarkSample);
end
dataout.pixeltagged=(pixelvar>0.01)';
dataout.pixelvariance=pixelvar';
end