"""convert a tiled map json into assembly."""
import sys
import os
import json
import os.path as path
import libgen

log = libgen.Log("tiled2asm.log")

def set_font_size(image, drawing):
	drawing.font_size = 8
	while True:
		metrics = drawing.get_font_metrics(image, "W", True)	
		if metrics.text_width <= 8 and metrics.text_height <= 8:
			return
		drawing.font_size -= 0.25	

def process_tileset(sourceFile, options):

	sourcePath = path.split(sourceFile)[0]

	info = {
		"source": sourceFile
	}
	tileset = None
	with open(sourceFile, "r") as f:
		tileset = json.load(f)

	if tileset is None:
		log.error(f"Unable to load json: {sourceFile}")
		return info

	if "image" in tileset:
		imageFile = path.join(sourcePath, tileset["image"])
		ext = path.splitext(imageFile)[1]
		if ext != ".png":
			log.println(f"skipping tileset {sourceFile}, source image is not a png.")
			info["error"] = "source image is not a png."
			info["skipped"] = True
		else:
			info["toAsm"] = libgen.png.to_asm(imageFile, options)

	return info

def process_source(sourceFile, options):

	info = {}

	sourcePath = path.split(sourceFile)[0]
	baseName = path.basename(sourceFile)
	baseName = path.splitext(baseName)[0]
	baseName = baseName.replace(" ", "_")
	baseName = baseName.replace("-", "_")
	baseLabel = baseName.lower()

	outSrcFile = path.join(options["outFolder"], f"{baseName}.s")
	outHeaderFileName = f"{baseName}.h"
	outHeaderFile = path.join(options["outFolder"], outHeaderFileName)
	outCommonHeaderFile = path.join(options["outFolder"], "map_common.h")
	info["outFile"] = outSrcFile
	info["outHeader"] = outHeaderFile
	info["outCommon"] = outCommonHeaderFile

	if not options["overwrite"] and path.exists(outSrcFile):
		log.println(f"skipping {outSrcFile}, it already exists and ovewrite is set to False.")
		info["skipped"] = True
		return info

	tiled = None
	with open(sourceFile, "r") as f:
		tiled = json.load(f)

	if tiled is None:
		log.error(f"Uunable to load json: {sourceFile}")
		return info

	if not "layers" in tiled:
		log.error("Layers not found.")
		return info

	if "tilesets" in tiled:
		info["tilesets"] = []
		for tileset in tiled["tilesets"]:
			info["tilesets"].append(process_tileset(path.join(sourcePath, tileset["source"]), options))

	layers = []
	for layer in tiled["layers"]:
		if not "properties" in layer:
			continue

		props = {}
		for prop in layer["properties"]:
			props[prop["name"]] = prop["value"]

		if not "export" in props or props["export"] != True:
			continue

		plane = "B"
		if "plane" in props:
			plane = props["plane"].upper()
		else:
			log.warn(f"Property does not exist 'plane', defaulting to {plane}.")

		if plane != "A" and plane != "B" and plane != "W":
			log.error("Plane must be one of the following: A, B, W")

		vram = None
		if plane == "A": vram = "VDP_PLANEA"
		elif plane == "B": vram = "VDP_PLANEB"
		elif plane == "W": vram = "VDP_WINDOW"

		if layer["type"] != "tilelayer":
			continue

		paletteIndex = 0
		if "paletteIndex" in props:
			paletteIndex = props["paletteIndex"]

		layerName = layer["name"]
		mapWidth = layer["width"] # in tiles
		mapHeight = layer["height"]
		offsetX = layer["startx"]
		offsetY = layer["starty"]

		tiles = [[0] * mapWidth for _ in range(mapHeight)]

		outLayer = {
			"name": layerName,
			"width": mapWidth,
			"height": mapHeight,
			"tiles": tiles,
			"outTilesSize": 0,
			"plane": plane,
			"vram": vram,
		}
		layers.append(outLayer)

		for chunk in layer["chunks"]:
			chunkX = chunk["x"] - offsetX
			chunkY = chunk["y"] - offsetY
			chunkWidth = chunk["width"]
			chunkHeight = chunk["height"]
			chunkData = chunk["data"]
			chunkIdx = 0
			for y in range(0, chunkHeight):
				for x in range(0, chunkWidth):
					tile = chunkData[chunkIdx]
					# Tiled Data
					# tile is a 32 bit value; https://doc.mapeditor.org/en/stable/reference/global-tile-ids/
					# H V D 0 X X X X  X X X X X X X X  X X X X X X X X  X X X X X X X X
					# H = Horizontal Flip
					# V = Vertical Flip
					# D = Diagnol Flip (For isometric maps)
					# 0 = Ignore
					# X = Tile ID
					if tile == 0:
						tileId = 0
						hFlip = 0
						vFlip = 0
					else:
						hFlip = tile >> 31
						vFlip = tile >> 30 & 0x01
						tileId = tile & 0xfffffff
						tileId -= 1 # TODO: get firstgid
					
					if tileId > 1023:
						log.error("Tile indexes must be 10-bit values.")
						return info

					tiles[chunkY + y][chunkX + x] = libgen.vdp.make_tile(tileId, hFlip, vFlip)
					outLayer["outTilesSize"] += 2 # 2 bytes per tyle
					chunkIdx += 1

	if len(layers) == 0:
		log.print("Nothing to export, did you add the custom 'export' property to your layer(s)?")
		return info

	# Write header file
	with open(outHeaderFile, "w") as fo:

		# file header
		fo.write(f"// tiled2asm \"{sourceFile}\"\n")
		fo.write("#include \"hw.h\"\n")
		fo.write("#include \"app.h\"\n")
		fo.write("\n")

		# map details
		for layer in layers:
			layerName = libgen.util.make_variable_friendly(layer["name"])
			outTileSize = layer["outTilesSize"]
			mapWidth = layer["width"]
			mapHeight = layer["height"]
			tileCount = mapWidth * mapHeight
			vram = layer["vram"]
			defLabel = f"{baseLabel.upper()}_{layerName.upper()}"
			fo.write(f"// Layer: {layerName}\n\n")
			fo.write(f"#define {defLabel}_MAP_WIDTH         {mapWidth}\n")
			fo.write(f"#define {defLabel}_MAP_HEIGHT        {mapHeight}\n")
			fo.write(f"#define {defLabel}_MAP_PIXEL_WIDTH   {mapWidth * 8}\n")
			fo.write(f"#define {defLabel}_MAP_PIXEL_HEIGHT  {mapHeight * 8}\n")
			fo.write(f"#define {defLabel}_TILE_COUNT        {tileCount}\n")
			fo.write(f"#define {defLabel}_SIZE              {outTileSize}\n")
			fo.write(f"#define {defLabel}_MAX_TILE_X        {defLabel}_MAP_WIDTH - SCREEN_TILE_WIDTH\n")
			fo.write(f"#define {defLabel}_MAX_TILE_Y        {defLabel}_MAP_HEIGHT - SCREEN_TILE_HEIGHT\n")
			fo.write(f"#define {defLabel}_VRAM              {vram}\n")
			fo.write(f"#define {defLabel}_MAX_PIXEL_X       {defLabel}_MAP_PIXEL_WIDTH - SCREEN_WIDTH\n")
			fo.write(f"#define {defLabel}_MAX_PIXEL_Y       {defLabel}_MAP_PIXEL_HEIGHT - SCREEN_HEIGHT\n")
			fo.write("\n")

	with open(outCommonHeaderFile, "w") as fo:
		# file header
		fo.write("// tiled2asm commons\n\n")
		fo.write("// Assembly Offsets\n")
		fo.write("#define MAP_OS                 0\n")
		fo.write("#define MAP_OS_DATA_ADD        0\n")
		fo.write("#define MAP_OS_WIDTH           4\n")
		fo.write("#define MAP_OS_HEIGHT          6\n")
		fo.write("#define MAP_OS_MAX_TILE_X      8\n")
		fo.write("#define MAP_OS_MAX_TILE_Y     10\n")
		fo.write("#define MAP_OS_VRAM           12\n")
		fo.write("#define MAP_OS_MAX_PIXEL_X    16\n")
		fo.write("#define MAP_OS_MAX_PIXEL_Y    18\n")
		fo.write("\n")

	# write source file
	with open(outSrcFile, "w") as fo:

		# file header		
		fo.write(f"// tiled2asm \"{sourceFile}\"\n")
		fo.write(f"#include \"{outHeaderFileName}\"\n")
		fo.write("\n")

		# globals
		fo.write(".text\n")
		for layer in layers:
			layerName = libgen.util.make_variable_friendly(layer["name"])
			fo.write(f"    // data\n")
			label = f"{baseLabel}_{layerName.lower()}"
			fo.write(f"    .global {label}_data\n")
			fo.write(f"    // struct\n")
			label = libgen.util.to_upper_camel(label)
			fo.write(f"    .global {label}\n")
			fo.write(f"    .global {label}Data\n")
			fo.write(f"    .global {label}Width\n")
			fo.write(f"    .global {label}Height\n")
			fo.write(f"    .global {label}MaxTileX\n")
			fo.write(f"    .global {label}MaxTileY\n")
			fo.write(f"    .global {label}VRam\n")
			fo.write(f"    .global {label}MaxPixelX\n")
			fo.write(f"    .global {label}MaxPixelY\n")

		fo.write("\n")

		# map struct
		for layer in layers:
			layerName = libgen.util.make_variable_friendly(layer["name"])
			label = f"{baseLabel}_{layerName.lower()}"
			dataLabel = f"{label}_data"
			defLabel = f"{baseLabel.upper()}_{layerName.upper()}"
			label = libgen.util.to_upper_camel(label)

			fo.write(f"// map struct\n")
			fo.write(f"{label}:\n")
			fo.write(f"{label}Data:         dc.l    {dataLabel}\n")
			fo.write(f"{label}Width:        dc.w    {defLabel}_MAP_WIDTH\n")
			fo.write(f"{label}Height:       dc.w    {defLabel}_MAP_HEIGHT\n")
			fo.write(f"{label}MaxTileX:     dc.w    {defLabel}_MAX_TILE_X\n")
			fo.write(f"{label}MaxTileY:     dc.w    {defLabel}_MAX_TILE_Y\n")
			fo.write(f"{label}VRam:         dc.l    {defLabel}_VRAM\n")
			fo.write(f"{label}MaxPixelX:    dc.w    {defLabel}_MAX_PIXEL_X\n")
			fo.write(f"{label}MaxPixelY:    dc.w    {defLabel}_MAX_PIXEL_Y\n")
			fo.write("\n")

		# tile data
		for layer in layers:
			layerName = libgen.util.make_variable_friendly(layer["name"])
			mapWidth = layer["width"]
			mapHeight = layer["height"]
			tiles = layer["tiles"]
			label = f"{baseLabel}_{layerName.lower()}"
			dataLabel = f"{label}_data"

			# map data
			fo.write(f"// map data (indexed tiles)\n")
			fo.write(f"{dataLabel}:\n")
			for y in range(0, mapHeight):
				fo.write("    dc.w    ")
				for x in range(0, mapWidth - 1):
					fo.write(f"{hex(tiles[y][x])},")
				fo.write(f"{hex(tiles[y][mapWidth -1])}\n")
			fo.write("\n")

	layersExported = len(layers)
	log.println(f"exported {layersExported} layers.")
	info["layersExported"] = layersExported

	return info

def process(options):

	info = {}
	info["jobs"] = []

	os.makedirs(options["outFolder"], exist_ok=True)

	# process each source image
	sourcePath = options["sources"]

	files = libgen.util.get_files(options["sources"])

	for file in files:
		info["jobs"].append(process_source(file, options))

	return info

def show_help():

	log.println("tiled2asm -i [source tiled map json(s)]")
	log.println("-o    : output folder [default current directory].")
	log.println("-w    : enable overwrite mode [default: False].")

def main(argv):

	options = {}
	options["log"] = log
	options["sources"] = None
	options["outFolder"] = "."
	options["overwrite"] = False

	argCount = len(argv)
	if argCount==1: # need _some_ arguments
		show_help()
		return

	testMode = False

	xr = iter(range(argCount))
	next(xr)
	for i in xr:
		arg = argv[i]
		if arg=="-i" and i<argCount - 1:
			options["sources"] = argv[i+1]
			next(xr)
		elif arg=="-o" and i<argCount - 1:
			options["outFolder"] = argv[i+1]
			next(xr)
		elif arg=="-w":
			options["overwrite"] = True
		elif arg=="-h":
			show_help()
			return
		else:
			log.println("unrecognized command (or missing command arguments): " + arg)
			return

	if options["sources"] is None:
		log.println("source image(s) must be supplied.")
		return

	options["outFolder"] = path.abspath(options["outFolder"])

	json.dump(options, log.file(), indent=4)
	log.println("")

	os.makedirs(options["outFolder"], exist_ok=True)
	info = process(options)
	info["options"] = options

	if info is not None:
		with open("tiled2asm.json", "w") as f:
			json.dump(info, f, indent=4)

	log.println("finished.")

if __name__ == '__main__':

	try:
		main(sys.argv)
	except KeyboardInterrupt:
		log.println("\nuser break!")
	except SystemExit:
		log.println("exiting program.")
	#except:		
	#	log.println(f"Unexpected error: {sys.exc_info()[0]}")

	log.close()
