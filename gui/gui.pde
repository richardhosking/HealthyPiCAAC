//////////////////////////////////////////////////////////////////////////////////////////
//
//   Raspberry Pi/ Desktop GUI for displaying data from the HealthyPi HAT v4
//   Can be used in Linux desktop also 
//
//   Copyright (c) 2016 ProtoCentral
//   modified by Richard Hosking 
//   richardh@iinet.net.au
//
//   Language: Java using Processing Framework on host computer
//   Processing is a "cut down" Java IDE which hides much of the implementation 
//   like the Arduino IDE simplifies C++ coding 
//   
//   Dependent libraries:
//     * ControlP5
//     * Grafica
//
//   This software is licensed under the MIT License(http://opensource.org/licenses/MIT). 
//   
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
//   NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
//   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
//   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
/////////////////////////////////////////////////////////////////////////////////////////

import processing.serial.*;                  // Serial Library
import grafica.*;

// Java Swing Package For prompting message
import java.awt.*;
import javax.swing.*;
import static javax.swing.JOptionPane.*;

// File Packages to record the data into a text file
import javax.swing.JFileChooser;
import java.io.FileWriter;
import java.io.BufferedWriter;

// Date Format
import java.util.*;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

// General Java Package
import java.math.*;
import controlP5.*;

// Instances 
ControlP5 cp5;

Textlabel  lblSerial;
Textlabel lblHR;
Textlabel lblSPO2;
Textlabel lblRR;
Textlabel lblBP;
Textlabel lblTemp;
Textlabel lblMQTT;
Textlabel lblMQTTStatus;
Textlabel lblRecordStatus;

Toggle tglRecord;

Accordion accordion;

// Variables 
/************** Packet Validation  **********************/
private static final int CESState_Init = 0;
private static final int CESState_SOF1_Found = 1;
private static final int CESState_SOF2_Found = 2;
private static final int CESState_PktLen_Found = 3;

/*CES CMD IF Packet Format*/
private static final int CES_CMDIF_PKT_START_1 = 0x0A;
private static final int CES_CMDIF_PKT_START_2 = 0xFA;
private static final int CES_CMDIF_PKT_STOP = 0x0B;

/*CES CMD IF Packet Indices*/
private static final int CES_CMDIF_IND_LEN = 2;
private static final int CES_CMDIF_IND_LEN_MSB = 3;
private static final int CES_CMDIF_IND_PKTTYPE = 4;
private static int CES_CMDIF_PKT_OVERHEAD = 5;

/************** Packet Related Variables **********************/

int ecs_rx_state = 0;                                        // To check the state of the packet
int CES_Pkt_Len;                                             // To store the Packet Length Details
int CES_Pkt_Pos_Counter, CES_Data_Counter;                   // Packet and data counter
int CES_Pkt_PktType;                                         // To store the Packet Type
char CES_Pkt_Data_Counter[] = new char[1000];                // Buffer to store the data from the packet
char CES_Pkt_ECG_Counter[] = new char[4];                    // Buffer to hold ECG data
char CES_Pkt_Resp_Counter[] = new char[4];                   // Respiration Buffer
char CES_Pkt_SpO2_Counter_RED[] = new char[4];               // Buffer for SpO2 RED
char CES_Pkt_SpO2_Counter_IR[] = new char[4];                // Buffer for SpO2 IR
int pSize = 1000;                                            // Total Size of the buffer
int arrayIndex = 0;                                          // Increment Variable for the buffer
float time = 0;                                              // X axis increment variable

// Buffer for ecg,spo2,respiration,and average of thos values
float[] xdata = new float[pSize];
float[] ecgdata = new float[pSize];
float[] respdata = new float[pSize];
float[] bpmArray = new float[pSize];
float[] ecg_avg = new float[pSize];                          
float[] resp_avg = new float[pSize];
float[] spo2data = new float[pSize];
float[] spo2Array_IR = new float[pSize];
float[] spo2Array_RED = new float[pSize];
float[] rpmArray = new float[pSize];
float[] ppgArray = new float[pSize];

/************** Graph Related Variables **********************/

double maxe, mine, maxr, minr, maxs, mins;             // To Calculate the Minimum and Maximum of the Buffer
double ecg, resp, spo2_ir, spo2_red, spo2, redAvg, irAvg, ecgAvg, resAvg;  // To store the current ecg value
double respirationVoltage=20;                          // To store the current respiration value
boolean startPlot = false;                             // Conditional Variable to start and stop the plot

// Class instances GPlot - class in grafica which controls other elements of the plot  
GPlot plotPPG;
GPlot plotECG;
GPlot plotResp;

int step = 0;
int stepsPerCycle = 100;
int lastStepTime = 0;
boolean clockwise = true;
float scale = 5;

/************** File Related Variables **********************/

boolean logging = false;                                // Variable to check whether to record the data or not
FileWriter output;                                      // In-built writer class object to write the data to file
JFileChooser jFileChooser;                              // Helps to choose particular folder to save the file
Date date;                                              // Variables to record the date related values                              
BufferedWriter bufferedWriter;
DateFormat dateFormat;

/************** Port Related Variables **********************/

Serial port = null;                                     // Oject for communicating via serial port
String[] portList;                                      // Array to hold available serial ports  
char inString = '\0';                                   // To receive the bytes from the packet
String selectedPort;                                    // Holds the selected port number
String globalPortName="/dev/ttyUSB0";
boolean portOpened = false;
int baud = 115200;

/************** Logo Related Variables **********************/
// Logo to display top Toolbar
// jpg image in /data
PImage pcLogo;

boolean gStatus;                                        // Boolean variable to save the grid visibility status

int nPoints1 = pSize;
int totalPlotsHeight=0;
int totalPlotsWidth=0;
int heightHeader=100;
int updateCounter=0;

boolean is_raspberrypi=false;

int global_hr;
int global_rr;
float global_temp;
int global_spo2;

int global_test=0;

boolean ECG_leadOff,spo2_leadOff;
boolean ShowWarning = true;
boolean ShowWarningSpo2=true;



String strRecordStatus="Not Recording";



public void setup() 
{
    // Display size - needs to be at top of sketch 
    size(1000, 960, JAVA2D); //<>//
    // or make display full size
    //fullScreen();
    
    // Find available serial ports 
    portList = Serial.list(); //<>//
        
    // try the various serial ports
    for (int i = 0; i < portList.length; i++) //<>//
    {
        // On my Linux machine /dev/ttyUSB*
        if (portList[i].contains("USB")) //<>//
        {
            portOpened = startSerial(portList[i],baud);
            selectedPort = portList[i];
            println(selectedPort, "  opened");
            break;
        }
        else
        {
            println(portList[i], "  not available");
        }
 
    }

    println(System.getProperty("os.name")); //<>//
    println(System.getProperty("os.arch"));
    
    GPointsArray pointsPPG = new GPointsArray(nPoints1);
    GPointsArray pointsECG = new GPointsArray(nPoints1);
    GPointsArray pointsResp = new GPointsArray(nPoints1);
  
    
     
    heightHeader=100;
    println("Height:"+height);
    totalPlotsHeight=height-heightHeader;
    
    pcLogo = loadImage("caac.jpg"); //<>//
    
    makeGUI();
    
    plotECG = new GPlot(this);
    plotECG.setPos(0,50);
    plotECG.setDim(width-200, (totalPlotsHeight/3)-10);
    plotECG.setBgColor(0);
    plotECG.setBoxBgColor(0);
    plotECG.setLineColor(color(0, 255, 0));
    plotECG.setLineWidth(3);
    plotECG.setMar(0,0,0,0);
    
    plotPPG = new GPlot(this);
    plotPPG.setPos(0,(totalPlotsHeight/3+60));
    plotPPG.setDim(width-200, (totalPlotsHeight/3)-10);
    plotPPG.setBgColor(0);
    plotPPG.setBoxBgColor(0);
    plotPPG.setLineColor(color(255, 255, 0));
    plotPPG.setLineWidth(3);
    plotPPG.setMar(0,0,0,0);
  
    plotResp = new GPlot(this);
    plotResp.setPos(0,(totalPlotsHeight/3+totalPlotsHeight/3+70));
    plotResp.setDim(width-200, (totalPlotsHeight/3)-10);
    plotResp.setBgColor(0);
    plotResp.setBoxBgColor(0);
    plotResp.setLineColor(color(0,0,255));
    plotResp.setLineWidth(3);
    plotResp.setMar(0,0,0,0);
  
    for (int i = 0; i < nPoints1; i++) 
    {
      pointsPPG.add(i,0);
      pointsECG.add(i,0);
      pointsResp.add(i,0); 
    }
  
    plotECG.setPoints(pointsECG);
    plotPPG.setPoints(pointsPPG);
    plotResp.setPoints(pointsPPG);
  
    for (int i=0; i<pSize; i++) 
    {
      time = time + 1;
      xdata[i]=time;
      ecgdata[i] = 0;
      respdata[i] = 0;
      ppgArray[i] = 0;
    }
    time = 0;
    

    
    checkForExternalStorage();
    
}

public void draw() 
{
    background(0);
    fill(19,88,113);
    rect(0, 0, width, 55);
    image(pcLogo, 0, 0);
  
    GPointsArray pointsPPG = new GPointsArray(nPoints1);
    GPointsArray pointsECG = new GPointsArray(nPoints1);
    GPointsArray pointsResp = new GPointsArray(nPoints1);
  
    if (startPlot)                             
    {
      for(int i=0; i<nPoints1;i++)
      {    
        pointsECG.add(i,ecgdata[i]);
        pointsPPG.add(i,spo2data[i]); 
        pointsResp.add(i,respdata[i]);
        
      }
    } 
    
    plotECG.setPoints(pointsECG);
    plotPPG.setPoints(pointsPPG);
    plotResp.setPoints(pointsResp);
    
    plotECG.beginDraw();
    plotECG.drawBackground();
    plotECG.drawLines();
    plotECG.endDraw();
    
    plotPPG.beginDraw();
    plotPPG.drawBackground();
    plotPPG.drawLines();
    plotPPG.endDraw();
  
    plotResp.beginDraw();
    plotResp.drawBackground();
    plotResp.drawLines();
    plotResp.endDraw();
}

// Main display window 
public void makeGUI()
{  
   cp5 = new ControlP5(this);
   
   cp5.addButton("Exit") //<>//
     //setValue(0)
     .setColorBackground(color(255,255,255)) //<>//
     .setColorLabel(color(0)) //<>//
     .setPosition(width-110,5) //<>//
     .setSize(90,40) //<>//
     .setFont(createFont("verdana",16)); //<>//

    tglRecord = cp5.addToggle("record")
     .setPosition(width-225,5)
     //.setLabel("Record Data")
     .setLabelVisible(true)
     .setSize(90,20)
     .setFont(createFont("verdana",10))
     .setValue(false)
     .setColorBackground(color(255,255,255))
     .setColorLabel(color(255,255,255))
     .setMode(ControlP5.SWITCH);
                 

           
       lblHR = cp5.addTextlabel("lblHR")
      .setText("HR--- bpm")
      .setPosition(width-250,100)
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",40));
      
      lblSPO2 = cp5.addTextlabel("lblSPO2")
      .setText("SpO2 --- %")
      .setPosition(width-250,(totalPlotsHeight/3+60))
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",40));
 
      lblRR = cp5.addTextlabel("lblRR")
      .setText("Resp --- pm")
      .setPosition(width-250,(totalPlotsHeight/3+totalPlotsHeight/3+60))
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",40));
    
      lblTemp = cp5.addTextlabel("lblTemp")
      .setText("Temp: --- C")
      .setPosition(width-300,height-60)
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",40));
      
       lblSerial = cp5.addTextlabel("lblSerial")
      .setText("Serial port " +selectedPort)
      .setPosition(10, height-50)
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",14));
            
      lblRecordStatus = cp5.addTextlabel("lblRecordStatus")
      .setText("Record status: " + strRecordStatus)
      .setPosition(10,height-25)
      .setColorValue(color(255,255,255))
      .setFont(createFont("verdana",14));
          
    if(height<=480) //condition for Raspberry Pi 7" display
    {  
        lblHR.setFont(createFont("verdana",20));
        lblHR.setPosition(width-200,5+heightHeader);      
        
        lblSPO2.setFont(createFont("verdana",20));
        lblSPO2.setPosition(width-200,(totalPlotsHeight/3+heightHeader));
      
        lblTemp.setPosition((width/3)*2,height-25)
        .setFont(createFont("verdana",20));
        
        lblRR.setPosition(width-200,(totalPlotsHeight/3+totalPlotsHeight/3+10+heightHeader))
        .setFont(createFont("verdana",20));
       
    }
}



void record(boolean theFlag) {
  if(theFlag==true) {
   print("Recording started");
   RecordData();
  } else {
    if(logging==true)
    {
     print("Stop record");
     StopRecord();
    }
  }
  //println("a toggle event.");
}

public void Exit() 
{
  int dialogResult = JOptionPane.showConfirmDialog (null, "Would You Like to Close The Application?");
  if (dialogResult == JOptionPane.YES_OPTION) {
    try
    {
      //Runtime runtime = Runtime.getRuntime();
      //Process proc = runtime.exec("sudo shutdown -h now");
      System.exit(0);
    }
    catch(Exception e)
    {
      exit();
    }
  } else
  {
  }
}


public void StopRecord()
{
  //Stop logging
  //if(logging==true)
  //{
    logging=false;
     setRecordStatus("Stopped Recording");
  
  //Close file
  try
  {
    bufferedWriter.close();
    output.close();
    
    println("Closed all files");
  }
  catch(Exception e)
  {
    println(e);
  }
  //}
}

String globalSelectedPath;

public void setRecordStatus(String RecordStatus)
{
    lblRecordStatus.setText("Status: "+ RecordStatus);
}

public void checkForExternalStorage()
{
  String storagePath;

    
      storagePath="/media/pi/";
      File[] usbFiles = listFiles(storagePath);
      //print(str(usbFiles.length));
      //print(usbFiles[0]);
      if(usbFiles!=null)
      {
      if(usbFiles.length<=0)
        {
          setRecordStatus("No storage device found. Not recording data");
          
        }
        else
        {
          RecordData();
        }   
      }
      else {
        setRecordStatus("No storage device found. Not recording data");
      }
        
}
public void RecordData()
{
    String storagePath;
  
    if(logging==false)
    {
      //Check if Raspberry Pi
      if(System.getProperty("os.arch").contains("arm"))
      {
        storagePath="/media/pi/";
        File[] usbFiles = listFiles(storagePath);
        print(str(usbFiles.length));
        //print(usbFiles[0]);
        if(usbFiles.length<=0)
          {
            //JFrame f = new JFrame();
            //JOptionPane.showMessageDialog(f,"No storage device found!","No device",JOptionPane.WARNING_MESSAGE);
            setRecordStatus("No storage device found. Not recording data");
          }
          else
          {
            storagePath=usbFiles[0].getPath();
            
            try
            {
              if(port!=null)
                port.stop();
              //USB storage present
              //jFileChooser = new JFileChooser(storagePath);
              long currentTime=System.currentTimeMillis();
              String filename = currentTime + ".csv";
              //jFileChooser.setSelectedFile(new File(filename));
              //jFileChooser.showSaveDialog(null);
              //String filePath = jFileChooser.getSelectedFile()+"";
              
              logging = true;
              date = new Date();
              //output = new FileWriter(jFileChooser.getSelectedFile(), true);
              output = new FileWriter(storagePath+"/"+filename, true);
              setRecordStatus("Recording to "+filename);
              bufferedWriter = new BufferedWriter(output);
              bufferedWriter.write("Log started at: " + date.toString()+"");
              bufferedWriter.newLine();
              //bufferedWriter.write("TimeStamp,ECG,SpO2,Respiration");
              bufferedWriter.write("Sampling rate for all signals: 125 Hz");
              bufferedWriter.newLine();
              bufferedWriter.write("Format: ECG, PPG, Respiration, Temperature, Heartrate, SpO2, Respiration Rate");
              bufferedWriter.newLine();
              startSerial("/dev/ttyAMA0",115200);
            }
            catch(Exception e)
            {
              println(e);
            }
        
          }
          
      } else 
      {
        //Not Raspberry Pi
        try
        {
          selectFolder("Select a folder to save log files", "folderSelected");
        }
        catch(Exception e)
        {
          println(e);
        }
      
      }  
    }
}

void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    try
    {
      globalSelectedPath= selection.getAbsolutePath();
      println("User selected " + selection.getAbsolutePath());
      
      long currentTime=System.currentTimeMillis();
      String filename = currentTime + ".csv";
      
      if(port!=null)
        port.stop();
      
      logging = true;
      date = new Date();
      output = new FileWriter(globalSelectedPath+"/"+filename, true);
      setRecordStatus("Recording to "+ globalSelectedPath + "/" + filename);
      bufferedWriter = new BufferedWriter(output);
      bufferedWriter.write("Log started at: " + date.toString()+"");
      bufferedWriter.newLine();
      bufferedWriter.write("Sampling rate for all signals: 125 Hz");
      bufferedWriter.newLine();
      bufferedWriter.write("Format: ECG, PPG, Respiration, Temperature, Heartrate, SpO2, Respiration Rate");
      bufferedWriter.newLine();
      
     }
    catch(Exception e)
    {
      println(e);
    }
  }
}

// Open the serial port specified 
boolean startSerial(String startPortName, int baud)
{
  try
  {
      port = new Serial(this,startPortName, baud);
      port.clear();
      startPlot = true;
      return true;
  }
  catch(Exception e)
  {

    showMessageDialog(null, "Port is invalid or busy", "Alert", ERROR_MESSAGE);
    //System.exit (0);
    return false;
  }
}


void serialEvent (Serial blePort) 
{
  try
  {
      inString = blePort.readChar();
      ecsProcessData(inString);
  }
  catch(Exception e)
  {

    //showMessageDialog(null, "Failed in serial Event function", "Alert", ERROR_MESSAGE);
    //System.exit (0);
    
  }
  
}

/*** Main function to process packet data
 *  Packet structure 
 *  8 bit bytes 
 *  0 Start 0x0A
 *  1 Start 0xFA
 *  2 datalength LSB
 *  3 datalength MSB
 *  4 0x02
 *  These 4 bytes are 0x00 if lead off detected
 *  5 ECG LSB
 *  6 ECG MSB
 *  7 Resp LSB
 *  8 Resp MSB
 *  9-12 Oximeter IR data LSB first
 *  13-16 0ximeter Red data LSB first 
 *  Temp - Deg C in hundredths of a degree
 *  17 Temperature LSB
 *  18 Temperature MSB
 *  19 Resp rate
 *  20 spO2
 *  21 Heartrate
 *  22 BP diastolic - not implemented = 80
 *  23 BP Systolic - not implemented
 *  24 spO2 probe status
 *  25 Stop 0x00
 *  26 Stop 0x0B 
*/ 

void ecsProcessData(char rxch)
{
  //println("Inside ecsProcessData"); 
  switch(ecs_rx_state)
  {
  case CESState_Init:                               // If packet is not initialized 
    if (rxch==CES_CMDIF_PKT_START_1)                // Look for start byte   
    {
        ecs_rx_state=CESState_SOF1_Found;
        //println("Start byte found");
    }
    break;
  case CESState_SOF1_Found:                       // If start byte has been found look for start_2 byte        
    if (rxch==CES_CMDIF_PKT_START_2)
    {
        ecs_rx_state=CESState_SOF2_Found;        // Packet state both start bytes found
        //println("Second start byte found");
    }
    else
      ecs_rx_state=CESState_Init;              //Invalid Packet, reset state to init            
    break;

  case CESState_SOF2_Found:
    // Packet length data
    ecs_rx_state = CESState_PktLen_Found;
    CES_Pkt_Len = (int) rxch;
    CES_Pkt_Pos_Counter = CES_CMDIF_IND_LEN;
    CES_Data_Counter = 0;
    //println("Packet length ",CES_Pkt_Len, " bytes");    
    break;

  case CESState_PktLen_Found:
    //  actual packet data 
    CES_Pkt_Pos_Counter++;
    //println("Actual data byte ",CES_Pkt_Pos_Counter, " ",(int)rxch );
    if (CES_Pkt_Pos_Counter < CES_CMDIF_PKT_OVERHEAD)  //Read Header
    {
      if (CES_Pkt_Pos_Counter==CES_CMDIF_IND_LEN_MSB)
        CES_Pkt_Len = (int) ((rxch<<8)|CES_Pkt_Len);
      else if (CES_Pkt_Pos_Counter==CES_CMDIF_IND_PKTTYPE)
        CES_Pkt_PktType = (int) rxch;
    } else if ( (CES_Pkt_Pos_Counter >= CES_CMDIF_PKT_OVERHEAD) && (CES_Pkt_Pos_Counter < CES_CMDIF_PKT_OVERHEAD+CES_Pkt_Len+1) )  //Read Data
    {
      if (CES_Pkt_PktType == 2)
      {
        CES_Pkt_Data_Counter[CES_Data_Counter++] = (char) (rxch);          // Buffer that assigns the data separated from the packet
      }
    } else  //All  and data received
    {
      if (rxch==CES_CMDIF_PKT_STOP)
      {     
        CES_Pkt_ECG_Counter[0] = CES_Pkt_Data_Counter[0];
        CES_Pkt_ECG_Counter[1] = CES_Pkt_Data_Counter[1];


        CES_Pkt_Resp_Counter[0] = CES_Pkt_Data_Counter[2];
        CES_Pkt_Resp_Counter[1] = CES_Pkt_Data_Counter[3];

        CES_Pkt_SpO2_Counter_IR[0] = CES_Pkt_Data_Counter[4];
        CES_Pkt_SpO2_Counter_IR[1] = CES_Pkt_Data_Counter[5];
        CES_Pkt_SpO2_Counter_IR[2] = CES_Pkt_Data_Counter[6];
        CES_Pkt_SpO2_Counter_IR[3] = CES_Pkt_Data_Counter[7];

        CES_Pkt_SpO2_Counter_RED[0] = CES_Pkt_Data_Counter[8];
        CES_Pkt_SpO2_Counter_RED[1] = CES_Pkt_Data_Counter[9];
        CES_Pkt_SpO2_Counter_RED[2] = CES_Pkt_Data_Counter[10];
        CES_Pkt_SpO2_Counter_RED[3] = CES_Pkt_Data_Counter[11];

        float Temp_Value = (float) (CES_Pkt_Data_Counter[12]| CES_Pkt_Data_Counter[13]<<8)/100;  // Temperature
        
        // BP Value Systolic and Diastolic not implemented at present
        // Placeholders 120/80
        
        int global_RespirationRate = (int) (CES_Pkt_Data_Counter[14]);
        int global_spo2= (int) (CES_Pkt_Data_Counter[15]);
        int global_HeartRate = (int) (CES_Pkt_Data_Counter[16]);
         
        int BP_Value_Sys = (int) CES_Pkt_Data_Counter[17];
        int BP_Value_Dia = (int) CES_Pkt_Data_Counter[18];
        
        int leadstatus =  CES_Pkt_Data_Counter[19];
        leadstatus &= 0x01; 
        if(leadstatus== 0x01) ECG_leadOff = true;  
        else ECG_leadOff = false;
        
        leadstatus =  CES_Pkt_Data_Counter[19];
        leadstatus &= 0x02; 
        if(leadstatus == 0x02) spo2_leadOff = true;
        else spo2_leadOff = false;
        

        int data1 = CES_Pkt_ECG_Counter[0] | CES_Pkt_ECG_Counter[1]<<8; //reversePacket(CES_Pkt_ECG_Counter, CES_Pkt_ECG_Counter.length-1);
        data1 <<= 16;
        data1 >>= 16;
        ecg = (double) data1/(Math.pow(10, 3));

        int data2 = CES_Pkt_Resp_Counter[0] | CES_Pkt_Resp_Counter[1] <<8; //reversePacket(CES_Pkt_ECG_Counter, CES_Pkt_ECG_Counter.length-1);
        data2 <<= 16;
        data2 >>= 16;
        resp = (double) data2/(Math.pow(10, 3));

        int data3 = reversePacket(CES_Pkt_SpO2_Counter_IR, CES_Pkt_SpO2_Counter_IR.length-1);
        spo2_ir = (double) data3;

        int data4 = reversePacket(CES_Pkt_SpO2_Counter_RED, CES_Pkt_SpO2_Counter_RED.length-1);
        spo2_red = (double) data4;

        ecg_avg[arrayIndex] = (float)ecg;
        ecgAvg = averageValue(ecg_avg);
        ecg = (ecg_avg[arrayIndex] - ecgAvg);

        spo2Array_IR[arrayIndex] = (float)spo2_ir;
        spo2Array_RED[arrayIndex] = (float)spo2_red;
        redAvg = averageValue(spo2Array_RED);
        irAvg = averageValue(spo2Array_IR);
        spo2 = (spo2Array_IR[arrayIndex] - irAvg);

        resp_avg[arrayIndex]= (float)resp;
        resAvg =  averageValue(resp_avg);
        resp = (resp_avg[arrayIndex] - resAvg);

        time = time+1;
        xdata[arrayIndex] = time;

        ecgdata[arrayIndex] = (float)ecg;
        respdata[arrayIndex]= (float)resp;
        spo2data[arrayIndex] = (float)spo2;
        bpmArray[arrayIndex] = (float)ecg;
        rpmArray[arrayIndex] = (float)resp;
        ppgArray[arrayIndex] = (float)spo2;

        if(ECG_leadOff == true)
        {
           if(ShowWarning == true)
           {
             lblHR.setColorValue(color(255,0,0));
             lblRR.setColorValue(color(255,0,0));
             lblHR.setText("LEAD ERROR");
             lblRR.setText("LEAD ERROR");
             ShowWarning = false;
           }
        }
        else 
        {
          if(ShowWarning == false)
          {
             lblHR.setColorValue(color(255,255,255));
             lblRR.setColorValue(color(255,255,255));
             ShowWarning = true;
          }
          lblRR.setText("Resp " + global_RespirationRate+ " pm");
          lblHR.setText("HR " + global_HeartRate + " bpm");          
        }
        
        if(spo2_leadOff == true)
        {
          if(ShowWarningSpo2 == true)
           {
             lblSPO2.setColorValue(color(255,0,0));
             lblSPO2.setText("SpO2 Probe Error");
             ShowWarningSpo2 = false;
           }
        }
        else 
        {
           if(ShowWarningSpo2 == false)
            {
               lblSPO2.setColorValue(color(255,255,255));
               ShowWarningSpo2 = true;
            }
           lblSPO2.setText("SpO2 " + global_spo2 + "%");
        }
       
        arrayIndex++;
        updateCounter++;

        if(updateCounter==100)
        {
          if (startPlot)
          {
            global_temp=Temp_Value;
            lblTemp.setText("Temp "+Temp_Value+" C");
            
          }
          updateCounter=0;
        }
        
        if (arrayIndex == pSize)
        {  
          arrayIndex = 0;
          time = 0;
        }       

        if (logging == true)
        {
          try 
          {
            //date = new Date();
            //dateFormat = new SimpleDateFormat("HH:mm:ss");
            bufferedWriter.write(ecg+","+spo2_red+","+resp+","+Temp_Value+","+global_HeartRate+","+global_spo2+","+global_RespirationRate);
            bufferedWriter.newLine();
          }
          catch(IOException e) 
          {
            println("It broke!!!");
            e.printStackTrace();
          }
        }
          ecs_rx_state=CESState_Init;
      } 
      else
      {
        ecs_rx_state=CESState_Init;
      }
    }
    break;

  default:
    break;
  }
}


/*********************************************** Recursive Function To Reverse The data *********************************************************/

public int reversePacket(char DataRcvPacket[], int n)
{
  if (n == 0)
    return (int) DataRcvPacket[n]<<(n*8);
  else
    return (DataRcvPacket[n]<<(n*8))| reversePacket(DataRcvPacket, n-1);
}

/*************** Function to Calculate Average *********************/
double averageValue(float dataArray[])
{

  float total = 0;
  for (int i=0; i<dataArray.length; i++)
  {
    total = total + dataArray[i];
  }
  return total/dataArray.length;
}
