function [summary,M]  =  viewopenfluormatches(filename,options)
% <a href = "matlab:drEEMtoolbox.doc('viewopenfluormatches')">[summary,M] = viewopenfluormatches(filename) (click to access documentation)</a>
%
% <strong>Import results from OpenFluor</strong> for analysis
%
% <strong>Inputs - Required</strong>
% filename (1,:) {mustBeFile}
%
% <strong>EXAMPLE(S)</strong>
%   [summary,M] = tbx.viewopenfluormatches(which("OpenFluorSearch_384_osPARAFAC_Tapajos_20250223.csv"))
%
% <a href = "matlab:drEEMtoolbox.doc('viewopenfluormatches')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    filename (1,:) {mustBeFile}
    options.figurefile (1,:) {mustBeText} = ""
end

%% Load file and store contents in cell array
disp('Loading the matching result file...')
if iscell(filename)
    filename = deblank(char(filename));
end
try
    fid  =  fopen(filename, 'r');
catch
    error('Could not open the specified file.')
end
counter  =  1;
tline  =  fgetl(fid);
while ischar(tline)
    tline  =  fgetl(fid);
    data{counter,1} = tline;
    counter = counter+1;
end
fclose(fid);
data(end) = [];
data  =  data(~cellfun(@isempty, data));
clearvars tline counter fid % Cleanup

%% Make sure the file is really an OpenFluor product
if ~contains(data{1},'Dataset / Model')
    error('The contents suggests that the specified file is not an OpenFluor matching result.')
end

%% Find important indices
beginsummary = find(contains(data,'Summary of Matches'),1,'first');
beginspectra = find(contains(data,'---------------------------------'),1,'first');

if isempty(beginsummary)||isempty(beginspectra)
    error('Error: Perhaps you should export the matching result once more and try again.')
end
%% Subset data
header = data(1:beginsummary-1); % Header is everything above the summary
modellist = header(find(contains(header,'Models'),1,'first')+1:end); % The header minus the very start
summaryinfo = data(beginsummary+1:beginspectra-1); % Summary contains match statistics
spectra = data(beginspectra:end); % Spectra contains the spectra (no match statistics)

clearvars beginsummary beginspectra % Cleanup

%% 1. Extract model names and IDs
modelnames  =  cell(numel(modellist),1);
modelids  =  cell(numel(modellist),1);
modeldoi  =  cell(numel(modellist),1);
for n = 1:numel(modellist)
    tempvar = strsplit(modellist{n},{' (',')',','}); % Split each model into name and database ID.
    if ~isempty(tempvar{1})
        modelnames(n,1) = tempvar(1);
        modelids(n,1) = tempvar(2);
        modeldoi(n,1) = tempvar(3);
    end
end
clearvars tempvar n % Cleanup

%% 2. Extract summary information
disp('Preparing match summary...')

% Get the name of the reference model
referencemodelname=erase(header{1},'Dataset / Model: ');
if strcmp(referencemodelname,'?')
    referencemodelname='Comparison reference';
end
% Get the height of the summary table.
summaryheight = numel(summaryinfo)-numel(find(contains(summaryinfo,{'Summary of','#Comp in'})));
% Prepare table
summary = table('size',[summaryheight,9],...
    'VariableTypes',{'categorical','categorical','double','double','double','double','double','double','double'},...
    'VariableNames',{'model','doi','id','matchid','Creference','Cmodel','simiem','simiex','simiexem'});

counter = 1; % Counter is necessary to 2unfold" the matching summary
for n = 1:size(modelnames,1)
    idx = find(contains(summaryinfo,[' ',modelnames{n},',']),1,'last');
    try
        inext = find(contains(summaryinfo,[' ',modelnames{n+1},',']),1,'first')-2;
    catch
        inext = numel(summaryinfo);
    end
    subset = summaryinfo(idx+1:inext);
    for jj = 1:numel(subset)
        tempvar1 = subset{jj};
        if isempty(erase(tempvar1,','))
            summary.model(counter) = categorical(modelnames(n));
            summary.doi(counter) = categorical(cellstr(modeldoi{n}));
            summary.id(counter) = str2double(erase(modelids{n},'ID : '));
            summary.matchid(counter) = counter;
            summary.Creference(counter) = NaN;
            summary.Cmodel(counter) = NaN;
            summary.simiem(counter) = NaN;
            summary.simiex(counter) = NaN;
            summary.simiexem(counter) = NaN;
            break
        end
        tempvar2 = str2double(strsplit(tempvar1,','));
        summary.model(counter) = categorical(modelnames(n));
        summary.doi(counter) = categorical(cellstr(modeldoi{n}));
        summary.id(counter) = str2double(erase(modelids{n},'ID : '));
        summary.matchid(counter) = counter;
        summary.Creference(counter) = tempvar2(1);
        summary.Cmodel(counter) = tempvar2(2);
        summary.simiem(counter) = tempvar2(3);
        summary.simiex(counter) = tempvar2(4);
        summary.simiexem(counter) = tempvar2(5);
        counter = counter+1;
    end
end
summary(summary.id==0,:) = [];


clearvars counter n jj inext idx summaryheight tempvar1 tempvar2 subset % Cleanup
%% 3. Extract spectral information (per component)
disp('Extracting the matching component loadings...')

cmatched = unique(summary.Creference);
loadtype={'Ex','Em'};
protectedvars = [who;{'n'};{'M'};{'protectedvars'}];
for n = 1:numel(cmatched)
    clearvars('-except', protectedvars{:});
    % Find the segment that contains matches for a given component
    ibegin = find(contains(spectra,['Matched Component: C',num2str(cmatched(n))]));
    try
        iend = find(contains(spectra,['Matched Component: C',num2str(cmatched(n+1))]));
    catch
        iend = numel(spectra)+2; % add 2 to later compensate the cut off for non end comps
    end
    % Select that chunk
    subset = spectra(ibegin+2:iend-2);
    
    
    idx(1,1) = find(contains(subset,'Type: Ex'));
    idx(2,1) = find(contains(subset,'Type: Em'));
    idx(1,2) = idx(2,1)-1;
    idx(2,2) = numel(subset);
    
    
    for ii=1:numel(loadtype)
        chunk = subset(idx(ii,1)+2:idx(ii,2));
        chunksize = numel(chunk);
        wave = strsplit(erase(subset{idx(ii,1)+1},'wavelength,'));
        nWave = count(wave{1},',')+1;
        wave = sscanf(wave{1},'%f,',[1 nWave])';
        loadn = nan(chunksize,nWave);
        mname = cell(chunksize,1);
        mdoi = cell(chunksize,1);
        matchid = nan(chunksize,1);
        matchedcomp = nan(chunksize,1);
        for jj = 1:chunksize
            if numel(strfind(chunk{jj},')'))>1
                findidx=strfind(chunk{jj},')');
                chunk{jj}(findidx(1))=[];
            end
            tempvar = strsplit(chunk{jj},{'(ID : ',') '});
            compno=strsplit(chunk{jj},{') ',','});
            compno=str2double(erase(compno{2},'C'));
            
            id = str2double(tempvar{2});
            % Cross reference the loadings with the summary table
            if jj>1
                try matchid(jj)=summary.matchid(id==summary.id&compno==summary.Cmodel);
                catch
                    matchid(jj)=nan;
                end
            end
            mname(jj) = cellstr(char(summary.model(find(summary.id==id,1,'first'))));
            mdoi(jj) = cellstr(char(summary.doi(find(summary.id==id,1,'first'))));
            matchedcomp(jj) = compno;
            % The reference always comes first. It's not mentioned in the summary, because it is referenced to.
            if isempty(mname{jj})&&jj==1
                 mname(jj)=cellstr('Comparison reference');
            end
            loadings = tempvar{3};
            tempvar = strfind(loadings,',');
            try            
                loadings = split(loadings(tempvar(1):end),',');
            catch
                error('Error during the extraction of the component loadings of the PARAFAC models. Contact author at urbw@aqua.dtu.dk')
            end
            for kk = 1:nWave
                conv = str2double(loadings{kk});
                if isempty(loadings{kk})
                    loadn(jj,kk) =  NaN;
                else
                    loadn(jj,kk) =  conv;
                end
            end
        end

    
    M.(loadtype{ii}){cmatched(n)} = wave;
    M.([loadtype{ii},'_load']){cmatched(n),1} = loadn;
    M.MatchID{cmatched(n),1}=matchid;
    M.Modelname{cmatched(n),1} = mname;
    M.Modeldoi{cmatched(n),1} = mdoi;
    M.Modelcomp{cmatched(n),1} = matchedcomp;
    end
end
M.Creference = cmatched;
disp('All done...')
%%  4: Plot
if drEEMtoolbox.options.uifig
        hf=drEEMtoolbox.dreemuifig;
    else
        hf=drEEMtoolbox.dreemfig;
end
hf.Name  =  'OpenFluor Matching Results';
nplots  =  numel(M.Creference);
rc  =  [1 1;1 2;1 3;2 2;  2 3;  2 3;  2 4;  2 4;  3 3;   2 5;     3 4;       3 4;     4 4;      4 4];
tl = tiledlayout(hf,rc(nplots,1),rc(nplots,2),'padding','compact','TileSpacing','compact');
colors = makecolormap(numel(unique(summary.model)));
uniquemnames = unique(summary.model);
ax = gobjects(numel(M.Creference),1);
hem = cell(numel(M.Creference),1);
hex = cell(numel(M.Creference),1);
for n = 1:numel(M.Creference)
    ax(n) = nexttile(tl);

    hold(ax(n),'on')
    ncomp = size(M.Em_load{M.Creference(n)}',2);
    hem{n} = gobjects(ncomp,1);
    hex{n} = gobjects(ncomp,1);
    for i = 2:ncomp
        colidx = find(strcmp(M.Modelname{M.Creference(n)}{i},cellstr(uniquemnames)));
        if isempty(colidx)
            colidx = 1;
        end
        y = crescale(M.Em_load{M.Creference(n)}(i,:));
        x = M.Em{M.Creference(n)};
        psel=~isnan(y);
        hem{n}(i) = plot(ax(n),x(psel),y(psel),...
            'DisplayName',M.Modelname{M.Creference(n)}{i},...
            'Color',colors(colidx,:),'LineStyle','-','LineWidth',1.5);
        y = crescale(M.Ex_load{M.Creference(n)}(i,:));
        x = M.Ex{M.Creference(n)};
        psel=~isnan(y);
        hex{n}(i) = plot(ax(n),x(psel),y(psel),...
            'DisplayName',M.Modelname{M.Creference(n)}{i},...
            'Color',colors(colidx,:),'LineStyle','-.','LineWidth',1.5);
        addprop(hex{n}(i),'matchedcomp');
        addprop(hem{n}(i),'matchedcomp');
        hex{n}(i).matchedcomp=M.Modelcomp{M.Creference(n)}(i);
        hem{n}(i).matchedcomp=M.Modelcomp{M.Creference(n)}(i);
    end
    % Plot the first model (the user's model) on top
    y = crescale(M.Em_load{M.Creference(n)}(1,:));
    x = M.Em{M.Creference(n)};
    psel=~isnan(y);
    hem{n}(1) = plot(ax(n),x(psel),y(psel),...
        'DisplayName',referencemodelname,...
        'Color',[0 0 0],'LineStyle','-','LineWidth',1.7);
    y = crescale(M.Ex_load{M.Creference(n)}(1,:));
    x = M.Ex{M.Creference(n)};
    psel=~isnan(y);
    hex{n}(1) = plot(ax(n),x(psel),y(psel),...
        'DisplayName',referencemodelname,...
        'Color',[ 0 0 0],'LineStyle','-.','LineWidth',1.7);
    addprop(hex{n}(1),'matchedcomp');
    addprop(hem{n}(1),'matchedcomp');
    hex{n}(1).matchedcomp=M.Creference(n);
    hem{n}(1).matchedcomp=M.Creference(n);
    if (ncomp-1)>1
        titlepart=' matches';
    else
        titlepart=' match';
    end
    title(ax(n),['C',num2str(M.Creference(n)),' : ',num2str(ncomp-1),titlepart])
    axis(ax(n),'tight')
    grid(ax(n),'on')
    ylim(ax(n),[-0.05 1.05])
    set(ax(n),'YTickLabel','')
   
    
    addprop(ax(n),'refcomp');
    ax(n).refcomp=M.Creference(n);
    
end
 xlabel(tl,'Wavelength (nm)')
ylabel(tl,'Loadings')
dcm_obj  =  datacursormode(hf);
dcm_obj.Interpreter = 'none';
set(dcm_obj,'UpdateFcn',{@augmentdatacursor,summary,referencemodelname});
datacursormode(hf,'on')

figurefile=char(options.figurefile);
if not(isempty(figurefile))
    % Pause for figure rendering
    pause(3)
    try
        dreemgui.saveAfterFunctionCall(hf,figurefile)
    catch ME
        throwAsCaller(ME)
    end
end

end
function txt  =  augmentdatacursor(~,event_obj,summary,referencemodelname)
idx  =  get(event_obj, 'DataIndex');

switch event_obj.Target.DisplayName
    case referencemodelname
        txt  =  {referencemodelname,...
            ['wave. (nm): ',num2str(round(event_obj.Target.XData(idx)))],...
            ['y: ',num2str(round(event_obj.Target.YData(idx),2))]};
    otherwise
        try
            [names,iunique] = unique(summary.model,'stable');
            dois =summary.doi(iunique);
            hit=find(strcmp(cellstr(names),event_obj.Target.DisplayName));

            if numel(hit)>1 % Just in case multiple models have the same name.
                txt={['wave. (nm): ',num2str(round(event_obj.Target.XData(idx)))],...
                    ['y: ',num2str(round(event_obj.Target.YData(idx),2))]};
                return
            end

            componentmatched=num2str(event_obj.Target.matchedcomp);
            txt  =  {[char(names(hit)),': C',componentmatched],...
                ['doi ','copied to clipboard'],...
                ['wave. (nm): ',num2str(round(event_obj.Target.XData(idx)))],...
                ['y: ',num2str(round(event_obj.Target.YData(idx),2))]};

            if strcmp(char(dois(hit)),'<undefined>')||isempty(char(dois(hit)))
                doitoclipboard='no DOI available.';
            else
                doitoclipboard=string(dois(hit));
            end
            clipboard('copy',doitoclipboard)
        catch
            txt={['wave. (nm): ',num2str(round(event_obj.Target.XData(idx)))],...
                ['y: ',num2str(round(event_obj.Target.YData(idx),2))]};
        end
end

end


function colors  =  makecolormap(ncolor)

defaultmap = [255,205,37;
    253,206,39;
    251,206,41;
    249,207,43;
    247,208,45;
    245,209,47;
    243,210,49;
    241,210,51;
    239,211,53;
    236,212,55;
    234,213,57;
    232,213,59;
    230,214,61;
    228,215,63;
    226,216,65;
    224,217,67;
    222,217,69;
    220,218,72;
    218,219,74;
    216,220,76;
    214,221,78;
    212,221,80;
    210,222,82;
    208,223,84;
    206,224,86;
    203,224,88;
    201,225,90;
    199,226,92;
    197,227,94;
    195,228,96;
    193,228,98;
    191,229,100;
    189,230,102;
    187,231,104;
    185,232,106;
    183,232,108;
    181,233,110;
    179,234,112;
    177,235,114;
    175,236,116;
    173,236,118;
    171,237,120;
    168,238,122;
    166,239,124;
    164,239,126;
    162,240,128;
    160,241,130;
    158,242,132;
    156,243,134;
    154,243,136;
    152,244,138;
    150,245,140;
    148,246,142;
    146,247,144;
    144,247,146;
    142,248,148;
    140,249,150;
    138,250,152;
    135,250,154;
    133,251,157;
    131,252,159;
    129,253,161;
    127,254,163;
    125,254,165;
    124,254,166;
    125,252,164;
    126,250,162;
    127,248,160;
    128,246,158;
    129,244,156;
    130,242,153;
    131,240,151;
    132,238,149;
    133,236,147;
    134,234,145;
    135,232,143;
    136,230,141;
    137,228,139;
    138,226,137;
    139,224,135;
    140,222,133;
    141,219,131;
    142,217,129;
    143,215,127;
    144,213,125;
    145,211,123;
    146,209,121;
    147,207,119;
    148,205,117;
    149,203,115;
    150,201,113;
    151,199,111;
    152,197,109;
    153,195,107;
    154,193,105;
    155,191,103;
    156,189,101;
    157,186,99;
    159,184,97;
    160,182,95;
    161,180,93;
    162,178,91;
    163,176,89;
    164,174,87;
    165,172,85;
    166,170,83;
    167,168,81;
    168,166,79;
    169,164,77;
    170,162,75;
    171,160,73;
    172,158,70;
    173,156,68;
    174,154,66;
    175,151,64;
    176,149,62;
    177,147,60;
    178,145,58;
    179,143,56;
    180,141,54;
    181,139,52;
    182,137,50;
    183,135,48;
    184,133,46;
    185,131,44;
    186,129,42;
    187,127,40;
    188,125,38;
    188,123,38;
    186,123,39;
    183,122,40;
    181,121,42;
    179,120,43;
    177,120,45;
    175,119,46;
    173,118,47;
    171,117,49;
    169,116,50;
    167,116,51;
    165,115,53;
    163,114,54;
    161,113,55;
    159,113,57;
    157,112,58;
    155,111,59;
    153,110,61;
    151,110,62;
    149,109,64;
    147,108,65;
    145,107,66;
    143,107,68;
    141,106,69;
    139,105,70;
    137,104,72;
    135,104,73;
    133,103,74;
    131,102,76;
    129,101,77;
    127,101,78;
    125,100,80;
    123,99,81;
    121,98,83;
    119,98,84;
    117,97,85;
    115,96,87;
    113,95,88;
    111,95,89;
    109,94,91;
    107,93,92;
    105,92,93;
    103,92,95;
    100,91,96;
    98,90,98;
    96,89,99;
    94,89,100;
    92,88,102;
    90,87,103;
    88,86,104;
    86,86,106;
    84,85,107;
    82,84,108;
    80,83,110;
    78,83,111;
    76,82,112;
    74,81,114;
    72,80,115;
    70,80,117;
    68,79,118;
    66,78,119;
    64,77,121;
    62,77,122;
    60,76,123;
    59,77,125;
    58,78,127;
    57,79,129;
    56,80,131;
    55,81,133;
    54,82,135;
    53,83,137;
    52,84,139;
    51,85,141;
    50,86,143;
    49,87,145;
    49,88,147;
    48,89,149;
    47,90,151;
    46,91,153;
    45,92,155;
    44,93,157;
    43,94,159;
    42,95,161;
    41,96,163;
    40,97,165;
    39,98,167;
    38,99,169;
    37,100,171;
    36,102,173;
    35,103,175;
    35,104,176;
    34,105,178;
    33,106,180;
    32,107,182;
    31,108,184;
    30,109,186;
    29,110,188;
    28,111,190;
    27,112,192;
    26,113,194;
    25,114,196;
    24,115,198;
    23,116,200;
    22,117,202;
    21,118,204;
    21,119,206;
    20,120,208;
    19,121,210;
    18,122,212;
    17,123,214;
    16,124,216;
    15,126,218;
    14,127,220;
    13,128,222;
    12,129,224;
    11,130,226;
    10,131,228;
    9,132,230;
    8,133,232;
    7,134,234;
    7,135,236;
    6,136,238;
    5,137,240;
    4,138,242;
    3,139,244;
    2,140,246;
    1,141,248;
    0,142,250]./255;


if ncolor<=size(defaultmap,1)
    idx = floor(linspace(1,size(defaultmap,1),ncolor));
    colors = defaultmap(idx,:);
else
    colors = hsv(ncolor);
end
end


function out=crescale(in)
out=(in-min(in,[],'omitnan'))/(max(in,[],'omitnan')-min(in,[],'omitnan'));
end