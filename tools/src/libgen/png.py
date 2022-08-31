import os.path as path
import png
from libgen import vdp

def to_asm(source, options):

	log = options["log"]

	info = {}
	info["source"] = {}

	ext = path.splitext(source)[1]
	if ext != ".png":
		log.println(f"ERROR: {source} is not a png. only png's are supported.")
		info["error"] = "Not a png."
		info["skipped"] = True
		return info

	baseName = path.basename(source)	
	baseName = path.splitext(baseName)[0]
	baseName = baseName.replace(" ", "_")
	baseLabel = baseName.replace("-", "_")
	baseLabel = baseLabel.lower()

	outFile = path.join(options["outFolder"], f"{baseName}.s")
	outHeaderFile = path.join(options["outFolder"], f"{baseName}.h")
	info["outFile"] = outFile
	info["outHeader"] = outHeaderFile

	if not options["overwrite"] and path.exists(outFile):
		log.println(f"skipping {outFile}, it already exists and ovewrite is set to False.")
		info["error"] = "Already exists and ovewrite is set to False."
		info["skipped"] = True
		return info

	# load our source
	pngFile = png.Reader(source)
	image = pngFile.read()

	w = image[0]
	h = image[1]
	pngInfo = image[3]
	if not "palette" in pngInfo:
		log.println("ERROR: Image does not contain an indexed palette.")
		info["error"] = "Image does not contain an indexed palette."
		info["skipped"] = True
		return info

	palLen = len(pngInfo["palette"])

	log.println(f"source image: {source}")
	log.println(f"size: {w} x {h}")	
	log.println(f"palette length: {palLen}")

	if palLen == 0 or palLen > 16:
		log.println("ERROR: Input palette size must be between 1 and 16.")
		info["error"] = "Input palette size must be between 1 and 16."
		info["skipped"] = True
		return info

	if w % 8.0 > 0 or h % 8.0 > 0:
		log.println("ERROR: Image dimensions must be a multiple of 8.")
		info["error"] = "Image dimensions must be a multiple of 8."
		info["skipped"] = True
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
		color = vdp.make_color(rgb[0], rgb[1], rgb[2])
		outPal.append(color)
	palSize = palLen * 2	

	includeData = not "includeData" in options or options["includeData"]
	includePallete = not "includePalette" in options or options["includePalette"]

	with open(outHeaderFile, "w") as fo:
		defLabel = baseLabel.upper()

		fo.write(f"// png.to_asm {source}\n\n")
		if includeData:
			fo.write(f"#define {defLabel}_WIDTH_TILES   {wt}\n")
			fo.write(f"#define {defLabel}_HEIGHT_TILES  {ht}\n")
			fo.write(f"#define {defLabel}_SIZE          {outTilesSize}\n")
			fo.write(f"#define {defLabel}_TILE_COUNT    {outTilesLen}\n")
		if includePallete:
			fo.write(f"#define {defLabel}_PALETTE_COUNT {palLen}\n")
			fo.write(f"#define {defLabel}_PALETTE_SIZE  {palSize}\n")

	with open(outFile, "w") as fo:
		fo.write(f"// png.to_asm {source}\n")
		fo.write(".text\n")
		if includeData:
			fo.write(f"    .global {baseLabel}_data\n")
		if includePallete:
			fo.write(f"    .global {baseLabel}_palette\n")
		fo.write("\n")

		# image data
		if includeData:
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
		if includePallete:
			fo.write(f"{baseLabel}_palette:\n")
			fo.write("    dc.w    ")
			for i in range(0, palLen - 1):
				fo.write(f"{hex(outPal[i])},")
			fo.write(f"{hex(outPal[palLen - 1])}")
			fo.write("\n")

	return info