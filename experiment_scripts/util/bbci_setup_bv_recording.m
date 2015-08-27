function [ bbci ] = bbci_setup_bv_recording( rec_name )
%BBCI_SETUP_BV_RECORDING Builds config struct for BV recording
global PROJECT_SETUP
global EXPERIMENT_CONFIG

exp_base_dir = fullfile(PROJECT_SETUP.BBCI_DATA_DIR,EXPERIMENT_CONFIG.VPcode_date);
mkdir(exp_base_dir)
full_rec_name = [EXPERIMENT_CONFIG.filePrefix rec_name,'_'];
dir = fullfile(exp_base_dir, full_rec_name);

bbci.source(1).record_basename = dir;
bbci.source(1).record_signals = true;
bbci.quit_condition.marker= EXPERIMENT_CONFIG.markers.trial_end;
bbci.quit_condition.running_time=inf;

bbci.source(1).acquire_fcn= @bbci_acquire_bv;
bbci.source(1).acquire_param= {'clab',{'*'}};
bbci.source(1).min_blocklength = 10;
bbci.source(1).record_signals = true;

bbci.signal(1).source = 1;
bbci.signal(1).proc = {@get_force};
bbci.signal(1).buffer_size = 10;

bbci.feature(1).signal = 1;
bbci.feature(1).ival = [-10 0];

C = struct('b', 0, 'w', ones(1,1));
bbci.classifier(1).feature = 1;
bbci.classifier(1).C = C;


bbci.control(1).classifier = 1;
bbci.control(1).fcn = @custom_control;

bbci.feedback(1).host = PROJECT_SETUP.UDP_FEEDBACK_HOST;
bbci.feedback(1).port = PROJECT_SETUP.UDP_FEEDBACK_PORT;
bbci.feedback(1).receiver = 'pyff';

end

