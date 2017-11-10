pixelSizeNanometers = 160
# The size of 1 pixel at the sample level
# i.e. pixel size of camera / magnification

mode = "phase"
# mode =
#  "phase" => https://en.wikipedia.org/wiki/Phase_correlation
#
#  or "template" => https://en.wikipedia.org/wiki/Template_matching

imageDirectory = '/Users/your_username/Documents/cc_images'
# A folder which has a number of images
# which are named as follows:
#
# image1_A.tif    // Your template
# image1_B.tif    // Your probe offset by a known amount.
# image2_A.tif
# image2_B.tif
#
# The bit before the _A or _B can be anything but must match with its corresponding
# template. i.e. chocolatefoob_A.tif chocolatefoob_B.tif is fine, chocolatefoob_A.tif
# chocolatecat_B.tif is not.
#
# To collect suitable images you should
# continually move X and Y back and forth saving it as A and B each time.

import cv2, os
import numpy as np
opposite = dict({
    "A":"B",
    "B":"A",
    "a":"b",
    "b":"a"
})

def main():
    if mode is "phase":
        print("Image1,Image2,PixelOffsetX,PixelOffsetY,OffsetX,OffsetY")
    elif mode is "template":
        print("Image,Template,PixelOffsetX,PixelOffsetY,OffsetX,OffsetY")
    filenames = [f for f in os.listdir(imageDirectory) if os.path.isfile(os.path.join(imageDirectory, f))]
    processedFiles = list()
    for file in filenames:
        try:
            fullFilename = os.path.join(imageDirectory,file)
            splitFilename = os.path.splitext(os.path.basename(file))
            idLetter = splitFilename[0][-1]
            complementaryFilename = splitFilename[0][:-1] + opposite[idLetter] + splitFilename[1]
            complementaryFile = os.path.join(imageDirectory,complementaryFilename)
            if file in processedFiles or complementaryFilename in processedFiles:
                continue    # Don't run if we've already processed this file.
            else:
                processedFiles.append(file)
                processedFiles.append(complementaryFilename)
                if mode is "phase":
                    # Read the images and convert them to a numpy array
                    image1 = cv2.imread(fullFilename,0)
                    image2 = cv2.imread(complementaryFile,0)
                    image1 = np.float64(image1)
                    image2 = np.float64(image2)
                    # Phase correlate
                    result = cv2.phaseCorrelate(image1,image2)
                    offsetPix = (abs(result[0]),abs(result[1]))
                elif mode is "template":
                    image1 = cv2.imread(fullFilename)
                    templateFull = cv2.imread(complementaryFile)
                    height, width, channels = templateFull.shape
                    intervalH = height/4
                    intervalW = width/4
                    template = templateFull[intervalH-1:intervalH*3-1,intervalW-1:intervalW*3-1]
                    result = cv2.matchTemplate(image1,template,cv2.TM_CCOEFF_NORMED)
                    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)
                    offsetPix = (abs(max_loc[0]-intervalW-1), abs(max_loc[1]-intervalH-1))
                offsetNm = (abs(offsetPix[0]*pixelSizeNanometers),abs(offsetPix[1]*pixelSizeNanometers))
                print "%s,%s,%s,%s,%s,%s" % (file,complementaryFilename,offsetPix[0],offsetPix[1],
                	offsetNm[0],offsetNm[1])
        except:
            # We failed to process a file, so we won't go there again.
            processedFiles.append(file)

    return

print cv2.__version__
print "_______________"
main()
