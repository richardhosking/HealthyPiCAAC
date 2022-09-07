
Programming.md
 
A process for setting up to program the HealthyPi4 board to develop and modify code 
This was not simple - a fair number of steps need to be followed 

OS Linux Mint 20 ulyana

1. Download and Install the Arduino Integrated Development Environment (IDE) - I am using 1.8.19
2. Open the IDE -> Open File-> Preferences -> Additional Boards Manager-> 
Add the url https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json in the additional URL box 
Note that paste may not work - use Ctrl-V
3.  Obtain the HealthyPi Arduino code from Github here or 
Download the latest Arduino Library for HealthyPi v4 from the Protocentral site at 
https://healthypi.protocentral.com/
4. Open one of the example sketches -> Sketch -> Include Library -> Manage library -> Add zip library -> browse to where you have saved the Protocentral zip library -> Install
5. Open a sketch File -> Examples -> Protocentral HealthyPi v4 library -> Default BLE and Pi mode
6. Tools ->  board -> Boards Manager -> filter search to ESP32
7. "by Espressif Sytems" - note that the latest libraries will not work 
select version 1.0.6 and install
8. Select the relevant board Tools -> board -> ESP32 Arduino -> ESP32 Dev board
9. Select the partition scheme Minimal SPIFFS (1.9MB APP with OTA/190KB SPIFFS)
Other options should be default 
10. Select the relevant port after connecting via USB to the board 

11. Upload your sketch - if all is well you should get something like..
(If not fix the errors and start again :) )

Sketch uses 1511926 bytes (76%) of program storage space. Maximum is 1966080 bytes.
Global variables use 95728 bytes (29%) of dynamic memory, leaving 231952 bytes for local variables. Maximum is 327680 bytes.


esptool.py v3.0-dev
Serial port /dev/ttyUSB0
Connecting....
Chip is ESP32-D0WD-V3 (revision 3)
Features: WiFi, BT, Dual Core, 240MHz, VRef calibration in efuse, Coding Scheme None
Crystal is 40MHz
MAC: 10:52:1c:88:ca:94
Uploading stub...
Running stub...
Stub running...
Changing baud rate to 921600
Changed.
Configuring flash size...
Auto-detected Flash size: 4MB
Compressed 8192 bytes to 47...
Writing at 0x0000e000... (100 %)
Wrote 8192 bytes (47 compressed) at 0x0000e000 in 0.0 seconds (effective 4232.8 kbit/s)...
Hash of data verified.
Compressed 18656 bytes to 12053...
Writing at 0x00001000... (100 %)
Wrote 18656 bytes (12053 compressed) at 0x00001000 in 0.1 seconds (effective 1037.8 kbit/s)...
Hash of data verified.
Compressed 1512048 bytes to 912031...
Writing at 0x00010000... (1 %)
Writing at 0x00014000... (3 %)
Writing at 0x00018000... (5 %)
Writing at 0x0001c000... (7 %)
Writing at 0x00020000... (8 %)
Writing at 0x00024000... (10 %)
Writing at 0x00028000... (12 %)
Writing at 0x0002c000... (14 %)
Writing at 0x00030000... (16 %)
Writing at 0x00034000... (17 %)
Writing at 0x00038000... (19 %)
Writing at 0x0003c000... (21 %)
Writing at 0x00040000... (23 %)
Writing at 0x00044000... (25 %)
Writing at 0x00048000... (26 %)
Writing at 0x0004c000... (28 %)
Writing at 0x00050000... (30 %)
Writing at 0x00054000... (32 %)
Writing at 0x00058000... (33 %)
Writing at 0x0005c000... (35 %)
Writing at 0x00060000... (37 %)
Writing at 0x00064000... (39 %)
Writing at 0x00068000... (41 %)
Writing at 0x0006c000... (42 %)
Writing at 0x00070000... (44 %)
Writing at 0x00074000... (46 %)
Writing at 0x00078000... (48 %)
Writing at 0x0007c000... (50 %)
Writing at 0x00080000... (51 %)
Writing at 0x00084000... (53 %)
Writing at 0x00088000... (55 %)
Writing at 0x0008c000... (57 %)
Writing at 0x00090000... (58 %)
Writing at 0x00094000... (60 %)
Writing at 0x00098000... (62 %)
Writing at 0x0009c000... (64 %)
Writing at 0x000a0000... (66 %)
Writing at 0x000a4000... (67 %)
Writing at 0x000a8000... (69 %)
Writing at 0x000ac000... (71 %)
Writing at 0x000b0000... (73 %)
Writing at 0x000b4000... (75 %)
Writing at 0x000b8000... (76 %)
Writing at 0x000bc000... (78 %)
Writing at 0x000c0000... (80 %)
Writing at 0x000c4000... (82 %)
Writing at 0x000c8000... (83 %)
Writing at 0x000cc000... (85 %)
Writing at 0x000d0000... (87 %)
Writing at 0x000d4000... (89 %)
Writing at 0x000d8000... (91 %)
Writing at 0x000dc000... (92 %)
Writing at 0x000e0000... (94 %)
Writing at 0x000e4000... (96 %)
Writing at 0x000e8000... (98 %)
Writing at 0x000ec000... (100 %)
Wrote 1512048 bytes (912031 compressed) at 0x00010000 in 13.1 seconds (effective 926.5 kbit/s)...
Hash of data verified.
Compressed 3072 bytes to 129...
Writing at 0x00008000... (100 %)
Wrote 3072 bytes (129 compressed) at 0x00008000 in 0.0 seconds (effective 1535.5 kbit/s)...
Hash of data verified.

Leaving...
Hard resetting via RTS pin...

Check these links about mode switch and indications. https://healthypi.protocentral.com/getting-started.html
Check this link about BLE  https://healthypi.protocentral.com/HealthyPiv4_with_BLE.html
​
