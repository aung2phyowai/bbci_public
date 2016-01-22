# -*- coding: utf-8 -*-
from iViewXAPI import *
import iViewXAPIReturnCodes
import os


SEND_IP_ADDRESS = '192.168.1.2'
SEND_PORT = 4444
RECEIVE_IP_ADDRESS = '192.168.1.1'
RECEIVE_PORT = 5555

interface = None

class FileWriter(object):

    def __init__(self, output_file):
        self.file = open(output_file, 'ab+')
        if not self.file.tell():
            self._write('TYPE, DATA (marker if M, [timestamp in microseconds, gaze_x, gaze_y] if G)')

    def _write(self, data):
        if not self.file.closed:
            self.file.writelines(data)

    def write_marker(self, marker):
        self._write('\r\nM, {0}'.format(marker))

    def write_gaze(self, timestamp, gaze_x, gaze_y):
        self._write('\r\nG, {0}, {1}, {2}'.format(timestamp, gaze_x, gaze_y))

    def close(self):
        self.file.close()


def check_iview_response(code):
    if code != 1:
        iViewXAPIReturnCodes.HandleError(code)


@WINFUNCTYPE(None, CSample)
def process_sample_data(sample):
    interface.iview_client._process_sample_data(sample)


class IViewClient(object):

    def __init__(self, sample_callback):
        self.sample_callback = sample_callback

    def connect(self):
        print "Connecting to iView"
        res = iViewXAPI.iV_Connect(c_char_p(SEND_IP_ADDRESS), c_int(SEND_PORT), c_char_p(RECEIVE_IP_ADDRESS), c_int(RECEIVE_PORT))
        check_iview_response(res)

        print "Subscribe sample callback"
        res = iViewXAPI.iV_SetSampleCallback(process_sample_data)
        check_iview_response(res)

    def disconnect(self):
        print "Disconnecting from iView"
        res = iViewXAPI.iV_Disconnect()
        check_iview_response(res)

    def _process_sample_data(self, sample):
        gaze_x = (sample.leftEye.gazeX + sample.rightEye.gazeX) / 2
        gaze_y = (sample.leftEye.gazeY + sample.rightEye.gazeY) / 2
        self.sample_callback(sample.timestamp, int(gaze_x), int(gaze_y))


class IViewInterface(object):

    file_writer = None
    output_file = None
    iview_client = None

    def __init__(self, output_file):
        self.output_file = output_file

    def start_recording(self):
        self.file_writer = FileWriter(self.output_file)
        self.iview_client = IViewClient(self.file_writer.write_gaze)
        self.iview_client.connect()

    def stop_recording(self):
        self.iview_client.disconnect()
        self.file_writer.close()

    def write_marker(self, marker):
        self.file_writer.write_marker(marker)


def create_filename_from_basename(basename):
    print 1
    ext = '.iview'
    filename = basename + ext

    if os.path.exists(filename):
        for counter in range(2, 100):
            filename = '{0}{1:0>2}{2}'.format(basename, counter, ext)
            if not os.path.exists(filename):
                return filename
    else:
        return filename
