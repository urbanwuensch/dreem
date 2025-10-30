load alt

Y = [0	0	0	55
0	0	0	220
275	0	0	0
0	25	0	0
46	4	2800	18
17	2	4700	28
20	1	3200	8
10	4	3200	16
6	2	2800	28
0	0	5600	0
0	8	0	0
56	0	0	0
28	0	0	0
0	0	0	5
0	0	700	0
0	16	0	0
3.5	1	350	20
3.5	0.5	175	20
3.5	0.25	700	10
1.75	4	1400	5
0.875	2	700	2.5
28	8	700	40
28	8	350	20
14	8	175	20
0.875	8	1400	2.5
1.75	8	700	5
3.5	2	700	80];

Ynames = {'Hydroquinone';'Tryptophan';'Phenylalanine';'Dopa'};

YID = [10
9
1
4
12
13
14
15
16
7
6
2
3
11
8
5
17
18
19
20
21
22
23
24
25
26
27];



EEM = dataset(reshape(X,DimX));
set(EEM,'name','EEM');
set(EEM,'author','Rasmus Bro');
set(EEM,'type','data');
EEM.label{1}=Names;
EEM.labelname{1} = 'Code';
EEM.axisscale{1}=YID;
EEM.axisscalename{1}='Sample Number';
EEM.axisscale{2}=Axis1;
EEM.axisscalename{2}='Wavelength/nm';
EEM.axisscale{3}=Axis2;
EEM.axisscalename{3}='Wavelength/nm';
EEM.title{1} = 'Sample';
EEM.title{2} = 'Emission';
EEM.title{3} = 'Excitation';
EEM.description = 'A Perkin-Elmer LS50 B fluorescence spectrometer was used to measure fluorescence landscapes using excitation wavelengths between 200-350 nm with 5 nm intervals. The emission wavelength range was 200-750 nm. Excitation and emission monochromator slit widths were set to 5 nm, respectively. Scan speed was 1500 nm/min.';

y = dataset(Y);
set(y,'name','Concentrations');
set(y,'author','Rasmus Bro');
set(y,'type','data');
y.label{1}=Names;
y.labelname{1} = 'Code';
y.label{2}=Ynames;
y.labelname{2} = 'Analyte';
y.axisscale{2}=[1e-6 1e-6 1e-6 1e-6];
y.axisscalename{2}='M';
y.title{1} = 'Sample';
y.title{2} = 'Concentration';
Y = y;

save dorrit EEM Y