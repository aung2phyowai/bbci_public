#!/usr/bin/python
"""calculates dense or sparse optical flow for sequence files"""
import argparse
import numpy as np
import cv2
import sys
import os

#import utils from feedback folder, so we need to add it to the path
feedback_path = os.path.normpath(os.path.join(os.path.dirname(__file__), "../feedbacks"))
sys.path.append(feedback_path)
import vco_utils

parser = argparse.ArgumentParser(description='calculate optical flow for sequence files')
#parser.add_argument('seqFiles', nargs='*', default=[ '~/local_data/kitti/seqs/seq_s03_1-hardtwaldb.txt'])
parser.add_argument('seqFiles', nargs='+')
parser.add_argument('-d', '--display', action='store_true')
parser.add_argument('-m', '--method', choices=['sparse', 'dense'], default='sparse',
                    help='type of flow calculation: sparse (Lucas-Kanade) or dense (Farneback)')

args = parser.parse_args()

#args.method = 'dense'

for seqFile in args.seqFiles:

    seqInfo = vco_utils.load_seq_file(seqFile)
    files = [f for f, markers in seqInfo]

    #remove first and last 10 frame (fading)
    files = files[10:-10]

    # params for ShiTomasi corner detection
    feature_params = dict(maxCorners=100,
                          qualityLevel=0.3,
                          minDistance=7,
                          blockSize=7)

    # Parameters for lucas kanade optical flow
    lk_params = dict(winSize=(15, 15),
                     maxLevel=2,
                     criteria=(cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 0.03))
    # parameters for farneback optical flow
    fb_params = dict(pyr_scale=0.5,
                     levels=3,
                     winsize=15,
                     iterations=2,
                     poly_n=5,
                     poly_sigma=1.1,
                     flags=0)

    # Create some random colors
    color = np.random.randint(0, 255, (100, 3))

    # Take first frame and find corners in it
    old_frame = cv2.imread(files[0])
    old_gray = cv2.cvtColor(old_frame, cv2.COLOR_RGB2GRAY)
    p0 = cv2.goodFeaturesToTrack(old_gray, mask=None, **feature_params)

    # Create a mask image for drawing purposes
    mask = np.zeros_like(old_frame)

    flowNorms = []

    #we don't need the first one
    for i, frameFile in enumerate(files[1:]):
        frame = cv2.imread(frameFile)
        frame_gray = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)

        # calculate optical flow
        try:
            if args.method == 'sparse':
                p1, st, err = cv2.calcOpticalFlowPyrLK(old_gray, frame_gray, p0, None, **lk_params)
                # Select good points
                good_new = p1[st == 1]
                good_old = p0[st == 1]

                flow = good_new.reshape(-1, 2) - good_old.reshape(-1, 2)        
                #flowVectorNorms = [np.linalg.norm(flow[i]) for i in xrange(flow.shape[0])]
                flowVectorNorms = np.linalg.norm(flow, axis=1)
                meanFlowVectorNorm = np.mean(flowVectorNorms)
               
            else:
                flow = cv2.calcOpticalFlowFarneback(old_gray, frame_gray, **fb_params)
                #reshape, so we have rows of vectors
                flow = np.reshape(flow, (-1, 2))
                
               # flowVectorNorms =  [np.linalg.norm(flow[i]) for i in xrange(flow.shape[0])]
                flowVectorNorms = np.linalg.norm(flow, axis=1)
                        
                meanFlowVectorNorm = np.mean(flowVectorNorms)
        except:
            print("error calculating between frames %d and %d with shapes %s and %s" %
                  ((i-1), i, old_gray.shape, frame_gray.shape))
        else:
         
            flowNorms.append(meanFlowVectorNorm)
            if args.display:
                print("norm of flow %1.2f" % meanFlowVectorNorm)
                mask = np.zeros_like(frame)
                # draw the tracks
                for i, (new, old) in enumerate(zip(good_new, good_old)):
                    a, b = new.ravel()
                    c, d = old.ravel()
                    cv2.line(mask, (a, b), (c, d), color[i].tolist(), 2)
                    cv2.circle(frame, (a, b), 5, color[i].tolist(), -1)
                img = cv2.add(frame, mask)

                cv2.imshow('frame', img)
                k = cv2.waitKey(200) & 0xff
                if k == 27:
                    break

        # Now update the previous frame and previous points
        old_gray = frame_gray.copy()
        #p0 = good_new.reshape(-1,1,2)
        p0 = cv2.goodFeaturesToTrack(old_gray, mask=None, **feature_params)

    print('%s mean flow norm %1.6f' % (seqFile, (sum(flowNorms) / len(flowNorms))))
if args.display:
    cv2.destroyAllWindows()
