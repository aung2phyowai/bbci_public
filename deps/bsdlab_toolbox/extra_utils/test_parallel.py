from ctypes import windll
import time

"""
This script test the parallel port sending markers from 1:2^n:2^8
Set the id_port according to the machine you are working with
"""
id_port = 0xD050 # Address of the parallel port in the audio-lab PC

pport = windll.inpout32
for i in xrange(9):
    pport.Out32(id_port,2**i-1)
    time.sleep(0.5)
