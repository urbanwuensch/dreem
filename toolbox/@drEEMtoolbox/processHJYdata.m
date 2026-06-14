function [DS,DSb] = processHJYdata(Xin,opt)
% This function is part of undocumented drEEM and not intended for general use

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)

arguments (Input)
    Xin  {Xinvalidator(Xin)}
    opt {mustBeA(opt,"struct")} = defaultopts
end


if strcmp(Xin,'options')
    opt=defaultopts;
    if strcmp(Xin,'options')
        DS=opt;
        return
    end
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

% Xin=ccdpixeltagger(Xin);
% DS.pixelvariance=Xin.pixelvariance;
% DS.pixeltagged=Xin.pixeltagged;
if opt.doublebinning
    temp=doublebinning(Xin);
    
    

    Xin=temp;
    DS.Em=Xin.Em;
    DS.nEm=numel(DS.Em);
    DS.X=nan(DS.nSample,DS.nEm,DS.nEx);
    % DS.pixelvariance=Xin.pixelvariance;
    % DS.pixeltagged=Xin.pixeltagged;
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
DSb.abs=[];
DSb.absWave=[];
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
stat=drEEMstatus.change(stat,"signalScaling","original scale");
stat=drEEMstatus.change(stat,"absorbanceUnit","absorbance per cm");

DS.status=stat;
DSb.status=stat;


DS = drEEMdataset.validate(DS,true);
DSb = drEEMdataset.validate(DSb,true);



end
%% Internal functions used above

function opt = defaultopts
opt.visualize=false;
opt.doublebinning=false;
opt.nanoversat=true;
disp(' ')
warning(sprintf(['No options were provided, the defaults were assumed.\n'...
    '     Please inspect the result and see if adjustments are necessary.\n'...
    '     Options can be obtained by calling ''processHJYdata(''options'')'''])) %#ok<SPWRN>
disp(' ')
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
    warning('Pixel binning introduced a significant difference in the level of S1DarkSample signals')
else
    %disp(['Ratio S1DarkSample before/S1DarkSample after ',num2str(darkratio)])
end
if Sratio>1.01||Sratio<0.99
    warning('Pixel binning introduced a significant difference in S1Sample signal levels')
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
    warning('Difference of >10 in binned sample fluorescence counts (samples)')
end
if abs(max(blankdiff))>10
    warning('Difference of >10 in binned sample fluorescence counts (samples)')
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

function Xinvalidator(Xin)

Xin_class = class(Xin);

pass=false;

if matches(Xin_class,'struct')||matches(Xin_class,'horibaRawdata')
    pass=true;
elseif ischar(Xin)
    if matches(Xin,'options')
        pass=true;
    end
elseif isstring(Xin)
    if matches(Xin,"options")
        pass=true;
    end
end


if not(pass)
    error('Xin must either be a structure (horibaRawdata) or ''options''')
end
end