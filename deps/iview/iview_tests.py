import unittest
import iview
import time

class IViewInterfaceTests(unittest.TestCase):

    def test_interface_writing(self):
        iview.interface = iview.IViewInterface(output_file='test.txt')
        iview.interface.start_recording()

        for i in range(1, 60):
            time.sleep(1)
            iview.interface.write_marker(42)

        iview.interface.stop_recording()
        time.sleep(1)