//	-----------------------------------------------------------------------------------------------------------------------	//
//
//	MultiRoi_Kymograph.ijm 
// 	Alex Zwetsloot (Centre for Mechanochemical Cell Biology, University of Warwick) 
//
// 	v0.1 1/03/2018
//
// 	Make kymographs from all selected ROIs. Save them into a folder with the same name as the image file. 
// 	
//	-----------------------------------------------------------------------------------------------------------------------	//
// 	Settings:

var kymographOutput = ""
var kymographStartNumbering = 0
var channels = newArray("488","561");
// End settings.

// Some global vars. I would avoid these if I was more fluent in IJ Macro language.
var processingChannel = channels[1]	// State information - what channel are we currently processing?
var debugging = false;
var resultsTableRows = 0;

function arrayPop(x,array) {
	// Remove x from input array, returning the array without x.
	var startArray = Array.copy(array);
	var numOccurences = 0;
	// Count occurences of x in array
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
	for (var n = 0; n < array.length; n++){
		if (x == array[n]) { 
			return true;
		}
	}
	return false;
}

function z_debug(message) {
	if (debugging) {
		print(message);
	}
}

function saveOpenKymograph() {
	var uniqueKymoNumber = 0;
	uniqueKymoNumber = uniqueKymoNumber+kymographStartNumbering;
	while (File.exists(kymographOutput + "/" + "Kymograph_" + uniqueKymoNumber + "_" + processingChannel + ".tif")) {
		uniqueKymoNumber++;
	}
	setResult("Name", resultsTableRows, "Kymograph_" + uniqueKymoNumber + "_" + processingChannel + ".tif");
	setResult("Width (pix)", resultsTableRows, getWidth);
	setResult("t (frames)", resultsTableRows, getHeight);
	resultsTableRows++;
	z_debug("Chose unique kymograph number as: " + uniqueKymoNumber);
	saveAs(kymographOutput + "/" + "Kymograph_" + uniqueKymoNumber + "_" + processingChannel + ".tif");
	close();
}
function deleteAllROIs() {
	roiManager("deselect");
	roiManager("delete");
}
function generateKymographsFromRoi() {
	numRois = roiManager("count");
	for (var countRois = 0; countRois < numRois; countRois++) {
		z_debug("Processing ROI " + countRois);
		roiManager("select", countRois);
		run("KymographMax", "linewidth=13");
		// Invert and autocontrast
		run("Invert LUT");
		run("Enhance Contrast", "saturated=0.35");
		z_debug("Attempting to save open kymograph");
		saveOpenKymograph();
		z_debug("Saved...");
	}
	
}

macro "Collect Kymographs [g]" {
	// Get name and directory of currently open file.
	z_debug("Starting multicolor multiroi kymograph collector...");
	dir = getDirectory("image"); 
	name=getTitle;
	nameNoExt = split(name, ".");
	nameNoExt = nameNoExt[0];
	// Make kymograph output directory
	kymographOutput = dir + "/" + nameNoExt + "_Kymographs";
	File.makeDirectory(kymographOutput);
	// Now save the ROIs we used for transparency purposes:
	roiManager("deselect"); 
    roiManager("save", kymographOutput + "/" + "ROIs_Used.zip"); 
	// Now make kymographs:
	generateKymographsFromRoi();
	deleteAllROIs();
    // Save results table of kymograph widths to the same directory:
    saveAs("Results",  kymographOutput + "/" + "Kymographs_Summary.csv"); 
    close("Results");
	// Done
	z_debug("Ich bin fertig!");
}
