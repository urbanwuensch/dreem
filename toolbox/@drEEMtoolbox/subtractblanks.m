function dataout = subtractblanks(samples,blanks,options)
% <a href = "matlab:drEEMtoolbox.doc('subtractblanks')">dataout = subtractblanks(samples,blanks) (click to access documentation)</a>
%
% <strong>Subtract blank dataset from sample dataset</strong>
%
% <strong>INPUTS - Required</strong>
% samples (1,1) {drEEMdataset.validate,...
%     drEEMdataset.sanityCheckBlankSubtraction}
% blanks (1,1)  {drEEMdataset.validate(blanks),...
%     drEEMdataset.sanityCheckBlankSubtraction}
%
% <strong> INPUTS - Optional</strong>
% plot (1,1) {mustBeNumericOrLogical} = samples.toolboxOptions.plotByDefault;
% figurefile (1,:) {mustBeText} = "";
%
% <strong>EXAMPLE(S)</strong>
%   1. Blank subtraction with visual output for inspection
%       samples = tbx.subtractblanks(samples,blanks)
%   2. Blank subtraction without visual output (not recommended)
%       samples = tbx.subtractblanks(samples,blanks,plot=false)
%
% <a href = "matlab:drEEMtoolbox.doc('subtractblanks')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    samples (1,1) {mustBeNonempty,drEEMdataset.validate(samples),...
        drEEMdataset.sanityCheckBlankSubtraction(samples),drEEMdataset.mustContainSamples(samples)}
    blanks (1,1) {mustBeNonempty,drEEMdataset.validate(blanks),...
        drEEMdataset.sanityCheckBlankSubtraction(blanks),drEEMdataset.mustContainSamples(blanks)}
    options.plot (1,1) {mustBeNumericOrLogical} = samples.toolboxOptions.plotByDefault;
    options.figurefile (1,:) {mustBeText} = "";
end

if nargout>0
    nargoutchk(1,1)
else
    disp('<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified).')
    options.plot=true;
end

% First off: Let's make sure the blank and sample datasets cover the same
% wavelengths. Differences can come easily duing the IFEcorrection method
% when some parts are deleted due to lacking CDOM coverage. This bit makes
% sure that the blank will also be cut to be compatible.

% Excitation comparisons
C=intersect(samples.Ex,blanks.Ex,"stable");
s_ex=setdiff(samples.Ex,C);
b_ex=setdiff(blanks.Ex,C);

% Emission comparisons
C=intersect(samples.Em,blanks.Em,"stable");
s_em=setdiff(samples.Em,C);
b_em=setdiff(blanks.Em,C);

% number of samples comparisons
if not(samples.nSample==blanks.nSample)
    error('Number of samples and blanks not equal. Use "alignsamples" prior to the execution of "subtractblanks" to avoid this issue.')
end
% subdataset call (will not do anything if wavelengths were identical)
samples_mod=drEEMtoolbox.subdataset(samples, ...
    outEm=ismember(samples.Em,s_em),outEx=ismember(samples.Ex,s_ex));
blanks_mod=drEEMtoolbox.subdataset(blanks, ...
    outEm=ismember(blanks.Em,b_em),outEx=ismember(blanks.Ex,b_ex));

% Next three lines are short but sometimes fail for no apparent reason and
% produce "no match" despite match.
% [C,is,ib] = intersect(samples_mod.filelist,blanks_mod.filelist);
% s_miss=setdiff(1:samples_mod.nSample,is);
% b_miss=setdiff(1:blanks_mod.nSample,ib);
cnt=1;
is=[];ib=[];s_miss=[];b_miss=[];
for j=1:samples_mod.nSample
    res=matches(samples_mod.filelist{j},blanks_mod.filelist{j});
    if res
        is(cnt)=cnt;
        ib(cnt)=cnt;
    else
        s_miss=cnt;
        b_miss=cnt;
    end
    cnt=cnt+1;
end

if not(isempty(b_miss))||not(isempty(s_miss))
    message=['Cannot go ahead since the filenames between both datasets don''t match.\n' ...
        'Troubleshooting information follows below:\n\n'];
    message=[message,'Number of samples: ',num2str(samples_mod.nSample),...
        ', number of blanks: ',num2str(blanks_mod.nSample),'\n\n'];
    
    if not(isempty(b_miss))
        message=[message,'\nThe following blanks have no corresponding sample:\n'];
        for j=1:numel(b_miss)
            message=[message,' | ',blanks_mod.filelist{b_miss(j)}];
        end
    end

    if not(isempty(s_miss))
        message=[message,'\nThe following samples have no corresponding blanks:\n'];
        for j=1:numel(s_miss)
            message=[message,' | ',samples_mod.filelist{s_miss(j)}];
        end
    end

    message=[message,'\n\nIt is recommended to use the "alignsamples" function prior to the execution of "subtractblanks" to avoid this issue.'];

    error(sprintf(message))
end

% Carry out the subtraction, but only if final dimension check was passed.
if all(size(samples_mod.X)==size(blanks_mod.X))
    dataout=samples_mod;
    dataout.status=...
        drEEMstatus.change(dataout.status,"blankSubtraction","applied by toolbox");

    dataout.X=samples_mod.X-blanks_mod.X;

    % Won't do anything with them, but the blanks will carry on existing in
    % the dataset because they will be exported.
    dataout.XBlank=blanks_mod.X;
    
    

else
    error('subtractblanks: Dimension missmatch. Cannot perform blank subtraction.')
end

% Finally let's make some plots to allow the user to see if blanks were
% clean and how well the subtraction worked for the elimitation of scatter.
if options.plot
    if samples.toolboxOptions.uifig
        f=drEEMtoolbox.dreemuifig;
    else
        f=drEEMtoolbox.dreemfig;
    end
    f.Name='drEEM: subtractblanks.m';
    t=tiledlayout(f,"flow",TileSpacing="compact");
    
    sam = inputname(1); % Show base workspace variable names in the plots
    bla = inputname(2); % Show base workspace variable names in the plots
    % Excitation 275 (for protein + humic fl).
    ex=samples.Ex(drEEMtoolbox.mindist(samples.Ex,275));
    ram1=1*10^7*((1*10^7)/(ex)-3382)^-1; % predicted raman 1st order
    ram2=(1*10^7*((1*10^7)/(ex)-3382)^-1)*2;  % predicted raman 2nd order
    ray1=ex;  % predicted rayleigh 1st order
    ray2=ex*2;  % predicted rayleigh 2nd order
    
    % Plot everything
    
    
    
    ax=nexttile(t);
    y = squeeze(blanks.X(:,:,drEEMtoolbox.mindist(blanks.Ex,275)));
    ysub = y(:,blanks.Em>340&blanks.Em<500);
    yl = min(y(:));
    yl(2) = max(ysub(:),[],1,"omitmissing").*3;
    plot(ax,blanks.Em,y)
    ylims=get(ax,"YLim");
    ylim(ax,yl)
    xline(ax,ray1,'Color','r')
    xline(ax,ray2,'Color','r')
    xline(ax,ram1,'Color','b')
    xline(ax,ram2,'Color','b')
    
    title(ax,[bla,' - emission scans @275nm'])
    xlabel(ax,'Emission (nm)')
    ylabel(ax,'Fluorescence intensity')
    
    ax = nexttile(t);
    tens2mat=@(x,sz1,sz2,sz3) reshape(x,sz1,sz2*sz3);
    y = tens2mat(blanks.X,blanks.nSample,blanks.nEm,blanks.nEx);
    mblank=reshape(max(y,[],1),blanks.nEm,blanks.nEx);
    signals(1)=mblank(drEEMtoolbox.mindist(blanks.Em,350),drEEMtoolbox.mindist(blanks.Ex,275));
    signals(2)=mblank(drEEMtoolbox.mindist(blanks.Em,450),drEEMtoolbox.mindist(blanks.Ex,250));
    signals(3)=mblank(drEEMtoolbox.mindist(blanks.Em,450),drEEMtoolbox.mindist(blanks.Ex,370));
    signals(4)=mblank(drEEMtoolbox.mindist(blanks.Em,500),drEEMtoolbox.mindist(blanks.Ex,450));
    ymax=max(signals(:),[],"omitmissing")*1;
    ymin=min(signals(:),[],"omitmissing")*1;
    levels=linspace(ymin,ymax,10);
    % contourf(ax,blanks.Ex,blanks.Em,mblank,100,LineStyle='none')
    % hold(ax,'on')
    % clim(ax,[ymin ymax])
    contour(ax,blanks.Ex,blanks.Em,mblank,LevelList=levels,Color='k')
    
    title(ax,[bla,' - max. int. countour EEM'])
    ylabel(ax,'Emission (nm)')
    xlabel(ax,'Excitaion (nm)')

    ax = nexttile(t);
    y = squeeze(samples.X(:,:,drEEMtoolbox.mindist(samples.Ex,275)));
    ysub = y(:,samples.Em>340&samples.Em<500);
    yl = max(ysub(:),[],1,"omitmissing").*1.5;
    plot(ax,samples.Em,y)
    ylims=get(ax,"YLim");
    ylim(ax,[ylims(1) yl])

    xline(ax,ray1,'Color','r')
    xline(ax,ray2,'Color','r')
    xline(ax,ram1,'Color','b')
    xline(ax,ram2,'Color','b')
    
    title(ax,[sam,' - emission scans @275nm'])
    xlabel(ax,'Emission (nm)')
    ylabel(ax,'Fluorescence intensity')

    ax=nexttile(t);
    y = squeeze(dataout.X(:,:,drEEMtoolbox.mindist(dataout.Ex,275)));
    ysub = y(:,dataout.Em>340&dataout.Em<500);
    plot(ax,dataout.Em,y)
    xline(ax,ray1,'Color','r')
    xline(ax,ray2,'Color','r')
    xline(ax,ram1,'Color','b')
    xline(ax,ram2,'Color','b')
    title(ax,{['[',sam,' - ',bla,'] - emission scans @275nm']})
    xlabel(ax,'Emission (nm)')
    ylabel(ax,'Fluorescence intensity')

    figurefile=char(options.figurefile);
    if not(isempty(figurefile))
        % Pause for figure rendering
        pause(3)
        try
            dreemgui.saveAfterFunctionCall(f,figurefile)
        catch ME
            throwAsCaller(ME)
        end
    end
end

% drEEMhistory entry
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'Blanks successfully subtracted',[],dataout);
dataout.validate(dataout);

if nargout==0
    clearvars dataout
end

end