//	-----------------------------------------------------------------------------------------------------------------------	//
//
//	MultiRoi_MultiCol_Kymograph.ijm 
// 	Alex Zwetsloot (Centre for Mechanochemical Cell Biology, University of Warwick) 
//
// 	v0.1 24/11/2017
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
var kymographOutput = "/Users/alex/Desktop/Kymograph_Output"
var kymographStartNumbering = 100
var channels = newArray("488","561");
// End settings.

// Some global vars. I would avoid these if I was more fluent in IJ Macro language.
var processingChannel = channels[0]	// State information - what channel are we currently processing?
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

function generateKymographsFromRoi() {
	numRois = roiManager("count");
	for (var countRois = 0; countRois < numRois; countRois++) {
		z_debug("Processing ROI " + countRois);
		roiManager("select", countRois);
		run("KymographMax", "linewidth=1");
		// Invert and autocontrast
		run("Invert LUT");
		run("Enhance Contrast", "saturated=0.35");
		z_debug("Attempting to save open kymograph");
		saveOpenKymograph();
		z_debug("Saved...");
	}
	
}

macro "Collect MRMC Kymographs [g]" {
	// Get name and directory of currently open file.
	z_debug("Starting multicolor multiroi kymograph collector...");
	dir = getDirectory("image"); 
	name=getTitle;
	nameNoExt = split(name, ".");
	nameNoExt = nameNoExt[0];
	var local_copy_channels = channels;
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
    roiManager("save", dir + "/" + "ROIs_Used.zip"); 
    // Save results table of kymograph widths to the same directory:
    saveAs("Results",  dir + "/" + "Kymographs_Summary.csv"); 
    close("Results");
	// Done
	z_debug("Ich bin fertig!");
}

