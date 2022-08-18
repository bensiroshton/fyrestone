"""convert png into an assembly data file"""
import sys
import os
import json
import os.path as path
import fnmatch
import math
import re
import png

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

def process_source(options, source):

	info = {}
	info["source"] = {}

	baseName = path.basename(source)
	baseName = path.splitext(baseName)[0]
	
	baseLabel = baseName.replace("-", "_")

	outFile = path.join(options["outFolder"], f"{baseName}.s")
	info["outFile"] = outFile

	if not options["overwrite"] and path.exists(outFile):
		println(f"skipping {outFile}, it already exists and ovewrite is set to False")
		info["skipped"] = True
		return info

	# load our source
	pngFile = png.Reader(source)
	image = pngFile.read()

	w = image[0]
	h = image[1]
	pngInfo = image[3]
	palLen = len(pngInfo["palette"])

	println(f"source image: {source}")
	println(f"size: {w} x {h}")	
	println(f"palette length: {palLen}")	

	if palLen == 0 or palLen > 16:
		println("ERROR: Input palette size must be between 1 and 16")
		return info

	if w % 8.0 > 0 or h % 8.0 > 0:
		println("ERROR: Image dimensions must be a multiple of 8.")
		return info

	wt = int(w / 8)
	ht = int(h / 8)

	data = list(image[2])
	dataLen = len(data)

	info["source"]["file"] = source
	info["source"]["width"] = w
	info["source"]["height"] = h
	info["source"]["widthTiles"] = wt
	info["source"]["heightTiles"] = ht
	info["source"]["paletteLength"] = palLen
	info["source"]["info"] = pngInfo
	info["source"]["dataLen"] = dataLen	

	outTiles = []
	outTilesSize = 0
	for y in range(0, h, 8):
		for x in range(0, w, 8):
			tileData = []
			for iy in range(0, 8):
				row = 0
				for ix in range(0, 8):
					index = data[y + iy][x + ix]
					row |= index << (7 - ix) * 4
				tileData.append(row)
				outTilesSize += 4
			outTiles.append(tileData)

	outTilesLen = len(outTiles)	

	inPal = pngInfo["palette"]
	outPal = []
	for i in range(0, palLen):
		rgb = inPal[i]
		r = int(rgb[0] / 255.0 * 15)
		g = int(rgb[1] / 255.0 * 15)
		b = int(rgb[2] / 255.0 * 15)
		color = b << 8 | g << 4 | r
		outPal.append(color)
	palSize = palLen * 2	

	with open(outFile, "w") as fo:
		fo.write(f"// png2asm {source}\n")
		fo.write(".text\n")
		fo.write(f"    .global {baseLabel}_width_tiles\n")
		fo.write(f"    .global {baseLabel}_height_tiles\n")
		fo.write(f"    .global {baseLabel}_tile_count\n")
		fo.write(f"    .global {baseLabel}_size\n")
		fo.write(f"    .global {baseLabel}_data\n")
		fo.write(f"    .global {baseLabel}_palette\n")
		fo.write(f"    .global {baseLabel}_palette_count\n")
		fo.write(f"    .global {baseLabel}_palette_size\n")
		fo.write("\n")

		# image info
		fo.write(f"{baseLabel}_width_tiles:\n    dc.w    {wt}\n\n")
		fo.write(f"{baseLabel}_height_tiles:\n    dc.w    {ht}\n\n")
		fo.write(f"{baseLabel}_tile_count:\n    dc.w    {outTilesLen}\n\n")
		fo.write(f"{baseLabel}_palette_count:\n    dc.w    {palLen}\n\n")
		fo.write(f"{baseLabel}_palette_size:\n    dc.w    {palSize}\n\n")

		# image data
		fo.write(f"{baseLabel}_data:\n")
		for ti in range(0, outTilesLen):
			tileData = outTiles[ti]
			tileDataLen = len(tileData)
			fo.write("    dc.l    ")
			for di in range(0, tileDataLen - 1):
				fo.write(f"{hex(tileData[di])},")
			fo.write(f"{hex(tileData[tileDataLen - 1])}\n")
		fo.write("\n")

		# palette data
		fo.write(f"{baseLabel}_palette:\n")
		fo.write("    dc.w    ")
		for i in range(0, palLen - 1):
			fo.write(f"{hex(outPal[i])},")
		fo.write(f"{hex(outPal[palLen - 1])}")
		fo.write("\n")

	return info

def get_files(sourcePath):

	files = []

	if sourcePath is None:
		return files

	if path.isfile(sourcePath):
		files.append(sourcePath)
		return files
	else:
		sourcePattern = "*"

		if not path.isdir(sourcePath):
			parts = path.split(sourcePath)
			sourcePath = parts[0]
			sourcePattern = parts[1]

		for file in os.listdir(sourcePath):
			if fnmatch.fnmatch(file, sourcePattern):
				files.append(path.join(sourcePath, file))

	return sorted_alphanumeric(files)

def process(options):

	info = {}
	info["jobs"] = []

	os.makedirs(options["outFolder"], exist_ok=True)

	# process each source image
	sourcePath = options["sources"]

	files = get_files(options["sources"])

	for file in files:
		info["jobs"].append(process_source(options, file))

	return info

def show_help():

	println("print-composite -i [source image(s)]")
	println("-i    : source image(s) to process, wildcards are ok. [REQUIRED]")
	println("-o    : output folder [default current directory].")
	println("-n    : name of output file, when used all source images will be included in this single file.")
	println("        default: not set, when not set a file per image will be output.")
	println("-w    : enable overwrite mode [default: False].")

def main(argv):

	global _log

	options = {}
	options["outFolder"] = "."
	options["name"] = None
	options["overwrite"] = False
	options["sources"] = None

	argCount = len(argv)
	if argCount==1: # need _some_ arguments
		show_help()
		return

	testMode = False

	xr = iter(range(argCount))
	next(xr)
	for i in xr:
		arg = argv[i]
		if arg=="-n" and i<argCount - 1:
			options["name"] = argv[i+1]
			next(xr)
		elif arg=="-o" and i<argCount - 1:
			options["outFolder"] = argv[i+1]
			next(xr)
		elif arg=="-i" and i<argCount - 1:
			options["sources"] = argv[i+1]
			next(xr)
		elif arg=="-w":
			options["overwrite"] = True
		elif arg=="-h":
			show_help()
			return
		else:
			println("unrecognized command (or missing command arguments): " + arg)
			return

	if not testMode:
		if options["sources"] is None:
			println("source image(s) must be supplied.")
			return

	options["outFolder"] = path.abspath(options["outFolder"])

	_log = open("png2asm.log", "w")
	json.dump(options, _log, indent=4)
	println("")

	info = process(options)

	if info is not None:
		with open("png2asm.json", "w") as f:
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
