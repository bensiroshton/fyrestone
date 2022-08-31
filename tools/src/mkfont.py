"""create font tiles and export as assembly."""
import sys
import os
import json
import os.path as path
import fnmatch
import math
import re
import png
from wand.image import Image
from wand.drawing import Drawing
from wand.color import Color

CHAR_START = 32
CHAR_END = 126

_log = None

def print(msg):
	sys.stdout.write(msg)
	sys.stdout.flush()
	if _log is not None:
		_log.write(msg)
		_log.flush()

def println(msg):
	print(msg + "\n")

def sorted_alphanumeric(data):
	convert = lambda text: int(text) if text.isdigit() else text.lower()
	alphanum_key = lambda key: [convert(c) for c in re.split('([0-9]+)', key)]
	return sorted(data, key=alphanum_key)

def set_font_size(image, drawing):
	drawing.font_size = 8
	while True:
		metrics = drawing.get_font_metrics(image, "W", True)	
		if metrics.text_width <= 8 and metrics.text_height <= 8:
			return
		drawing.font_size -= 0.25	

def make_font(options):

	info = {}
	fontName = options["font"]

	info["font"] = {}
	info["font"]["name"] = fontName

	baseName = fontName
	baseName = baseName.replace(" ", "_")
	baseName = baseName.replace("-", "_")
	baseLabel = baseName.lower()

	outSrcFile = path.join(options["outFolder"], f"{baseName}.s")
	outHeaderFile = path.join(options["outFolder"], f"{baseName}.h")
	outImageFile = path.join(options["outFolder"], f"{baseName}.png")
	info["outFile"] = outSrcFile
	info["outHeader"] = outHeaderFile
	info["outImageFile"] = outImageFile

	if not options["overwrite"] and path.exists(outImageFile):
		println(f"skipping {outImageFile}, it already exists and ovewrite is set to False")
		info["skipped"] = True
		return info

	# draw font
	numChars = CHAR_END - CHAR_START + 1
	info["chars"] = {}
	info["chars"]["start"] = CHAR_START
	info["chars"]["end"] = CHAR_END
	info["chars"]["count"] = numChars

	# we are using blue as the background, if we set it to black then image magick creates a greyscale instead of a palette based image.
	# we don't really care, the values of importance are the background and forground indexes.
	with Image(background=Color("rgb(0,0,255"), width=numChars * 8, height=8) as image:
		image.format = "PNG8"
		image.type = "palette"
		with Drawing() as drw:
			drw.fill_color = Color("rgb(255,255,255")
			drw.font_family = fontName
			drw.text_alignment = "center"
			drw.text_antialias = False
			set_font_size(image, drw)
			info["font"]["size"] = drw.font_size
			println(f"font size: {drw.font_size}")
			x = 4
			y = 7
			for char in range(CHAR_START, CHAR_END + 1):
				drw.text(x, y, str(chr(char)))
				x += 8
			drw.draw(image)
		image.save(filename=outImageFile) # just for debugging
	
		# write data file
		bgIndex = options["bgIndex"]
		fgIndex = options["fgIndex"]
		outTiles = []
		outTilesSize = 0
		for xs in range(0, image.width, 8):
			tileData = []
			pixels = image.export_pixels(xs, 0, 8, 8, "R")
			pi = 0
			for iy in range(0, 8):
				row = 0
				for ix in range(0, 8):
					index = int(pixels[pi] / 255.0)
					pi += 1
					if index == 0: index = bgIndex
					else: index = fgIndex
					row |= index << (7 - ix) * 4
				tileData.append(row)
				outTilesSize += 4
			outTiles.append(tileData)
		
		outTilesLen = len(outTiles)	

		with open(outHeaderFile, "w") as fo:
			
			defLabel = baseLabel.upper()
			fo.write(f"// mkfont \"{fontName}\"\n\n")
			fo.write(f"#define {defLabel}_CHAR_START {CHAR_START}\n")
			fo.write(f"#define {defLabel}_CHAR_END   {CHAR_END}\n")
			fo.write(f"#define {defLabel}_CHAR_COUNT {numChars}\n")
			fo.write(f"#define {defLabel}_BG_INDEX   {hex(bgIndex)}\n")
			fo.write(f"#define {defLabel}_FG_INDEX   {hex(fgIndex)}\n")
			fo.write(f"#define {defLabel}_SIZE       {outTilesSize}\n")

		with open(outSrcFile, "w") as fo:

			fo.write(f"// mkfont \"{fontName}\"\n\n")
			fo.write(".text\n")
			fo.write(f"    .global {baseLabel}_data\n")
			fo.write("\n")

			fo.write(f"{baseLabel}_data:\n")
			for ti in range(0, outTilesLen):
				tileData = outTiles[ti]
				tileDataLen = len(tileData)
				fo.write("    dc.l    ")
				ds = ""
				for di in range(0, tileDataLen - 1):
					ds += f"{hex(tileData[di])},"
				ds += f"{hex(tileData[tileDataLen - 1])}"
				fo.write(ds.ljust(90, " "))

				c = CHAR_START + ti
				s = chr(c)
				if c == 32: s = "space"
				elif c == 92: s = "back slash"

				si = str(ti).rjust(2, " ")
				sc = str(c).rjust(3, " ")
				fo.write(f" // [{si}] {sc}, {hex(c)}: {s}\n")
			fo.write("\n")

	return info

def show_help():

	println("mkfont -i [source font(s)]")
	println("-f    : font name. [REQUIRED]")
	println("-o    : output folder [default current directory].")
	println("-w    : enable overwrite mode [default: False].")
	println("-bg   : background index (0-15) [default: 0].")
	println("-fg   : foreground index (0-15) [default: 1].")

def main(argv):

	global _log

	options = {}
	options["outFolder"] = "."
	options["overwrite"] = False
	options["font"] = None
	options["bgIndex"] = 0
	options["fgIndex"] = 1

	argCount = len(argv)
	if argCount==1: # need _some_ arguments
		show_help()
		return

	testMode = False

	xr = iter(range(argCount))
	next(xr)
	for i in xr:
		arg = argv[i]
		if arg=="-o" and i<argCount - 1:
			options["outFolder"] = argv[i+1]
			next(xr)
		elif arg=="-f" and i<argCount - 1:
			options["font"] = argv[i+1]
			next(xr)
		elif arg=="-bg" and i<argCount - 1:
			options["bgIndex"] = int(argv[i+1])
			next(xr)
		elif arg=="-fg" and i<argCount - 1:
			options["fgIndex"] = int(argv[i+1])
			next(xr)
		elif arg=="-w":
			options["overwrite"] = True
		elif arg=="-h":
			show_help()
			return
		else:
			println("unrecognized command (or missing command arguments): " + arg)
			return

	if options["font"] is None:
		println("font name must be supplied.")
		return

	if options["bgIndex"] == options["fgIndex"]:
		println("background and foreground indexes must be different.")
		return

	if options["bgIndex"] < 0 or options["bgIndex"] > 15:
		println("background index must be between 0 and 15.")
		return

	if options["fgIndex"] < 0 or options["fgIndex"] > 15:
		println("foreground index must be between 0 and 15.")
		return

	options["outFolder"] = path.abspath(options["outFolder"])

	_log = open("mkfont.log", "w")
	json.dump(options, _log, indent=4)
	println("")

	os.makedirs(options["outFolder"], exist_ok=True)
	info = make_font(options)
	info["options"] = options

	if info is not None:
		with open("mkfont.json", "w") as f:
			json.dump(info, f, indent=4)

	println("finished.")

if __name__ == '__main__':

	try:
		main(sys.argv)
	except KeyboardInterrupt:
		println("\nuser break!")
	except SystemExit:
		println("exiting program.")
	#except:		
	#	println(f"Unexpected error: {sys.exc_info()[0]}")

	if  _log is not None:
		_log.close()
