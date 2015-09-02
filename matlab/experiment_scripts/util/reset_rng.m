function [] = reset_rng(  )
%RESET_RNG Resets the RNG based on configuration (for reproducibility)

global EXPERIMENT_CONFIG

vpSeed = java.lang.Math.abs(java.lang.String(strcat(...
    EXPERIMENT_CONFIG.VPcode, EXPERIMENT_CONFIG.date)).hashCode());
rng(vpSeed)

end