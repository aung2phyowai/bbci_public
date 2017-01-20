function [clab, idx]= gridutil_getClabOfGrid(mnt)
%GETCLABOFGRID - Channel names of channels Visible in the grid of a montage
%
%Synopsis:
%  [CLAB, IDX]= gridutil_getClabOfGrid(MNT)
%
%Arguments:
%  MNT - structure defining EEG montage and plot layout, 
%        see mnt_setElectrodePositions and mnt_setGrid
%
%Returns:
%  CLAB - [CELL{CHAR}] labels of channels that are included in the grid layout
%  idx  - indices (relative to MNT.clab) of those channels

if isfield(mnt, 'box'),
  idx= find(~isnan(mnt.box(1,:)));
  % remove index of legend:
  idx(find(idx>length(mnt.clab)))= [];
  clab= mnt.clab(idx);
else
  clab= mnt.clab;
  % workaround for non-assigned variable, did not check whether it actually
  % makes sense (at least second return value is not used by grid_plot if
  % mnt.box doesn't exist)
  % use nan to make crash likely in case it is actually used
  idx = nan;
end
