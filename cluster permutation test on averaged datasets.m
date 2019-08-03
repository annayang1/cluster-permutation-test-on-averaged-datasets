% % author: finch
% % this script reads averaged EEG data(each subject in each condition)
% % and makes cluster-based permutation test

cd 'D:\average\';
close all
clear

save_path='D:\average\cluster';
id = 1:30;  % participants' ID
Ns = length(id);

%% read the averaged EEG data for each subjects and each condition
for i=1:Ns
    cfg = [];
    cfg.trialdef.eventtype = 'average'; % this is the important line
    cfg.dataset = strcat(num2str(i),'_A.avg'); 
    cfg = ft_definetrial(cfg);
    condA = ft_preprocessing(cfg);  
    condA2=ft_timelockanalysis([], condA);
    
    cfg = [];
    cfg.trialdef.eventtype = 'average';
    cfg.dataset = strcat(num2str(i),'_B.avg'); 
    cfg = ft_definetrial(cfg);
    condB = ft_preprocessing(cfg); 
    condB2=ft_timelockanalysis([], condB);
 
    save([save_path ,num2str(i), '_CleanData.mat'], 'condA2', 'condB2') 
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% compute erps and statistical analysis %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
clear
cd 'D:\average\cluster'
id = 1:30; 
Ns = length(id);

%%%%%%%%%%%%%%%%compute erp for each subject%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:Ns   
    load(strcat([num2str(i), '_CleanData.mat']));
 
    %%% compute subject-ERPs
    cfg = [];
    erpA = ft_timelockanalysis(cfg, condA2);
    erpB = ft_timelockanalysis(cfg, condB2);
   
    %%% plot subject-ERPs  
    cfg = [];
    cfg.layout = 'D:\NeuroScan_quickcap64_layout.lay';  % NeuroScan quickcap layout

    cfg.interactive = 'yes';
    cfg.showoutline = 'yes';
    cfg.xlim        = [-0.1 0.6];
    cfg.ylim        = [-10 10];
    figure; ft_multiplotER(cfg, erpA, erpB)
    
    save([save_path, num2str(i), '_erp.mat'], 'erpA', 'erpB')   
    clear  condA2 condB2 erpA erpB 
end

%%%%%%%%%%% prepare data for grand-avg and statistical test%%%%%%%%%%%%%%%%
close all
clear
cd 'D:\average\cluster'
id=1:30
Ns = length(id);
allsub_A = cell(1,Ns);   
allsub_B = cell(1,Ns);

for i=1:Ns    
    load(strcat([num2str(id(i)), '_erp.mat']));   
    allsub_A{1,i} = erpA;   
    allsub_B{1,i} = erpB;
end 

%% calculate grand average for each condition
cfg = [];
cfg.latency   = 'all';
cfg.parameter = 'avg';
cfg.channel   = 'all';
A_grand  = ft_timelockgrandaverage(cfg,allsub_A{:});  
B_grand  = ft_timelockgrandaverage(cfg,allsub_B{:});   
%%% plot waveform
cfg = [];
cfg.showlabels  = 'yes';
cfg.layout    	= 'D:\NeuroScan_quickcap64_layout.lay';  
cfg.xlim        = [-0.1 0.6];  
cfg.ylim        = [-10 10];      
figure; ft_multiplotER(cfg, A_grand, B_grand)   

%%% plot topography 
cfg = [];
cfg.operation = 'subtract';
cfg.parameter = 'avg';
A_vs_B   = ft_math(cfg,A_grand, B_grand); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%  non-parametric cluster-based permutation test  %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% prepare neighbors
cfg = [];
cfg.method      = 'template';
cfg.template    = 'D:\NeuroScan_quickcap64_neighbours.mat';    
cfg.layout      = 'D:\NeuroScan_quickcap64_layout.lay';                  
cfg.feedback    = 'no';                                 
neighbours      = ft_prepare_neighbours(cfg,A_vs_B);   

%%% cluster-based permutation
cfg = [];
cfg.channel          = {'all'};
cfg.latency          = [0 0.6];    
cfg.avgovertime = 'no';
cfg.method           = 'montecarlo';   
cfg.statistic        = 'depsamplesT';   
cfg.correctm         = 'cluster';      
cfg.clusteralpha     = 0.05         
cfg.clustertail      = 1;               
cfg.clusterstatistic = 'maxsum';        
cfg.neighbours       = neighbours;      
cfg.tail             = 1;               
cfg.alpha            = 0.05;           
cfg.numrandomization = 1000;            
cfg.minnbchan = 2;
cfg.design(1,1:2*Ns)  = [ones(1,Ns) 2*ones(1,Ns)];
cfg.design(2,1:2*Ns)  = [1:Ns 1:Ns];
cfg.ivar              = 1; 
cfg.uvar              = 2; 

stat = ft_timelockstatistics(cfg,allsub_A{:},allsub_B{:});
save('ERP_result.mat','stat');
