clear all;close all

OS = 'linux';

disp('-------------------------------')

%%%Setup variables
localPath = '/home/jose/Codes/Unpacker/Matlab/'
cd([localPath])

%%Setup run number

run = 113,%Automatic mode
trbNumber = '099'


%%%Load run and setup variables
%loadRun;
TRBs = {[899],[1]};

linuxPathIn         = [localPath 'hlds/trb' trbNumber '/'];
pathTmp             = [localPath 'tmp/'];%Used to create tmp files
pathOut             = [localPath 'hlds/trb' trbNumber '/mat/'];
pathOutDat          = [localPath 'hlds/trb' trbNumber '/dat/'];

errorFlag           = 0;
    
mkdir(pathOut);mkdir(pathOutDat);

    



%%%Go to read files
s = dir([linuxPathIn '*.hld'])

for i=1:length(s)
    
fileName = s(i).name
    
%%%Setup Variables
    
unpackerBuffer      = 5000000;
disp('  ')

unpackerTRBs(fileName,unpackerBuffer,linuxPathIn,pathOut,1,{0,'R:\inlpar\INLPar.mat'},TRBs);

ss = dir([pathOut  fileName(1:end-4) '*.mat'])
for j=1:length(ss)
    load([pathOut ss(j).name])    
    fid=fopen([pathOutDat fileName '.dat'],'w');
    if fid == (-1)
        error(['rdf: Could not open file:' pathIn filename]);
    end

    mExt = [dataLeadings dataTrailings];
    fprintf(fid,'%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n', full(mExt'));
    
end
end
