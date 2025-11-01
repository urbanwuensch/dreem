function export2openfluor(data, f, filename)
% <a href = "matlab:drEEMtoolbox.doc('export2openfluor')">export2openfluor(data,f,filename) (click to access documentation)</a>
%
% <strong>Export PARAFAC model for OpenFluor comparisons</strong>
%
% <strong>INPUTS - Required</strong>
% data (1,1)      {mustBeA("drEEMdataset"),drEEMdataset.validate}
% f   (1,1)       {mustBeInteger,drEEMdataset.mustBeModel}
% filename (1,:)  {mustBeText}
%
% <strong>EXAMPLE(S)</strong>
%   1. Export a 5-component model to a text file that can be uploaded to
%   OpenFluor.org with an automatic date addition to the filename
%       tbx.export2openfluor(samples,5,['myAwesome5Cmodel_',char(datetime('today'))]);
%
% <a href = "matlab:drEEMtoolbox.doc('export2openfluor')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1)      {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data)}
    f   (1,1)       {mustBeInteger,drEEMdataset.mustBeModel(data,f)}
    filename (1,:)  {mustBeText}
end

drEEMdataset.mustBeModel(data,f)

filename=strsplit(filename,'.');
filename=filename{1};
filename=[filename,'.txt'];

M=data.models(f).loads;
B=M{2};C=M{3};
Ex=data.Ex;
Em=data.Em;
if ~isequal(round(Ex),Ex)
    Exint=round((max(Ex)-min(Ex))/(length(Ex)-1));
    Exmin=round(min(Ex));
    Exmax=round(max(Ex));
    C=interp1(Ex,C,Exmin:Exint:Exmax,'spline','extrap');
    Ex=(Exmin:Exint:Exmax)';
end
if ~isequal(round(Em),Em)
    Emint=round((max(Em)-min(Em))/(length(Em)-1));
    Emmin=round(min(Em));
    Emmax=round(max(Em));
    B=interp1(Em,B,Emmin:Emint:Emmax,'spline','extrap');
    Em=(Emmin:Emint:Emmax)';
end
report=[Ex C;Em B];
RowHead=char(repmat('Ex',[size(C,1),1]),repmat('Em',[size(B,1),1]));

metafields=table;
metafields.fields={...
    'name',...
    'creator',...
    'email',...
    'doi',...
    'reference',...
    'unit',...
    'toolbox',...
    'date',...
    'fluorometer',...
    'nSample',...
    'constraints',...
    'validation',...
    'methods',...
    'preprocess',...
    'sources',...
    'ecozones',...
    'description'}';


metafields.values={...
    inputname(1),...
    data.toolboxdata.host,...
    '',...
    '',...
    '',...
    data.status.signalCalibration,...
    data.toolboxdata.version,...
    char(datetime("today")),...
    '',...
    num2str(data.nSample),...
    data.models(f).constraints,...
    data.models(f).status,...
    '',...
    '',...
    '',...
    '',...
    ''}';
fid = fopen(filename, 'w');
fprintf(fid, '%s\t\n', '#');
fprintf(fid, '%s\t\n', '# Fluorescence Model');
fprintf(fid, '%s\t\n', '#');
for i=1:size(metafields,1)
    fprintf(fid, '%s\t', metafields.fields{i});
    fprintf(fid, '%s\n', char(metafields.values{i}));
end
fprintf(fid, '%s\t\n', '#');
fprintf(fid, '%s\t\n', '# Excitation/Emission (Ex, Em), wavelength (nm), component[n] (intensity)');
fprintf(fid, '%s\t\n', '#');

for i=1:size(report,1)
    fprintf(fid, '%s\t', RowHead(i,:));
    fprintf(fid, '%d\t', report(i,1));
    fprintf(fid, '%10.8f\t', report(i,2:end));
    if i<size(report,1)
        fprintf(fid, '\n');
    end
end
fclose(fid);

tbx.displaycitationinformation

end