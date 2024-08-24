function BioRadio_Disconnect ( myDevice )
% function BioRadio_Disconnect ( myDevice )
% BioRadio_Disconnect terminates the connection with the BioRadio
macID =int64(hex2dec('ECFE7E19AAA6'));
deviceManager = GLNeuroTech.Devices.BioRadio.BioRadioDeviceManager;
myDevice = deviceManager.GetBluetoothDevice(macID);
 
% INPUTS:
% - myDevice is a handle to a BioRadio device object

myDevice.Disconnect;