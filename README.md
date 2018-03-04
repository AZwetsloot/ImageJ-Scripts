# ImageJ-Scripts :microscope::mouse2::hospital:
A collection of ImageJ/FiJi scripts that work for me, but might not for you.

### [AutoMontage.ijm](https://github.com/AZwetsloot/ImageJ-Scripts/blob/master/AutoMontage.ijm)
Automatically make two-colour montages + a merge image next to it.

Useful for processing two-colour microscopy quickly.

Example:
![alt text](https://github.com/AZwetsloot/ImageJ-Scripts/blob/master/automontage_example.jpg?raw=true)

### [MultiRoi_MultiCol_Kymograph.ijm](https://github.com/AZwetsloot/ImageJ-Scripts/blob/master/MultiRoi_MultiCol_Kymograph.ijm)
Automatically generate multiple colours of kymograph for different channels (designed around Olympus software which saves the files individually as lightpath.TIFF). Saves kymographs each with unique identifying number. 

To use, open up your guide channel (e.g. microtubules?) and draw over them, adding to ROI manager. Click run, and if you're in an image with more than one timepoint, it will think you want to use this channel and will loop through each of the ROIs generating kymographs, autocontrasting them, inverting them and saving them.

Then if there's more channels to be processed, it will open up those images and apply exactly the same ROI to them.

ROIs are saved so that you can always look back.

### [MultiRoi_Kymograph.ijm](https://github.com/AZwetsloot/ImageJ-Scripts/blob/master/MultiRoi_Kymograph.ijm)
Loop through all of ROIs in the ROI manager, generate kymograph, auto-contrast, invert and save with identifying number.

### [Tiled_ThunderSTORM.py](https://github.com/AZwetsloot/ImageJ-Scripts/blob/master/Tiled_ThunderSTORM.py)
Made for Warwick Open-source Microscope (WOSM). Could work elsewhere.

A jython bolt-on that attempts to batch process STORM/PALM stacks, apply offsets to them, and concat' into one larger tiled image.

Pop in your plugins folder to have a go. Modify the settings for ThunderSTORM at the top of the file if you fancy. 

*Requires that ThunderSTORM plugin is installed...*


