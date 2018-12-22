//	-----------------------------------------------------------------------------------------------------------------------	//
//
//	MultiRoi_MultiCol_Kymograph.ijm 
// 	Alex Zwetsloot (Centre for Mechanochemical Cell Biology, University of Warwick) 
//
//  v0.4 22/12/2018
//	Change in v0.4
//					- save a simple image of the region you took the kymograph from
// 	v0.3 15/09/2018
//	Change in v0.3
//					- variable bool saveAdditionalKymographTypes - do you want to also save KymoSum and KymoRAW into
//					/Alternative subfolder for later quantitation.
//	24/11/2017:
// 	Change in v0.2 	- variable saveInProcessDir (true/false) to save in same location as original image.
//					- variable uniqueLabel, add a label infront of the kymograph name.
//
// 	This macro makes kymographs of all selected ROIs in all channels. This is written with Olympus capture
// 	software in mind (which saves channels as individial tiffs (e.g. 488.TIF, 561.TIF, 640.TIF).
//
//  If you have a single-frame image open, it will assume this is a template (e.g. just using 640 for outlining 
//	HiLyte microtubules), so it will move straight on to the other channels specified by the channels array.
//
//	It will then loop through the files specified by "channels" and make kymographs for all ROIs in those images.
//
// 	Each ROI and therefore resulting Kymograph is given a unique identifying number which is chosen by looping through
//	the output folder and seeing which numbers are available. This can be changed with the "numberingStartNumbering" which 
// 	is a variable which applies an offset for the numbering. (e.g. you have already Kymographs numbered 0-100 and you 
// 	have removed them from the output folder, so your kymographStartNumbering should be 100).
// 	
//	-----------------------------------------------------------------------------------------------------------------------	//
// 	Settings:
var kymographOutput = "/Users/alex/Desktop/"
var saveInProcessDir = true // Save in the same dir as the open image if not kymographOutput
var saveAdditionalKymographTypes = true // save a KymoSum and normal kymograph (for quantification purposes)
var kymographStartNumbering = 1
var channels = newArray("488ec","561ec");
var referenceChannel = "640nm"
var uniqueLabel = "2018_20_12_Experiment1_Kinesin";
// End settings.

// Some global vars. I would avoid these if I was more fluent in IJ Macro language.
var processingChannel = channels[0]	// State information - what channel are we currently processing?
var debugging = false;
var resultsTableRows = 0;
var originalDir = "";

function arrayPop(x,array) {
	// Remove x from input array, returning the array without x.
	var startArray = Array.copy(array);
	var numOccurences = 0;
	for (var c = 0; c < startArray.length; c++) {
		if (x == startArray[c]) {
			numOccurences++;
		}
	}
	var outputArray = newArray(startArray.length - numOccurences);
	var fillSequential = 0;
	for (var c = 0; c < startArray.length; c++) {
		if (x != startArray[c]) {
			outputArray[fillSequential] = startArray[c];
			fillSequential++;
		}
	}
	return outputArray;
}
function inArray(x,array) {
	// Is x in array?
	for (var n = 0; n < array.length; n++){
		if (x == array[n]) { 
			return true;
		}
	}
	return false;
}

function z_debug(message) {
	// Conditional print statement.
	if (debugging) {
		print(message);
	}
}

function generateReferenceImages() {
	// I never normally comment code so much, but this is a mess, so I better tell you 
	// what it's doing:
	//
	// Purpose: save image/plot-profile of MT from which kymographs are generated for
	// later inspection. 
	//
	// Function generateReferenceImages() - 
	// 		-> Loop through each ROI and:
	//			o Make a plot-profile of the kymograph line
	//			o Make a copy of a (20px padded) bounding-box, and
	//			  enlargen it to match plot-profile graph size.
	//			o Transform the ROI points to match the enlargened image.
	//			o Make a stack containing: 
	// 				1. The plotted profile.
	//				2. The enlargened image of the MT with ROI painted over in pink.
	//				3. The enlargened image of the MT without the ROI shown.
	//			o Flatten the stack into a montage, save as reference image.
	
	setBatchMode(true);
	numRois = roiManager("count");
	for (var countRois = 0; countRois < numRois; countRois++) {
		roiManager("select", countRois);
		// Get the coordinates of the rectangle which would encompass
		// the entire ROI line. Give it a 20pix margin.
		getSelectionCoordinates(xpoints, ypoints);
		Array.getStatistics(xpoints, min_x, max_x);
		Array.getStatistics(ypoints, min_y, max_y);
		getDimensions(width, height, channels[0], slices, frames);
		max_x = max_x+20;
		max_y = max_y+20;
		min_x = min_x-20;
		min_y = min_y-20;
	   if (max_x > width) { max_x = width; }
	   if (max_y > height) { max_y = height; }
	   if (min_x < 0) { min_x = 0; }
	   if (min_y < 0) { min_y = 0; }
	   rHeight = max_y - min_y;			// The rectangle's height/width
	   rWidth = max_x - min_x;
	   makeRectangle(min_x, min_y, rWidth, rHeight);
	   // Work out how to scale the rectangle to match the dimensions of the
	   // plot profile graph (we can only make stacks out of identical dimension images). 
	   var scaleBy = 1;
	   var scaleFactor = 1;
	   if (rWidth > rHeight) { 
	   		scaleBy = rWidth;
	   		scaleFactor = 613/scaleBy;
	   } else {
	   		scaleBy = rHeight;
	   		scaleFactor = 355/scaleBy;
	   }
	   // Copy out the rectangle to its own image.
	   run("Duplicate...", "title=ReferenceWithROI");
	   newX = Array.copy(xpoints);
	   newY = Array.copy(ypoints);
	   newXScaled = Array.copy(xpoints);
	   newYScaled = Array.copy(ypoints);
	   // Work out where the original ROI sits given we have made an image
	   // of new dimensions. Also, transform the ROI's points to fit the 
	   // enlargened image we will use in a minute.
	   for (var point = 0; point < xpoints.length; point++) {
	   		newX[point] = newX[point] - min_x;
	   		newY[point] = newY[point] - min_y;
	   		newXScaled[point] = (newXScaled[point] - min_x)*scaleFactor;
	   		newYScaled[point] = (newYScaled[point] - min_y)*scaleFactor;
	   }
	   // Make profile from original image selection:
	   makeSelection("polyline", newX, newY);
	   run("Plot Profile","title=ReferenceProfile");
	   // Make stack to add things to
	   newImage("Stack", "RGB white", 613, 355, 3);
	   // Add plot to stack.
	   selectWindow("Plot of ReferenceWithROI");
	   run("Copy");
	   selectWindow("Stack");
	   setSlice(1);
	   run("Paste");
	   // Blow up image to be same size as plot:
	   selectWindow("ReferenceWithROI");
	   run("Scale...", "x=- y=- width="+(rWidth*scaleFactor)+" height=- interpolation=Bilinear average create title=ReferenceBlownUp");	
	   close("ReferenceWithROI");
	   selectWindow("ReferenceBlownUp");
	   // Make sure it fits exactly with the plotprofile so we can add it to stack.
	   // Then add it to the stack.
	   run("Canvas Size...", "width=613 height=355 position=Top-Left");
	   run("Copy");
	   selectWindow("Stack");
	   setSlice(2);
	   run("Paste");
	   // Select the scaled-ROI in the stack and paint it pink.
	   makeSelection("polyline", newXScaled, newYScaled);
	   setForegroundColor(255, 0, 229);
	   run("Draw", "slice");
	   // Now make a copy without the ROI.
	   selectWindow("ReferenceBlownUp");
	   run("Duplicate...", "title=ReferenceBlownUpNoROI");
	   roiManager("deselect");
	   run("Copy");
	   selectWindow("Stack");
	   setSlice(3);
	   run("Paste");
	   // Clean up a bit, make and save the montage.
	   close("Reference*");
	   close("Plot*");
	   selectWindow("Stack");
	   run("Make Montage...", "columns=3 rows=1 scale=1 border=20");
	   // Co-opt our saveOpenKymograph function to save it with a nice unique name.
	   saveOpenKymograph(false,"Max");
	   close();
	   close("Stack");
	}
	setBatchMode(false);
	
}

function saveOpenKymograph(alternative, type) {
	var uniqueKymoNumber = 0;
	uniqueKymoNumber = uniqueKymoNumber+kymographStartNumbering;
	while (File.exists(kymographOutput + "/" + uniqueLabel + "_Kymograph_" + uniqueKymoNumber + "_" + processingChannel + ".tif")) {
		uniqueKymoNumber++;
	}
	if (processingChannel != "REF") {
		setResult("Name", resultsTableRows, uniqueLabel + "_Kymograph_" + uniqueKymoNumber + "_" + processingChannel + ".tif");
		setResult("Width (pix)", resultsTableRows, getWidth);
		setResult("t (frames)", resultsTableRows, getHeight);
		resultsTableRows++;
	}
	z_debug("Chose unique kymograph number as: " + uniqueKymoNumber);
	saveAs(kymographOutput + "/" + uniqueLabel + "_Kymograph_" + uniqueKymoNumber + "_" + processingChannel + ".tif");
	if (alternative) {
		// If alternative, that means we also want to save Kymo and KymoSum for quantitation
		saveAs(kymographOutput + "/Alternative/"+ type + uniqueLabel + "_Kymograph_" + uniqueKymoNumber + "_" + processingChannel + ".tif");
	} else {
		saveAs(kymographOutput + "/" + uniqueLabel + "_Kymograph_" + uniqueKymoNumber + "_" + processingChannel + ".tif");
	}
	close();
	return uniqueKymoNumber;
}

function generateKymographsFromRoi() {
	numRois = roiManager("count");
	for (var countRois = 0; countRois < numRois; countRois++) {
		z_debug("Processing ROI " + countRois);
		roiManager("select", countRois);
		run("KymographMax", "linewidth=5");
		// Invert and autocontrast
		run("Invert LUT");
		run("Enhance Contrast", "saturated=0.35");
		z_debug("Attempting to save open kymograph");
		var uniqueID = saveOpenKymograph(false, "Max");
		z_debug("Saved...");
		if (saveAdditionalKymographTypes) {
			// Repeat to save Kymograph SUM
			roiManager("select", countRois);
			run("KymographSum", "linewidth=13");
			run("Invert LUT");
			run("Enhance Contrast", "saturated=0.35");
			z_debug("Attempting to save open kymograph");
			saveAs(kymographOutput + "/Alternative/SUM_" + uniqueLabel + "_Kymograph_" + uniqueID + "_" + processingChannel + ".tif");
			close();
			z_debug("Saved SUM...");
			roiManager("select", countRois);
			// Repeat to save Kymograph RAW
			run("Kymograph", "linewidth=13");
			run("Invert LUT");
			run("Enhance Contrast", "saturated=0.35");
			saveAs(kymographOutput + "/Alternative/RAW_" + uniqueLabel + "_Kymograph_" + uniqueID + "_" + processingChannel + ".tif");
			close();
		}
	}
	
}

macro "Collect MRMC Kymographs [g]" {
	// Get name and directory of currently open file.
	z_debug("Starting multicolor multiroi kymograph collector...");
	dir = getDirectory("image"); 
	originalDir = dir;
	if (saveInProcessDir) {
		kymographOutput = dir;
	}
	if (saveAdditionalKymographTypes) {
		if (!File.exists(kymographOutput + "/Alternative")) {
			File.makeDirectory(kymographOutput + "/Alternative");
		}
	}
	name=getTitle;
	nameNoExt = split(name, ".");
	nameNoExt = nameNoExt[0];
	var local_copy_channels = channels;
	processingChannel = "REF";
	generateReferenceImages();
	selectWindow(name);
	return;
	// Check if its one we want to make kymographs for?
	if (inArray(nameNoExt, channels)) {
		z_debug("Image open is " + nameNoExt + " which is one we want to process.");
		// If the image we have open is one that we want to process, lets process it now!
		// But remove it from the list of things to process later.
		local_copy_channels = arrayPop(nameNoExt, channels);
		processingChannel = nameNoExt;
		generateKymographsFromRoi();
		close(name);
	}
	// Now loop through the rest of the colours
	for (var count = 0; count < local_copy_channels.length; count++) {
		open(dir+"/"+local_copy_channels[count]+".TIF");
		processingChannel = local_copy_channels[count];
		generateKymographsFromRoi();
		close(local_copy_channels[count]+".TIF");
	}
	// Now save the ROIs we used for transparency purposes:
	roiManager("deselect"); 
	roiManager("save", dir + "/" + uniqueLabel + "_ROIs_Used.zip"); 
	// Save results table of kymograph widths to the same directory:
	saveAs("Results",  dir + "/" + "Kymographs_Summary.csv"); 
	close("Results");
	// Done
	z_debug("Ich bin fertig!");
}
