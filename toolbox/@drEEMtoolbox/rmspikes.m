function dataout = rmspikes(data,options)
% <a href = "matlab:drEEMtoolbox.doc('rmspikes')">dataout = rmspikes(data,options) (click to access documentation)</a>
%
% <strong>Remove noisy data from fluorescence EEMs</strong>
%
% <strong>INPUTS - Required</strong>
% data (1,1) {drEEMdataset.validate}
% 
% <strong>INPUTS - Optional</strong>
% thresholdFactor (1,1) {mustBeNumeric} = 10
% interpolate (1,:) {mustBeNumericOrLogical} = false
% details (1,:) {mustBeNumericOrLogical} = false
% plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
%
% <strong>EXAMPLE(S)</strong>
%   1. Delete signals 10x above the noise floor and don't interpolate
%       samples = tbx.rmspikes(samples);
%   3. Delete signals 20x above the noise floor and interpolate over deletions
%       samples = tbx.rmspikes(samples,thresholdFactor=20,interpolate=true);
%
% <a href = "matlab:drEEMtoolbox.doc('rmspikes')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
    options.thresholdFactor (1,1) {mustBeNumeric} = 10
    options.interpolate (1,:) {mustBeNumericOrLogical} = false
    options.details (1,:) {mustBeNumericOrLogical} = false
    options.plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
end
% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    if nargout>0
        nargoutchk(1,1)
        diagnosticMode=false;
    else
        disp('<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified).')
        diagnosticMode=true;
        options.details=true;
        options.plot=true;
    end
end
%% Input parsing
Xname = 'X';
plt = options.plot;
diagn = options.details;
interpolate = options.interpolate;
constOpts=struct;
constOpts.medianDiff_fac=options.thresholdFactor;


%% Set & decide options
doparallel=true;
if isempty(gcp('nocreate'))
    doparallel=false;
end


%% Define variables
Xorg=data.(Xname);
X=Xorg;

XorgNaN=Xorg;
nSample=size(Xorg,1);
xdiff=zeros(data.nSample,data.nEm,data.nEx);

% Xorg: The original data with different elements removed
Xcut{1}=Xorg;Xcut{2}=Xorg;Xcut{3}=Xorg;Xcut{4}=Xorg;

% 1 & 2 are alternating cuts of excitation scans
Xcut{1}(:,:,3:2:end)=nan;
Xcut{2}(:,:,2:2:end)=nan;

% 3 & 4 are alternating cuts of emission scans
Xcut{3}(:,3:2:end,:)=nan;
Xcut{4}(:,2:2:end,:)=nan;

Xint=cell(4,1);
for j=1:numel(Xint)
    Xint{j}=ones(size(Xorg));
end


xreint=nan(nSample,data.nEm,data.nEx);

%% Function code
disp('2d-interpolation of alternatingly deleted data (4 rounds)...')

% Filling the deleted scans with smooth guess
if doparallel
    parfor k=1:numel(Xcut)
        
        for j=1:nSample
            Xint{k}(j,:,:)=inpaint_nans(squeeze(Xcut{k}(j,:,:)),1);
        end
    end
else
    for k=1:numel(Xcut)
        
        for j=1:nSample
            Xint{k}(j,:,:)=inpaint_nans(squeeze(Xcut{k}(j,:,:)),1);
        end
    end
end


cutstart=[3 2 3 2]; % Variable that defines where the cutting started
% Difference between guessed fluorescence and observed fluorescence no. 1
for k=1:2
    for j=1:nSample
        xidiff=squeeze(Xorg(j,:,:))-squeeze(Xint{k}(j,:,:));
        xdiff(j,:,cutstart(k):2:end)=squeeze(xdiff(j,:,cutstart(k):2:end))+xidiff(:,cutstart(k):2:end);
    end
end

% Difference between guessed fluorescence and observed fluorescence no. 2
for k=3:4
    for j=1:nSample
        xidiff=squeeze(Xorg(j,:,:))-squeeze(Xint{k}(j,:,:));
        xdiff(j,cutstart(k):2:end,:)=squeeze(xdiff(j,cutstart(k):2:end,:))+xidiff(cutstart(k):2:end,:);
    end
end

% NaN's the areas that were zero'ed by handlescatter (median would be artificially low)
xdiff(Xorg==0)=nan; 
cuttoff = squeeze(median(median(abs(xdiff),1,"omitnan"),2,"omitnan"));

if any(isnan(cuttoff))
    error(['The estimate of the noise floor contains NaNs. Cannot continue.' ...
        ' Most likely, you need to trim your dataset since it appears to include' ...
        'wavelengths without any information (exclusively NaN or zeros) '])
end

% Option to apply a shallower curve than the median noise otherwise would
% if sqrt or other transformation is applied here.
c2=sqrt(cuttoff);

c2=c2.*(cuttoff./c2(end));
cuttoff = repmat(c2,1,data.nEm)';

cuttoff=cuttoff.*constOpts.medianDiff_fac;

Xmarked1=nan(size(Xorg,1),size(Xorg,2),size(Xorg,3));
for j=1:nSample
    xreint(j,:,:) = abs(squeeze(xdiff(j,:,:)));
    XorgNaN(j,squeeze(xreint(j,:,:))>cuttoff)=nan;
    del=squeeze(xreint(j,:,:))>cuttoff;
    Xmarked1(j,del)=Xorg(j,del);
    
    X(j,del)=nan;

end

% And last the inpainting over the removed areas to reduce the impact of
% NaN's
Xi=nan(nSample,data.nEm,data.nEx);
disp('Finishing up...')

if interpolate
    if doparallel
        parfor j=1:nSample
            Xi(j,:,:)=inpaint_nans(squeeze(X(j,:,:)),1);
        end
    else
        for j=1:nSample
            Xi(j,:,:)=inpaint_nans(squeeze(X(j,:,:)),1);
        end
    end
        
else
    Xi=X;
end

for j=1:nSample
    xhere=squeeze(Xmarked1(j,:,:));
    pEx(j,:)=sum(not(isnan(xhere)),1)./data.nEx;
    pEm(j,:)=sum(not(isnan(xhere)),2)./data.nEm;
end


remEx=data.Ex(sum(pEx>.2,1)./nSample>.8);
remEm=data.Em(sum(pEm>.2,1)./nSample>.8);

if not(isempty(remEx))
    warning(['More than 80% of samples have more than 20% noisy  datapoints at ex = ',num2str(remEx')])
end

if not(isempty(remEm))
    warning(['More than 80% of samples have more than 20% noisy datapoints at em = ',num2str(remEx')])
end



%% Finishing up
dataout=data;
% Final interpolation replaced all NaN's (even scatter diagonals)
Xi(isnan(data.(Xname)))=nan;

dataout.(Xname)=Xi;



%% Plot the results for trouble shooting
vec=@(x) x(:);
if diagn
    if diagn
        if data.toolboxOptions.uifig
            fig=drEEMtoolbox.dreemuifig;
        else
            fig=drEEMtoolbox.dreemfig;
        end
        set(fig,Units='normalized',Position=[.1 .1 .6 .6])
        movegui(fig,'center')
        huic = uicontrol(fig,'Style', 'pushbutton','String','Next',...
            'Units','normalized','Position', [0.9323 0.0240 0.0604 0.0500],...
            'Callback',{@pltnext});

        t=tiledlayout(fig,'flow');
        for k=1:4
            ax(k)=nexttile(t);
        end
    end
    ax=ax([1 4 3 2]);
    uialert(fig,['Click next to jump to the next sample. ' ...
        'Closing the figure will stop the plotting and complete' ...
        ' the function execution'],'Information',Icon='info')
    cont=true;
    for j=1:nSample
        if cont

            mesh(ax(1),data.Ex,data.Em,squeeze(Xorg(j,:,:)))
            mesh(ax(2),data.Ex,data.Em,squeeze(xreint(j,:,:)),'FaceColor','k','EdgeColor',[0.6         0.6           1])
            hold(ax(2),'on')
            mesh(ax(2),data.Ex,data.Em,cuttoff,'FaceColor','r','EdgeColor','none','FaceAlpha',0.7)
            hold(ax(2),'off')
            mesh(ax(3),data.Ex,data.Em,squeeze(Xorg(j,:,:))) % Old: XorgNaN(j,:,:))

            hold(ax(3),'on')
            [X,Y] = meshgrid(data.Ex,data.Em);
            scatter3(ax(3),vec(X),vec(Y),vec(squeeze(Xmarked1(j,:,:))),'filled','r')
            hold(ax(3),'off')




            mesh(ax(4),data.Ex,data.Em,squeeze(Xi(j,:,:)))

            title(t,[num2str(j),' of ',num2str(data.nSample),'. data.i=',num2str(data.i(j)),' filename: ',data.filelist{j}])
            title(ax(1),'original data')
            title(ax(2),'| data - smoothed data| & threshold plane (red)')
            title(ax(3),'original data (removals marked)')
            title(ax(4),'final output')
            colormap(fig,turbo)
            xlabel(t,'Exication (nm)')
            ylabel(t,'Emission (nm)')
            for k=1:numel(ax)
                view(ax(k),78,64)
            end
            %         view(ax(1),[90 10.7])
            %         view(ax(4),[90 10.7])
            uicontrol(huic)
            uiwait(fig)
            if ~ishandle(fig)
                cont=false;
                continue% Ends function when plot is closed by user
            end
        else
        end
    end
end
%% Plot the final results
if plt

    f=uifigure;
    f.Name='drEEM: rmspikes.m';
    t=tiledlayout(f,"flow");
    ax=nexttile(t);
    plot(ax,data.Ex,squeeze(cuttoff(1,:,:)),'k')
    title(ax,'Noise threshold profile (along excitation)')
    ax=nexttile(t);
    h=plot(ax,data.Ex,pEx.*100);
    set(h, {'color'}, num2cell(turbo(numel(h)),2))
    title(ax,'Excitation')
    ax=nexttile(t);
    h=plot(ax,data.Em,pEm.*100);
    set(h, {'color'}, num2cell(turbo(numel(h)),2))
    title(ax,'Emission')
    ylabel(t,'% Removed at wavelength')
    xlabel(t,'Wavelength (nm)')
    title(t,'Removal overview: %-age removed per sample')

end
% Make the history entry
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,...
    'Automatic removal of noisy data was carried out',options,dataout);

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
function pltnext(sosurce,event) %#ok<INUSD>
uiresume(sosurce.Parent)
end
%%
function endfunc(~,~,hfig) 
close(hfig)
end
function B=inpaint_nans(A,method)
% INPAINT_NANS: in-paints over nans in an array
% usage: B=INPAINT_NANS(A)          % default method
% usage: B=INPAINT_NANS(A,method)   % specify method used
%
% Solves approximation to one of several pdes to
% interpolate and extrapolate holes in an array
%
% arguments (input):
%   A - nxm array with some NaNs to be filled in
%
%   method - (OPTIONAL) scalar numeric flag - specifies
%       which approach (or physical metaphor to use
%       for the interpolation.) All methods are capable
%       of extrapolation, some are better than others.
%       There are also speed differences, as well as
%       accuracy differences for smooth surfaces.
%
%       methods {0,1,2} use a simple plate metaphor.
%       method  3 uses a better plate equation,
%                 but may be much slower and uses
%                 more memory.
%       method  4 uses a spring metaphor.
%       method  5 is an 8 neighbor average, with no
%                 rationale behind it compared to the
%                 other methods. I do not recommend
%                 its use.
%
%       method == 0 --> (DEFAULT) see method 1, but
%         this method does not build as large of a
%         linear system in the case of only a few
%         NaNs in a large array.
%         Extrapolation behavior is linear.
%         
%       method == 1 --> simple approach, applies del^2
%         over the entire array, then drops those parts
%         of the array which do not have any contact with
%         NaNs. Uses a least squares approach, but it
%         does not modify known values.
%         In the case of small arrays, this method is
%         quite fast as it does very little extra work.
%         Extrapolation behavior is linear.
%         
%       method == 2 --> uses del^2, but solving a direct
%         linear system of equations for nan elements.
%         This method will be the fastest possible for
%         large systems since it uses the sparsest
%         possible system of equations. Not a least
%         squares approach, so it may be least robust
%         to noise on the boundaries of any holes.
%         This method will also be least able to
%         interpolate accurately for smooth surfaces.
%         Extrapolation behavior is linear.
%
%         Note: method 2 has problems in 1-d, so this
%         method is disabled for vector inputs.
%         
%       method == 3 --+ See method 0, but uses del^4 for
%         the interpolating operator. This may result
%         in more accurate interpolations, at some cost
%         in speed.
%         
%       method == 4 --+ Uses a spring metaphor. Assumes
%         springs (with a nominal length of zero)
%         connect each node with every neighbor
%         (horizontally, vertically and diagonally)
%         Since each node tries to be like its neighbors,
%         extrapolation is as a constant function where
%         this is consistent with the neighboring nodes.
%
%       method == 5 --+ See method 2, but use an average
%         of the 8 nearest neighbors to any element.
%         This method is NOT recommended for use.
%
%
% arguments (output):
%   B - nxm array with NaNs replaced
%
%
% Example:
%  [x,y] = meshgrid(0:.01:1);
%  z0 = exp(x+y);
%  znan = z0;
%  znan(20:50,40:70) = NaN;
%  znan(30:90,5:10) = NaN;
%  znan(70:75,40:90) = NaN;
%
%  z = inpaint_nans(znan);
%
%
% See also: griddata, interp1
%
% Author: John D'Errico
% e-mail address: woodchips@rochester.rr.com
% Release: 2
% Release date: 4/15/06
% I always need to know which elements are NaN,
% and what size the array is for any method
[n,m]=size(A);
A=A(:);
nm=n*m;
k=isnan(A(:));
% list the nodes which are known, and which will
% be interpolated
nan_list=find(k);
known_list=find(~k);
% how many nans overall
nan_count=length(nan_list);
% convert NaN indices to (r,c) form
% nan_list==find(k) are the unrolled (linear) indices
% (row,column) form
[nr,nc]=ind2sub([n,m],nan_list);
% both forms of index in one array:
% column 1 == unrolled index
% column 2 == row index
% column 3 == column index
nan_list=[nan_list,nr,nc];
% supply default method
if (nargin<2) || isempty(method)
  method = 0;
elseif ~ismember(method,0:5)
  error 'If supplied, method must be one of: {0,1,2,3,4,5}.'
end
% for different methods
switch method
 case 0
  % The same as method == 1, except only work on those
  % elements which are NaN, or at least touch a NaN.
  
  % is it 1-d or 2-d?
  if (m == 1) || (n == 1)
    % really a 1-d case
    work_list = nan_list(:,1);
    work_list = unique([work_list;work_list - 1;work_list + 1]);
    work_list(work_list <= 1) = [];
    work_list(work_list >= nm) = [];
    nw = numel(work_list);
    
    u = (1:nw)';
    fda = sparse(repmat(u,1,3),bsxfun(@plus,work_list,-1:1), ...
      repmat([1 -2 1],nw,1),nw,nm);
  else
    % a 2-d case
    
    % horizontal and vertical neighbors only
    talks_to = [-1 0;0 -1;1 0;0 1];
    neighbors_list=identify_neighbors(n,m,nan_list,talks_to);
    
    % list of all nodes we have identified
    all_list=[nan_list;neighbors_list];
    
    % generate sparse array with second partials on row
    % variable for each element in either list, but only
    % for those nodes which have a row index > 1 or < n
    L = find((all_list(:,2) > 1) & (all_list(:,2) < n));
    nl=length(L);
    if nl>0
      fda=sparse(repmat(all_list(L,1),1,3), ...
        repmat(all_list(L,1),1,3)+repmat([-1 0 1],nl,1), ...
        repmat([1 -2 1],nl,1),nm,nm);
    else
      fda=spalloc(n*m,n*m,size(all_list,1)*5);
    end
    
    % 2nd partials on column index
    L = find((all_list(:,3) > 1) & (all_list(:,3) < m));
    nl=length(L);
    if nl>0
      fda=fda+sparse(repmat(all_list(L,1),1,3), ...
        repmat(all_list(L,1),1,3)+repmat([-n 0 n],nl,1), ...
        repmat([1 -2 1],nl,1),nm,nm);
    end
  end
  
  % eliminate knowns
  rhs=-fda(:,known_list)*A(known_list);
  k=find(any(fda(:,nan_list(:,1)),2));
  
  % and solve...
  B=A;
  B(nan_list(:,1))=fda(k,nan_list(:,1))\rhs(k);
  
 case 1
  % least squares approach with del^2. Build system
  % for every array element as an unknown, and then
  % eliminate those which are knowns.
  % Build sparse matrix approximating del^2 for
  % every element in A.
  
  % is it 1-d or 2-d?
  if (m == 1) || (n == 1)
    % a 1-d case
    u = (1:(nm-2))';
    fda = sparse(repmat(u,1,3),bsxfun(@plus,u,0:2), ...
      repmat([1 -2 1],nm-2,1),nm-2,nm);
  else
    % a 2-d case
    
    % Compute finite difference for second partials
    % on row variable first
    [i,j]=ndgrid(2:(n-1),1:m);
    ind=i(:)+(j(:)-1)*n;
    np=(n-2)*m;
    fda=sparse(repmat(ind,1,3),[ind-1,ind,ind+1], ...
      repmat([1 -2 1],np,1),n*m,n*m);
    
    % now second partials on column variable
    [i,j]=ndgrid(1:n,2:(m-1));
    ind=i(:)+(j(:)-1)*n;
    np=n*(m-2);
    fda=fda+sparse(repmat(ind,1,3),[ind-n,ind,ind+n], ...
      repmat([1 -2 1],np,1),nm,nm);
  end
  
  % eliminate knowns
  rhs=-fda(:,known_list)*A(known_list);
  k=find(any(fda(:,nan_list),2));
  
  % and solve...
  B=A;
  B(nan_list(:,1))=fda(k,nan_list(:,1))\rhs(k);
  
 case 2
  % Direct solve for del^2 BVP across holes
  % generate sparse array with second partials on row
  % variable for each nan element, only for those nodes
  % which have a row index > 1 or < n
  
  % is it 1-d or 2-d?
  if (m == 1) || (n == 1)
    % really just a 1-d case
    error('Method 2 has problems for vector input. Please use another method.')
    
  else
    % a 2-d case
    L = find((nan_list(:,2) > 1) & (nan_list(:,2) < n));
    nl=length(L);
    if nl>0
      fda=sparse(repmat(nan_list(L,1),1,3), ...
        repmat(nan_list(L,1),1,3)+repmat([-1 0 1],nl,1), ...
        repmat([1 -2 1],nl,1),n*m,n*m);
    else
      fda=spalloc(n*m,n*m,size(nan_list,1)*5);
    end
    
    % 2nd partials on column index
    L = find((nan_list(:,3) > 1) & (nan_list(:,3) < m));
    nl=length(L);
    if nl>0
      fda=fda+sparse(repmat(nan_list(L,1),1,3), ...
        repmat(nan_list(L,1),1,3)+repmat([-n 0 n],nl,1), ...
        repmat([1 -2 1],nl,1),n*m,n*m);
    end
    
    % fix boundary conditions at extreme corners
    % of the array in case there were nans there
    if ismember(1,nan_list(:,1))
      fda(1,[1 2 n+1])=[-2 1 1];
    end
    if ismember(n,nan_list(:,1))
      fda(n,[n, n-1,n+n])=[-2 1 1];
    end
    if ismember(nm-n+1,nan_list(:,1))
      fda(nm-n+1,[nm-n+1,nm-n+2,nm-n])=[-2 1 1];
    end
    if ismember(nm,nan_list(:,1))
      fda(nm,[nm,nm-1,nm-n])=[-2 1 1];
    end
    
    % eliminate knowns
    rhs=-fda(:,known_list)*A(known_list);
    
    % and solve...
    B=A;
    k=nan_list(:,1);
    B(k)=fda(k,k)\rhs(k);
    
  end
  
 case 3
  % The same as method == 0, except uses del^4 as the
  % interpolating operator.
  
  % del^4 template of neighbors
  talks_to = [-2 0;-1 -1;-1 0;-1 1;0 -2;0 -1; ...
      0 1;0 2;1 -1;1 0;1 1;2 0];
  neighbors_list=identify_neighbors(n,m,nan_list,talks_to);
  
  % list of all nodes we have identified
  all_list=[nan_list;neighbors_list];
  
  % generate sparse array with del^4, but only
  % for those nodes which have a row & column index
  % >= 3 or <= n-2
  L = find( (all_list(:,2) >= 3) & ...
            (all_list(:,2) <= (n-2)) & ...
            (all_list(:,3) >= 3) & ...
            (all_list(:,3) <= (m-2)));
  nl=length(L);
  if nl>0
    % do the entire template at once
    fda=sparse(repmat(all_list(L,1),1,13), ...
        repmat(all_list(L,1),1,13) + ...
        repmat([-2*n,-n-1,-n,-n+1,-2,-1,0,1,2,n-1,n,n+1,2*n],nl,1), ...
        repmat([1 2 -8 2 1 -8 20 -8 1 2 -8 2 1],nl,1),nm,nm);
  else
    fda=spalloc(n*m,n*m,size(all_list,1)*5);
  end
  
  % on the boundaries, reduce the order around the edges
  L = find((((all_list(:,2) == 2) | ...
             (all_list(:,2) == (n-1))) & ...
            (all_list(:,3) >= 2) & ...
            (all_list(:,3) <= (m-1))) | ...
           (((all_list(:,3) == 2) | ...
             (all_list(:,3) == (m-1))) & ...
            (all_list(:,2) >= 2) & ...
            (all_list(:,2) <= (n-1))));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(all_list(L,1),1,5), ...
      repmat(all_list(L,1),1,5) + ...
        repmat([-n,-1,0,+1,n],nl,1), ...
      repmat([1 1 -4 1 1],nl,1),nm,nm);
  end
  
  L = find( ((all_list(:,2) == 1) | ...
             (all_list(:,2) == n)) & ...
            (all_list(:,3) >= 2) & ...
            (all_list(:,3) <= (m-1)));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(all_list(L,1),1,3), ...
      repmat(all_list(L,1),1,3) + ...
        repmat([-n,0,n],nl,1), ...
      repmat([1 -2 1],nl,1),nm,nm);
  end
  
  L = find( ((all_list(:,3) == 1) | ...
             (all_list(:,3) == m)) & ...
            (all_list(:,2) >= 2) & ...
            (all_list(:,2) <= (n-1)));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(all_list(L,1),1,3), ...
      repmat(all_list(L,1),1,3) + ...
        repmat([-1,0,1],nl,1), ...
      repmat([1 -2 1],nl,1),nm,nm);
  end
  
  % eliminate knowns
  rhs=-fda(:,known_list)*A(known_list);
  k=find(any(fda(:,nan_list(:,1)),2));
  
  % and solve...
  B=A;
  B(nan_list(:,1))=fda(k,nan_list(:,1))\rhs(k);
  
 case 4
  % Spring analogy
  % interpolating operator.
  
  % list of all springs between a node and a horizontal
  % or vertical neighbor
  hv_list=[-1 -1 0;1 1 0;-n 0 -1;n 0 1];
  hv_springs=[];
  for i=1:4
    hvs=nan_list+repmat(hv_list(i,:),nan_count,1);
    k=(hvs(:,2)>=1) & (hvs(:,2)<=n) & (hvs(:,3)>=1) & (hvs(:,3)<=m);
    hv_springs=[hv_springs;[nan_list(k,1),hvs(k,1)]];
  end
  % delete replicate springs
  hv_springs=unique(sort(hv_springs,2),'rows');
  
  % build sparse matrix of connections, springs
  % connecting diagonal neighbors are weaker than
  % the horizontal and vertical springs
  nhv=size(hv_springs,1);
  springs=sparse(repmat((1:nhv)',1,2),hv_springs, ...
     repmat([1 -1],nhv,1),nhv,nm);
  
  % eliminate knowns
  rhs=-springs(:,known_list)*A(known_list);
  
  % and solve...
  B=A;
  B(nan_list(:,1))=springs(:,nan_list(:,1))\rhs;
  
 case 5
  % Average of 8 nearest neighbors
  
  % generate sparse array to average 8 nearest neighbors
  % for each nan element, be careful around edges
  fda=spalloc(n*m,n*m,size(nan_list,1)*9);
  
  % -1,-1
  L = find((nan_list(:,2) > 1) & (nan_list(:,3) > 1)); 
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([-n-1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  
  % 0,-1
  L = find(nan_list(:,3) > 1);
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([-n, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % +1,-1
  L = find((nan_list(:,2) < n) & (nan_list(:,3) > 1));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([-n+1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % -1,0
  L = find(nan_list(:,2) > 1);
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([-1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % +1,0
  L = find(nan_list(:,2) < n);
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % -1,+1
  L = find((nan_list(:,2) > 1) & (nan_list(:,3) < m)); 
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([n-1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  
  % 0,+1
  L = find(nan_list(:,3) < m);
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([n, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % +1,+1
  L = find((nan_list(:,2) < n) & (nan_list(:,3) < m));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([n+1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  
  % eliminate knowns
  rhs=-fda(:,known_list)*A(known_list);
  
  % and solve...
  B=A;
  k=nan_list(:,1);
  B(k)=fda(k,k)\rhs(k);
  
end
% all done, make sure that B is the same shape as
% A was when we came in.
B=reshape(B,n,m);
% ====================================================
%      end of main function
% ====================================================
end
% ====================================================
%      begin subfunctions
% ====================================================
function neighbors_list=identify_neighbors(n,m,nan_list,talks_to)
% identify_neighbors: identifies all the neighbors of
%   those nodes in nan_list, not including the nans
%   themselves
%
% arguments (input):
%  n,m - scalar - [n,m]=size(A), where A is the
%      array to be interpolated
%  nan_list - array - list of every nan element in A
%      nan_list(i,1) == linear index of i'th nan element
%      nan_list(i,2) == row index of i'th nan element
%      nan_list(i,3) == column index of i'th nan element
%  talks_to - px2 array - defines which nodes communicate
%      with each other, i.e., which nodes are neighbors.
%
%      talks_to(i,1) - defines the offset in the row
%                      dimension of a neighbor
%      talks_to(i,2) - defines the offset in the column
%                      dimension of a neighbor
%      
%      For example, talks_to = [-1 0;0 -1;1 0;0 1]
%      means that each node talks only to its immediate
%      neighbors horizontally and vertically.
% 
% arguments(output):
%  neighbors_list - array - list of all neighbors of
%      all the nodes in nan_list
if ~isempty(nan_list)
  % use the definition of a neighbor in talks_to
  nan_count=size(nan_list,1);
  talk_count=size(talks_to,1);
  
  nn=zeros(nan_count*talk_count,2);
  j=[1,nan_count];
  for i=1:talk_count
    nn(j(1):j(2),:)=nan_list(:,2:3) + ...
        repmat(talks_to(i,:),nan_count,1);
    j=j+nan_count;
  end
  
  % drop those nodes which fall outside the bounds of the
  % original array
  L = (nn(:,1)<1)|(nn(:,1)>n)|(nn(:,2)<1)|(nn(:,2)>m); 
  nn(L,:)=[];
  
  % form the same format 3 column array as nan_list
  neighbors_list=[sub2ind([n,m],nn(:,1),nn(:,2)),nn];
  
  % delete replicates in the neighbors list
  neighbors_list=unique(neighbors_list,'rows');
  
  % and delete those which are also in the list of NaNs.
  neighbors_list=setdiff(neighbors_list,nan_list,'rows');
  
else
  neighbors_list=[];
end
end