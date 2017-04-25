#	-----------------------------------------------
# 	Tiled STORM ThunderSTORM bolt on. v0.1 25/04/17
# 	Alex Zwetsloot, University of Warwick
# 	alex@zwetsloot.uk
#	-----------------------------------------------

# 	This macro takes a JSON file containing a "Points" object; each point 
# 	is a position on a stage where a STORM stack has been acquired, as well as
# 	the filename of that stack. These are used to batch process in ThunderSTORM 
# 	and the resultant spot location csv files are edited with these offsets
# 	allowing the reconstruction of a large-scale tiled image.

# 	If you are not using the WOSM64 capture software, then your JSON settings file will 
# 	not automatically be created. An example is given below to show the format
# 	to be used.

#	Perfect your ThunderSTORM settings manually, and then input them in the 
#	stormAnalysisParams variable below. Run the macro and select the json file.

# -> acquisitionLog.json 
# {"TileCount": 5,
#  "FramesPertile": 60.0,
#  "Weather": "Pleasant, North Westerly breeze. Relative humidity 32%, temperature 20C.",
#  "Points": [
#    {
#      "id": 0,
#      "Filename": "STORM_tile_0.tif",
#      "X": 0.0,
#      "Y": 0.0
#    },
#    {
#      "id": 1,
#      "Filename": "STORM_tile_1.tif",
#      "X": 66360.0,
#      "Y": 0.0
#    },
#    {
#      "id": 2,
#      "Filename": "STORM_tile_2.tif",
#      "X": 132720.0,
#      "Y": 0.0
#    },
#    {
#      "id": 3,
#      "Filename": "STORM_tile_3.tif",
#      "X": 199079.99999999997,
#      "Y": 0.0
#    },
#    {
#      "id": 4,
#      "Filename": "STORM_tile_4.tif",
#      "X": 199079.99999999997,
#      "Y": 66360.0
#    }
#}

from ij import IJ, WindowManager
import json, os, csv
# STORM macro settings:
macro = "ThunderSTORM"
stormAnalysisCmd = "Run analysis"
stormAnalysisParams = """"filter=[Wavelet filter (B-Spline)] scale=2.0 order=3 detector detector=[Local maximum] connectivity=8-neighbourhood threshold=std(Wave.F1) estimator=[PSF: Integrated Gaussian] sigma=1.6 method=[Weighted Least squares] fitradius=3 mfaenabled=false renderer=[No renderer]""" 
stormExportCmd = "Export results"
stormExportParams = "filepath=[%filename] file=[CSV (comma separated)] frame=true x=true y=true sigma=true intensity=true offset=true bkgstd=true uncertainty=true"
tiledStormSpotfile = "Tiled_STORM_image.csv"	# The output file.
virtualStack = False							# Use virtual stack?

# Global var:
exportList = list()

def applyOffsets(fileList, jsonSettings, outputFilename):
	# ---------------------------------------------
	# Applies the nanometer offset read from the json
	# configuration file (jsonSettings) to each of the
	# csv files in fileList, then concatentates these
	# all into one csv called outputFilename.
	# ---------------------------------------------
	print(outputFilename)
	finalOutputCSV = list()
	countFiles = 0
	header = ""
	for filename in fileList:
		offsetX = jsonSettings['Points'][countFiles]['X']
		offsetY = jsonSettings['Points'][countFiles]['Y']
		countFiles += 1
		print(offsetY)
		print(offsetX)
		rowcounter = 0
		with open(filename, 'rb') as tileFile:
			tileData = csv.reader(tileFile)	
			for row in tileData:
				if rowcounter == 0:
					header = row
					rowcounter += 1
					continue
				editRow = row
				editRow[1] = float(editRow[1]) + float(offsetX)
				editRow[2] = float(editRow[2]) + float(offsetY)
				finalOutputCSV.append(editRow)
			rowcounter = 0
			
	with open(outputFilename, 'wb') as out:
		myWriter = csv.writer(out)
		myWriter.writerow(header)
		myWriter.writerows(finalOutputCSV)	
	print("Finished!")
	WindowManager.closeAllWindows()
	return

def runThunderSTORM(filename):
	# ---------------------------------------------
	# Runs the ThunderSTORM plugin on the filename 
	# provided with the settings from the top of 
	# this file.
	# ---------------------------------------------
	global exportList
	if virtualStack: 
		IJ.openVirtual(filename)
	else:
		IJ.open(filename)
	IJ.run(stormAnalysisCmd, stormAnalysisParams)
	dataStoreFilename =os.path.dirname(filename) + os.sep + os.path.splitext(os.path.basename(filename))[0] + ".csv"
	exportList.append(dataStoreFilename)
	exportParams = stormExportParams.replace("%filename",dataStoreFilename)
	print exportParams
	IJ.run(stormExportCmd, exportParams)
	WindowManager.closeAllWindows()
	return exportList

def main():
	# ---------------------------------------------
	# Loads json file, reads tiff stack filenames
	# runs them through the selected STORM analyser
	# then attempts to save the collected spot info.
	# ---------------------------------------------
	settingsFile = ""
	settingsFile = IJ.getFilePath(settingsFile);
	if settingsFile == None:
		return
	try:
		jsonFileObj = open(settingsFile,'r')
		jsonRead = json.load(jsonFileObj)	
	except:
		IJ.error("No JSON could be loaded from " + settingsFile + ". Are you certain this file is the correct format?");
		return
	directory = jsonRead['SaveDirectory']
	tiledStormOutputFile = directory + os.sep + "Tiled_STORM_spots.csv"
	# Run analysis:
	for item in jsonRead['Points']:
		imageFile = directory + os.sep + item['Filename']
		if macro == "ThunderSTORM":
			fileList = runThunderSTORM(imageFile)
		elif macro == "SomeOTHERnotimplementedSTORM":
			fileList = runThunderSTORM(imageFile)
		else:
			IJ.error("The STORM method selected in the Tile_STORM macro is invalid. :(")
	# Apply offsets:
	applyOffsets(fileList, jsonRead, tiledStormOutputFile)
	
	return 0
	
main()